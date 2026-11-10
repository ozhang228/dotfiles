import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const sandbox = fileURLToPath(new URL("../../sandbox", import.meta.url));
const piCli = execFileSync(
  "python3",
  [
    "-c",
    "import sys;sys.path.insert(0,sys.argv[1]);from runtime import find_runtime;print(find_runtime()[1])",
    sandbox,
  ],
  { encoding: "utf8" },
).trim();
let piAgent = dirname(piCli);
while (!existsSync(`${piAgent}/package.json`)) piAgent = dirname(piAgent);
const piAgentRequire = createRequire(`${piAgent}/package.json`);
const piTuiEntry = piAgentRequire.resolve("@earendil-works/pi-tui");
const { createJiti } = piAgentRequire("jiti");
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": `${piAgent}/dist/index.js`,
    "@earendil-works/pi-tui": piTuiEntry,
  },
});
const { CozyEditor, default: cozyPrompt } = await jiti.import("./index.ts");
const { KeybindingsManager } = await jiti.import(`${piAgent}/dist/core/keybindings.js`);
const { CombinedAutocompleteProvider, visibleWidth } = await jiti.import(piTuiEntry);

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

test("Ctrl+C aborts a busy session through the public runtime action", function abortBusySession() {
  let input;
  let footer;
  const stop = new AbortController();
  cozyPrompt({
    on(_name, start) {
      start(
        {},
        {
          hasUI: true,
          isIdle() {
            return false;
          },
          abort() {
            stop.abort();
          },
          ui: {
            setFooter(factory) {
              footer = factory(
                { requestRender() {} },
                {},
                {
                  onBranchChange() {
                    return () => {};
                  },
                },
              );
            },
            onTerminalInput(handler) {
              input = handler;
              return () => {};
            },
            setWidget() {},
            setEditorComponent() {},
          },
        },
      );
    },
  });
  try {
    assert.deepEqual(input("\x03"), { consume: true });
    assert.equal(stop.signal.aborted, true);
  } finally {
    footer.dispose();
  }
});
