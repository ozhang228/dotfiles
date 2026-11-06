import {
  createBashToolDefinition,
  createEditToolDefinition,
  createWriteToolDefinition,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { isAbsolute, relative } from "node:path";
import { Type, type TSchema } from "typebox";
import { Value } from "typebox/value";

const messageSchema = Type.Union([
  Type.Object({
    type: Type.Union([Type.Literal("update"), Type.Literal("result")]),
    result: Type.Unknown(),
  }),
  Type.Object({ type: Type.Literal("error"), error: Type.String() }),
]);
const content = Type.Array(Type.Object({ type: Type.Literal("text"), text: Type.String() }));
const common = { content, isError: Type.Optional(Type.Boolean()) };
const writeResult = Type.Object({ ...common });
const editResult = Type.Object({
  ...common,
  details: Type.Optional(
    Type.Object({
      diff: Type.String(),
      patch: Type.String(),
      firstChangedLine: Type.Optional(Type.Number()),
    }),
  ),
});
const truncation = Type.Object({
  content: Type.String(),
  truncated: Type.Boolean(),
  truncatedBy: Type.Union([Type.Literal("lines"), Type.Literal("bytes"), Type.Null()]),
  totalLines: Type.Number(),
  totalBytes: Type.Number(),
  outputLines: Type.Number(),
  outputBytes: Type.Number(),
  lastLinePartial: Type.Boolean(),
  firstLineExceedsLimit: Type.Boolean(),
  maxLines: Type.Number(),
  maxBytes: Type.Number(),
});
const bashResult = Type.Object({
  ...common,
  details: Type.Optional(
    Type.Object({
      truncation: Type.Optional(truncation),
      fullOutputPath: Type.Optional(Type.String()),
    }),
  ),
  structuredContent: Type.Optional(
    Type.Object({
      output: Type.String(),
      truncated: Type.Boolean(),
      full_output_path: Type.Optional(Type.String()),
      exit_code: Type.Number(),
      wall_time_seconds: Type.Number(),
    }),
  ),
});

async function request<T extends TSchema>(
  tool: string,
  args: unknown,
  schema: T,
  signal?: AbortSignal,
  update?: (result: ReturnType<typeof Value.Parse<T>>) => void,
) {
  const response = await fetch("http://pi-gateway.invalid/control", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ tool, args }),
    signal,
  });
  if (!response.ok) {
    let explanation = "";
    const reader = response.body?.getReader();
    if (reader) {
      const decoder = new TextDecoder();
      let remaining = 2000;
      try {
        while (remaining > 0) {
          const { value, done } = await reader.read();
          if (done) break;
          explanation += decoder.decode(value.subarray(0, remaining), { stream: true });
          remaining -= value.length;
        }
        explanation += decoder.decode();
      } finally {
        await reader.cancel();
      }
    }
    throw new Error(
      `Sandbox controller ${response.status}: ${explanation.trim() || response.statusText}`,
    );
  }
  if (!response.body) throw new Error("Sandbox controller returned no response body");
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let pending = "";
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      pending += decoder.decode(value, { stream: true });
      let newline = pending.indexOf("\n");
      while (newline >= 0) {
        if (newline > 262144) throw new Error("Sandbox result exceeds transport limit");
        const message = Value.Parse(messageSchema, JSON.parse(pending.slice(0, newline)));
        pending = pending.slice(newline + 1);
        if (message.type === "error") throw new Error(message.error);
        const result = Value.Parse(schema, message.result);
        if (message.type === "result") return result;
        update?.(result);
        newline = pending.indexOf("\n");
      }
      if (pending.length > 262144) throw new Error("Sandbox result exceeds transport limit");
    }
    throw new Error("Sandbox operation interrupted before completion");
  } finally {
    await reader.cancel();
  }
}

function relativeToolPath(cwd: string, path: string) {
  if (!isAbsolute(path) || path.split("/").some((part) => part === "." || part === "..")) {
    return path;
  }
  return relative(cwd, path);
}

export function sandboxWrite(cwd: string) {
  const native = createWriteToolDefinition(cwd);
  return {
    ...native,
    execute: async function execute(_id, args, signal, _update, _ctx) {
      const result = await request(
        "write",
        { ...args, path: relativeToolPath(cwd, args.path) },
        writeResult,
        signal,
      );
      return { ...result, details: undefined };
    },
  } satisfies typeof native;
}

export function sandboxEdit(cwd: string) {
  const native = createEditToolDefinition(cwd);
  return {
    ...native,
    execute: async function execute(_id, args, signal, _update, _ctx) {
      const result = await request(
        "edit",
        { ...args, path: relativeToolPath(cwd, args.path) },
        editResult,
        signal,
      );
      return { ...result, details: result.details };
    },
  } satisfies typeof native;
}

export function sandboxBash(cwd: string) {
  const native = createBashToolDefinition(cwd);
  return {
    ...native,
    execute: async function execute(_id, args, signal, update, _ctx) {
      const result = await request("bash", args, bashResult, signal, (partial) =>
        update?.({ ...partial, details: partial.details }),
      );
      return { ...result, details: result.details };
    },
  } satisfies typeof native;
}

export function registerRecovery(pi: ExtensionAPI) {
  pi.registerTool({
    name: "recovery_list",
    label: "recovery",
    description:
      "List protected pre-command checkpoints, or saved file paths for one checkpoint. Results are paginated.",
    parameters: Type.Object({
      checkpoint: Type.Optional(Type.String()),
      offset: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    async execute(_id, args, signal) {
      const result = await request(
        "recovery_list",
        args,
        Type.Object({ entries: Type.Array(Type.Unknown()), next_offset: Type.Number() }),
        signal,
      );
      return { content: [{ type: "text", text: JSON.stringify(result) }], details: undefined };
    },
  });
  pi.registerTool({
    name: "recovery_restore",
    label: "recover",
    description:
      "Recover selected saved files. Missing files are restored; existing files receive sibling .recovered-* copies so newer host edits remain intact.",
    parameters: Type.Object({
      checkpoint: Type.String(),
      paths: Type.Array(Type.String(), { minItems: 1, maxItems: 50 }),
    }),
    async execute(_id, args, signal) {
      const result = await request(
        "recovery_restore",
        args,
        Type.Object({ paths: Type.Array(Type.String()) }),
        signal,
      );
      return { content: [{ type: "text", text: JSON.stringify(result) }], details: undefined };
    },
  });
}
