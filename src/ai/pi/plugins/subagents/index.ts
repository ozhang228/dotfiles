import {
  createAgentSession,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  DefaultResourceLoader,
  defineTool,
  getAgentDir,
  ModelRuntime,
  SessionManager,
  SettingsManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { Value } from "typebox/value";
import { sandboxReadonlyBash } from "../../sandbox/tools.ts";
import { BatchRunner, type WorkerSession } from "./batch.ts";

type ActiveModel = NonNullable<ExtensionContext["model"]>;
type Effort = ReturnType<ExtensionAPI["getThinkingLevel"]>;

export async function createReadonlySession(options: {
  cwd: string;
  registry: ExtensionContext["modelRegistry"];
  model: ActiveModel;
  effort: Effort;
  signal: AbortSignal;
}): Promise<WorkerSession> {
  const provider = options.registry.getProvider(options.model.provider);
  if (!provider) throw new Error(`Parent provider unavailable: ${options.model.provider}`);
  const modelRuntime = await ModelRuntime.create({
    modelsPath: null,
    refreshOnCreate: false,
    allowModelNetwork: false,
    signal: options.signal,
    credentials: {
      async read() {
        return undefined;
      },
      async list() {
        return [];
      },
      async modify() {
        throw new Error("Child credential writes are disabled");
      },
      async delete() {
        throw new Error("Child credential writes are disabled");
      },
    },
  });
  // Keep the trusted protocol adapter; child registration never refreshes a catalog.
  modelRuntime.registerNativeProvider({
    ...provider,
    getModels() {
      return [options.model];
    },
    getAllModels() {
      return [options.model];
    },
    refreshModels: undefined,
  });
  const settingsManager = SettingsManager.inMemory({
    extensions: ["!**"],
    packages: [],
    skills: ["!**"],
    prompts: ["!**"],
    themes: ["!**"],
    compaction: { enabled: false },
    retry: { enabled: false },
    cacheWarming: "off",
    enableAnalytics: false,
    enableInstallTelemetry: false,
  });
  const resourceLoader = new DefaultResourceLoader({
    cwd: options.cwd,
    agentDir: getAgentDir(),
    settingsManager,
    noExtensions: true,
    disabledBuiltinExtensions: ["mcp", "codemode", "tool-search"],
    noSkills: true,
    noPromptTemplates: true,
    noThemes: true,
    noContextFiles: true,
    systemPrompt:
      "You are a short-lived read-only worker. Complete the supplied focused task using the parent's explicit context. Repositories are read-only. Bash has no network, credentials, or gateway access and permits only disposable scratch writes. Use $TMPDIR for scripts, reports, and benchmarks. Report denied writes or unavailable tools; never seek write access. Return your answer to the parent, who owns all edits. Do not delegate.",
  });
  await resourceLoader.reload();
  options.signal.throwIfAborted();
  const { session } = await createAgentSession({
    cwd: options.cwd,
    model: options.model,
    thinkingLevel: options.effort,
    modelRuntime,
    settingsManager,
    resourceLoader,
    sessionManager: SessionManager.inMemory(options.cwd),
    tools: ["read", "grep", "find", "ls", "bash"],
    noTools: "builtin",
    customTools: [
      defineTool(createReadToolDefinition(options.cwd)),
      defineTool(createGrepToolDefinition(options.cwd)),
      defineTool(createFindToolDefinition(options.cwd)),
      defineTool(createLsToolDefinition(options.cwd)),
      defineTool(sandboxReadonlyBash(options.cwd)),
    ],
  });
  return {
    subscribe(listener) {
      return session.subscribe(listener);
    },
    prompt(text) {
      return session.prompt(text, { expandPromptTemplates: false });
    },
    get answer() {
      const message = session.messages.findLast((entry) => entry.role === "assistant");
      if (!message || message.role !== "assistant")
        throw new Error("Worker returned no assistant answer");
      if (message.stopReason === "error" || message.stopReason === "aborted")
        throw new Error(message.errorMessage ?? `Worker ${message.stopReason}`);
      return message.content
        .filter((entry) => entry.type === "text")
        .map((entry) => entry.text)
        .join("\n");
    },
    abort() {
      return session.abort();
    },
    dispose() {
      session.dispose();
    },
  };
}

export function subagents(pi: ExtensionAPI) {
  let runner: BatchRunner<ActiveModel, Effort> | undefined;
  async function close() {
    const current = runner;
    runner = undefined;
    await current?.close();
  }
  pi.on("session_shutdown", close);
  pi.registerTool({
    name: "subagent",
    label: "subagents",
    description:
      "Run one to four concurrent, short-lived read-only workers for generic focused tasks. Supply all relevant context explicitly. Workers inherit the parent's active model and effort, return identified answers and full transcript handles, then end. Only the parent edits repositories.",
    parameters: Type.Object({
      tasks: Type.Array(
        Type.Object({
          name: Type.String({ minLength: 1, maxLength: 80, pattern: "^[A-Za-z0-9_-]+$" }),
          task: Type.String({ minLength: 1, maxLength: 65536 }),
          context: Type.String({ maxLength: 262144 }),
        }),
        { minItems: 1, maxItems: 4 },
      ),
    }),
    async execute(_id, args, signal, update, ctx) {
      if (process.env.PI_SANDBOX_CONTROL !== "1")
        throw new Error(
          "Subagents require ordinary sandboxed Pi with an approved repository controller",
        );
      const model = ctx.model;
      if (!model) throw new Error("Select a parent model before delegating");
      const effort = pi.getThinkingLevel();
      if (!runner) runner = new BatchRunner<ActiveModel, Effort>({});
      const results = await runner.run({
        tasks: args.tasks,
        model,
        effort,
        signal,
        create: (options) =>
          createReadonlySession({
            cwd: ctx.cwd,
            registry: ctx.modelRegistry,
            model: options.model,
            effort: options.effort,
            signal: options.signal,
          }),
        update(rows) {
          update?.({
            content: [],
            details: { rows, model: `${model.provider}/${model.id}`, effort },
          });
        },
      });
      return {
        content: [{ type: "text", text: JSON.stringify(results) }],
        details: { rows: results, model: `${model.provider}/${model.id}`, effort },
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg(
          "toolTitle",
          `subagents · ${args.tasks?.map((task) => task.name).join(" · ") ?? "starting"}`,
        ),
        0,
        0,
      );
    },
    renderResult(result, _options, theme) {
      if (!result.details) return new Text("", 0, 0);
      const { rows } = Value.Parse(
        Type.Object({
          rows: Type.Array(
            Type.Object({
              name: Type.String(),
              status: Type.Union([
                Type.Literal("running"),
                Type.Literal("done"),
                Type.Literal("failed"),
                Type.Literal("cancelled"),
              ]),
              activity: Type.String(),
            }),
          ),
        }),
        result.details,
      );
      return new Text(
        rows
          .map(
            (row) =>
              `${theme.fg("toolTitle", row.name)} ${theme.fg(row.status === "failed" ? "error" : "muted", row.status)}${row.activity ? ` · ${theme.fg("dim", row.activity)}` : ""}`,
          )
          .join("\n"),
        0,
        0,
      );
    },
  });
  pi.registerTool({
    name: "subagent_log",
    label: "subagent log",
    description:
      "Read a completed or active worker's recorded full transcript. Offsets and limits count UTF-16 characters. Follow nextOffset until done. Handles expire when Pi ends or old completed batches are evicted.",
    parameters: Type.Object({
      handle: Type.String(),
      offset: Type.Optional(Type.Integer({ minimum: 0 })),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 16384 })),
    }),
    async execute(_id, args) {
      if (!runner) throw new Error("Subagent log expired or unknown");
      const page = runner.readLog({
        handle: args.handle,
        offset: args.offset ?? 0,
        limit: args.limit ?? 8192,
      });
      return { content: [{ type: "text", text: JSON.stringify(page) }], details: undefined };
    },
  });
}

// Pi's extension loader requires a default factory export.
export default subagents;
