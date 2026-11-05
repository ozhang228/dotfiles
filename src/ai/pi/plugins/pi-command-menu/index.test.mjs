import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";
import { createCommandMenuProvider } from "./index.ts";

const require = createRequire(import.meta.url);
const { CombinedAutocompleteProvider } = require("@earendil-works/pi-tui");

test("the slash menu hides unlisted commands and still completes skills from short names", async function skillMenu() {
  const current = new CombinedAutocompleteProvider([
    { name: "model" },
    { name: "share" },
    { name: "skill:debug" },
  ]);
  const provider = createCommandMenuProvider(current, new Set(["model", "skill:*"]));
  const options = { signal: new AbortController().signal };
  const menu = await provider.getSuggestions(["/"], 0, 1, options);
  assert.deepEqual(
    menu.items.map((item) => item.value),
    ["model", "skill:debug"],
  );
  assert.equal(await provider.getSuggestions(["/share"], 0, 6, options), null);
  const skills = await provider.getSuggestions(["/deb"], 0, 4, options);
  assert.deepEqual(provider.applyCompletion(["/deb"], 0, 4, skills.items[0], skills.prefix).lines, [
    "/skill:debug ",
  ]);
});

test("argument and file suggestions bypass the command whitelist", async function otherCompletion() {
  const argumentSuggestions = { prefix: "/model g", items: [{ value: "gpt", label: "gpt" }] };
  const fileSuggestions = { prefix: "@file", items: [{ value: "file.ts", label: "file.ts" }] };
  const forcedSuggestions = { prefix: "/", items: [{ value: "/tmp/", label: "/tmp/" }] };
  const current = {
    triggerCharacters: ["#"],
    async getSuggestions(lines, _line, _col, options) {
      if (options.force) return forcedSuggestions;
      return lines[0].startsWith("/model ") ? argumentSuggestions : fileSuggestions;
    },
    applyCompletion() {
      throw new Error("unused");
    },
    shouldTriggerFileCompletion() {
      return false;
    },
  };
  const provider = createCommandMenuProvider(current, new Set());
  const options = { signal: new AbortController().signal };
  assert.equal(await provider.getSuggestions(["/model g"], 0, 8, options), argumentSuggestions);
  assert.equal(await provider.getSuggestions(["@file"], 0, 5, options), fileSuggestions);
  assert.equal(
    await provider.getSuggestions(["/"], 0, 1, { ...options, force: true }),
    forcedSuggestions,
  );
  assert.deepEqual(provider.triggerCharacters, ["#"]);
  assert.equal(provider.shouldTriggerFileCompletion(["@file"], 0, 5), false);
});
