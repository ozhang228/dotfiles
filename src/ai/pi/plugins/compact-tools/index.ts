import {
  sandboxBash,
  sandboxEdit,
  sandboxWrite,
  registerRecovery,
} from "../../sandbox/tools.ts";
import {
  createBashToolDefinition,
  defineTool,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  type ExtensionAPI,
  type ToolDefinition,
  type ToolRenderers,
} from "@earendil-works/pi-coding-agent";
import {
  Container,
  Text,
  truncateToWidth,
  visibleWidth,
  sliceByColumn,
  type Component,
} from "@earendil-works/pi-tui";
import { Type, type TProperties } from "typebox";
import { Value } from "typebox/value";

type ToolName = "read" | "grep" | "find" | "ls" | "bash" | "edit" | "write";
type CardState = {
  compactResult?: string;
  nativeCall?: Component;
  nativeResult?: Component;
};
type CardContext = Omit<
  Parameters<NonNullable<ToolRenderers["renderCall"]>>[2],
  "state" | "args"
> & { state: CardState; args: unknown };

function isToolName(name: string): name is ToolName {
  return ["read", "grep", "find", "ls", "bash", "edit", "write"].includes(name);
}

function icon(name: ToolName) {
  switch (name) {
    case "read":
      return "📖";
    case "grep":
      return "🔎";
    case "find":
      return "🧭";
    case "ls":
      return "📂";
    case "bash":
      return "⚡";
    case "edit":
      return "✏️";
    case "write":
      return "📝";
  }
}

function toolColor(name: ToolName) {
  switch (name) {
    case "read":
    case "grep":
    case "find":
    case "ls":
      return "mdQuoteBorder";
    case "edit":
    case "write":
      return "mdCode";
    case "bash":
      return "accent";
  }
}

function singleLine(value: unknown) {
  return typeof value === "string"
    ? value
        .replace(/\p{Cc}/gu, " ")
        .replace(/\s+/g, " ")
        .trim()
    : "";
}

function summaryText(name: ToolName, value: unknown) {
  const summary = singleLine(value);
  if (name === "ls") return summary.replace(/^(?:ls|list|inspect)\s+/i, "");
  if (name === "read") return summary.replace(/^(?:read|inspect)\s+/i, "");
  return summary;
}

function target(name: ToolName, args: Record<string, unknown>) {
  const path = singleLine(args.path);
  const displayPath = path === "." ? "./" : path;
  switch (name) {
    case "bash":
      return singleLine(args.command);
    case "grep":
      return `/${singleLine(args.pattern)}/ in ${displayPath || "./"}`;
    case "find":
      return `${singleLine(args.pattern)} in ${displayPath || "./"}`;
    case "read":
    case "edit":
    case "write":
      return displayPath;
    case "ls":
      return displayPath || "./";
  }
}

function fitTarget(name: ToolName, args: Record<string, unknown>, width: number) {
  const value = target(name, args);
  if (width <= 0) return "";
  if (["read", "edit", "write", "ls"].includes(name) && visibleWidth(value) > width) {
    return `…${sliceByColumn(value, visibleWidth(value) - width + 1, width - 1, true)}`;
  }
  return truncateToWidth(value, width);
}

function textOutput(result: { content: { type: string; text?: string }[] }) {
  return result.content
    .filter((block) => block.type === "text")
    .map((block) => block.text || "")
    .join("\n");
}

function record(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null
    ? Object.fromEntries(Object.entries(value))
    : {};
}

function countLabel(count: number, unit: string) {
  return `${count} ${count === 1 ? unit : unit === "entry" ? "entries" : `${unit}s`}`;
}

function resultSummary(
  name: ToolName,
  result: {
    content: { type: string; text?: string }[];
    details?: unknown;
    structuredContent?: unknown;
  },
  context: CardContext,
) {
  const output = textOutput(result);
  if (context.isError) {
    if (output.startsWith("ENOENT:")) return "failed: file not found";
    return `failed: ${singleLine(output.split("\n")[0]) || "tool error"}`;
  }
  if (context.isPartial) return "running";
  const details = record(result.details);
  const truncation = record(details.truncation);
  const truncated =
    truncation.truncated === true ||
    details.matchLimitReached !== undefined ||
    details.entryLimitReached !== undefined ||
    details.resultLimitReached !== undefined ||
    details.linesTruncated === true;
  const suffix = truncated ? " · limited" : "";
  switch (name) {
    case "read": {
      if (result.content.some((block) => block.type === "image")) return "image";
      // Native read adds a continuation notice outside the file's selected lines.
      const content = output.replace(
        /\n\n\[\d+ more lines in file\. Use offset=\d+ to continue\.\]$/,
        "",
      );
      const lines =
        typeof truncation.outputLines === "number"
          ? truncation.outputLines
          : content.split("\n").length;
      return countLabel(lines, "line") + suffix;
    }
    case "grep":
      return (output.startsWith("No matches found") ? "no matches" : "matches found") + suffix;
    case "find":
    case "ls": {
      if (name === "find" && output.startsWith("No files found")) return "no files";
      const limit = name === "find" ? details.resultLimitReached : details.entryLimitReached;
      const count =
        typeof truncation.outputLines === "number"
          ? truncation.outputLines
          : typeof limit === "number"
            ? limit
            : output.trim().split("\n").filter(Boolean).length;
      return countLabel(count, name === "find" ? "file" : "entry") + suffix;
    }
    case "bash": {
      const structured = record(result.structuredContent);
      return (
        (typeof structured.exit_code === "number" ? `exit ${structured.exit_code}` : "completed") +
        suffix
      );
    }
    case "edit":
      return "updated";
    case "write":
      return "written";
  }
}

