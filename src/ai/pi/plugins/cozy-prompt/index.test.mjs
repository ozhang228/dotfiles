import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";

const require = createRequire(import.meta.url);
const { createJiti } = require("jiti");
const modules = "/usr/lib/pi/lib/node_modules/@earendil-works";
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": `${modules}/pi-coding-agent/dist/index.js`,
    "@earendil-works/pi-tui": `${modules}/pi-tui/dist/index.js`,
  },
});
const { CozyEditor } = await jiti.import("./index.ts");
const { KeybindingsManager } = await jiti.import(
  `${modules}/pi-coding-agent/dist/core/keybindings.js`,
);
const { CombinedAutocompleteProvider, visibleWidth } = await jiti.import(
  `${modules}/pi-tui/dist/index.js`,
);

function makeEditor() {
  const terminal = { columns: 80, rows: 24 };
  const tui = { terminal, requestRender() {} };
  const unchanged = function unchanged(text) {
    return text;
  };
  const theme = {
    borderColor: unchanged,
    selectList: {
      selectedPrefix: unchanged,
      selectedText: unchanged,
      description: unchanged,
      scrollInfo: unchanged,
      noMatch: unchanged,
    },
  };
  const editor = new CozyEditor(tui, theme, new KeybindingsManager());
  editor.setPaddingX(0);
  editor.focused = true;
  return editor;
}

test("the decorated composer preserves multiline paste, cursor placement, and submission", function pasteAndSubmit() {
  const editor = makeEditor();
  let submitted;
  editor.onSubmit = function capture(text) {
    submitted = text;
  };
  editor.handleInput("\x1b[200~inspect α\nthen explain\x1b[201~");
  const lines = editor.render(34);
  assert.equal(editor.getText(), "inspect α\nthen explain");
  assert.equal(lines.filter((line) => line.includes("\x1b_pi:c\x07")).length, 1);
  assert.deepEqual(lines.map(visibleWidth), [34, 34, 34, 34]);
  editor.handleInput("\r");
  assert.equal(submitted, "inspect α\nthen explain");
});

test("the decorated slash menu keeps mouse selection and native completion aligned", async function mouseCompletion() {
  const editor = makeEditor();
  editor.setAutocompleteProvider(
    new CombinedAutocompleteProvider([{ name: "model" }, { name: "skill:debug" }]),
  );
  editor.handleInput("/");
  await new Promise(function settle(resolve) {
    setTimeout(resolve, 30);
  });
  const lines = editor.render(40);
  assert.equal(editor.isShowingAutocomplete(), true);
  assert.ok(lines.some((line) => line.includes("skill:debug")));
  editor.handleMouse({
    type: "click",
    button: "left",
    x: 4,
    y: 4,
    width: 40,
    height: lines.length,
  });
  editor.handleInput("\t");
  assert.equal(editor.getText(), "/skill:debug ");
});
