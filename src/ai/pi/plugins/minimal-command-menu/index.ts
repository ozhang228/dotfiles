import { readFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AutocompleteProvider } from "@earendil-works/pi-tui";

function loadAllowedCommands() {
  const value: unknown = JSON.parse(
    readFileSync(new URL("./allowed-commands.json", import.meta.url), "utf8"),
  );
  if (!Array.isArray(value) || !value.every((item: unknown) => typeof item === "string")) {
    throw new Error(
      "minimal-command-menu: allowed-commands.json must be an array of command names",
    );
  }
  return new Set<string>(value);
}

export function createCommandMenuProvider(
  current: AutocompleteProvider,
  allowedCommands: ReadonlySet<string>,
): AutocompleteProvider {
  return {
    triggerCharacters: current.triggerCharacters ?? [],
    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const suggestions = await current.getSuggestions(lines, cursorLine, cursorCol, options);
      if (!suggestions || options.force || !/^\/[^\s/]*$/.test(suggestions.prefix)) {
        return suggestions ?? null;
      }
      const items = suggestions.items.filter(
        (item) =>
          allowedCommands.has(item.value) ||
          (allowedCommands.has("skill:*") && item.value.startsWith("skill:")),
      );
      return items.length > 0 ? { ...suggestions, items } : null;
    },
    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
    },
    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

export default function commandMenu(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const allowedCommands = loadAllowedCommands();
    ctx.ui.addAutocompleteProvider((current) =>
      createCommandMenuProvider(current, allowedCommands),
    );
  });
}