function compactRenderers(name: ToolName, native: ToolRenderers = {}): ToolRenderers {
  return {
    renderShell: "self",
    renderCall(rawArgs: unknown, theme, context: CardContext) {
      const args = record(rawArgs);
      const header = `${icon(name)} ${theme.fg(toolColor(name), theme.bold(name))} ${theme.fg("text", summaryText(name, args.summary))}`;
      if (context.expanded && native.renderCall) {
        const component = native.renderCall(args, theme, {
          ...context,
          lastComponent: context.state.nativeCall,
        });
        context.state.nativeCall = component;
        const expanded = new Container();
        expanded.addChild(new Text(header, context.outputPad, 0));
        expanded.addChild(component);
        return expanded;
      }
      return {
        render(width) {
          const result = context.state.compactResult;
          const contentWidth = Math.max(1, width - context.outputPad * 2);
          const resultWidth = Math.min(visibleWidth(result || ""), Math.floor(contentWidth * 0.6));
          const status = result
            ? ` → ${theme.fg(context.isError ? "error" : context.isPartial ? "muted" : "success", truncateToWidth(result, resultWidth))}`
            : "";
          const targetWidth = Math.max(0, contentWidth - 2 - visibleWidth(status));
          const detail = `  ${theme.fg("muted", fitTarget(name, args, targetWidth))}${status}`;
          return new Text(
            `${truncateToWidth(header, contentWidth)}\n${truncateToWidth(detail, contentWidth)}`,
            context.outputPad,
            0,
          ).render(width);
        },
        invalidate() {},
      };
    },
    renderResult(result, options, theme, context: CardContext) {
      context.state.compactResult = resultSummary(name, result, context);
      if (options.expanded && native.renderResult) {
        const component = native.renderResult(result, options, theme, {
          ...context,
          lastComponent: context.state.nativeResult,
        });
        context.state.nativeResult = component;
        return component;
      }
      return new Text("", 0, 0);
    },
  };
}

function withSummary<TProps extends TProperties, TDetails, TState>(
  tool: ToolDefinition<Type.TObject<TProps>, TDetails, TState>,
) {
  const summarySchema = Type.Object({
    summary: Type.String({
      minLength: 1,
      description:
        "2–6 words completing the tool name as a sentence, e.g. 'repository overview'. No opening verb or internal reasoning.",
    }),
  });
  const parameters = Type.Object({ ...tool.parameters.properties, ...summarySchema.properties });
  const nativeRenderers: ToolRenderers = defineTool(tool);
  return {
    ...tool,
    renderCall: nativeRenderers.renderCall,
    renderResult: nativeRenderers.renderResult,
    defaultActive: false,
    parameters,
    prepareArguments(args) {
      const input = record(args);
      const prepared = tool.prepareArguments ? tool.prepareArguments(args) : input;
      return Value.Parse(parameters, { ...record(prepared), summary: input.summary });
    },
    execute: async function execute(toolCallId, params, signal, onUpdate, ctx) {
      const { summary: _summary, ...nativeArgs } = record(params);
      return tool.execute(
        toolCallId,
        Value.Parse(tool.parameters, nativeArgs),
        signal,
        onUpdate,
        ctx,
      );
    },
  } satisfies ToolDefinition<typeof parameters, TDetails, TState>;
}

export default function compactTools(pi: ExtensionAPI) {
  // Read effective settings at execution time so /reload and project settings retain native behavior.
  const read = createReadToolDefinition(process.cwd());
  pi.registerTool(
    withSummary({
      ...read,
      execute(id, args, signal, update, ctx) {
        return createReadToolDefinition(ctx.cwd, {
          autoResizeImages: pi.getSettings().images?.autoResize,
        }).execute(id, args, signal, update, ctx);
      },
    }),
  );
  const sandboxed = process.env.PI_SANDBOX_CONTROL === "1";
  const bash = sandboxed ? sandboxBash(process.cwd()) : createBashToolDefinition(process.cwd());
  pi.registerTool(
    withSummary({
      ...bash,
      execute(id, args, signal, update, ctx) {
        if (sandboxed) return sandboxBash(ctx.cwd).execute(id, args, signal, update, ctx);
        const settings = pi.getSettings();
        return createBashToolDefinition(ctx.cwd, {
          commandPrefix: settings.shellCommandPrefix,
          shellPath: settings.shellPath,
        }).execute(id, args, signal, update, ctx);
      },
    }),
  );
  pi.registerTool(withSummary(createGrepToolDefinition(process.cwd())));
  pi.registerTool(withSummary(createFindToolDefinition(process.cwd())));
  pi.registerTool(withSummary(createLsToolDefinition(process.cwd())));
  pi.registerTool(
    withSummary(sandboxed ? sandboxEdit(process.cwd()) : createEditToolDefinition(process.cwd())),
  );
  pi.registerTool(
    withSummary(sandboxed ? sandboxWrite(process.cwd()) : createWriteToolDefinition(process.cwd())),
  );
  if (sandboxed) registerRecovery(pi);
  pi.registerToolRenderer(function resolveRenderer(name, next) {
    return isToolName(name) ? compactRenderers(name, next()) : next();
  });
}
