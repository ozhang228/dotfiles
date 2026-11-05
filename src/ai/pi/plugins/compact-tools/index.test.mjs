import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";

const require = createRequire(import.meta.url);
const { createJiti } = require("jiti");
const modules = "/usr/lib/pi/lib/node_modules";
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": `${modules}/@earendil-works/pi-coding-agent/dist/index.js`,
    "@earendil-works/pi-tui": `${modules}/@earendil-works/pi-tui/dist/index.js`,
    typebox: `${modules}/typebox/build/index.mjs`,
    "typebox/value": `${modules}/typebox/build/value/index.mjs`,
  },
});
const { default: compactTools } = await jiti.import("./index.ts");
const { visibleWidth } = await jiti.import(`${modules}/@earendil-works/pi-tui/dist/index.js`);
const theme = {
  fg(_color, text) {
    return text;
  },
  bold(text) {
    return text;
  },
};

function plugin() {
  const tools = new Map();
  let resolver;
  compactTools({
    registerTool(tool) {
      tools.set(tool.name, tool);
    },
    registerToolRenderer(value) {
      resolver = value;
    },
    getSettings() {
      return {};
    },
  });
  return {
    tools,
    renderer(name) {
      return resolver(name, () => tools.get(name));
    },
  };
}

function context(args, options = {}) {
  return {
    args,
    state: {},
    toolCallId: "fixture",
    cwd: "/tmp",
    outputPad: 0,
    invalidate() {},
    lastComponent: undefined,
    executionStarted: true,
    argsComplete: true,
    isPartial: false,
    expanded: false,
    showImages: false,
    isError: false,
    durationMs: 1,
    ...options,
  };
}

test("read cards hide content and continuation notices until native output is expanded", function readCard() {
  const { renderer } = plugin();
  const read = renderer("read");
  const args = { path: "src/auth.txt", summary: "inspect authentication flow", limit: 2 };
  const ctx = context(args);
  const result = {
    content: [
      { type: "text", text: "first\nsecond\n\n[8 more lines in file. Use offset=3 to continue.]" },
    ],
  };
  const call = read.renderCall(args, theme, ctx);
  read.renderResult(result, { expanded: false, isPartial: false }, theme, ctx);
  assert.deepEqual(
    call.render(80).map((line) => line.trimEnd()),
    ["📖 read authentication flow", "  src/auth.txt → 2 lines"],
  );
  ctx.expanded = true;
  const expanded = read
    .renderResult(result, { expanded: true, isPartial: false }, theme, ctx)
    .render(80)
    .join("\n");
  assert.match(expanded, /first\s*\nsecond/);
  assert.match(expanded, /8 more lines in file/);
});

test("narrow cards retain results, plural entries correctly, and keep failures visible", function narrowCards() {
  const { renderer } = plugin();
  const ls = renderer("ls");
  const args = {
    path: "very/long/path/that/exceeds/the/terminal/width",
    summary: "inspect all project directories and configuration files",
  };
  const ctx = context(args);
  const call = ls.renderCall(args, theme, ctx);
  ls.renderResult(
    { content: [{ type: "text", text: "one\ntwo\nthree\nfour\nfive\nsix" }] },
    { expanded: false, isPartial: false },
    theme,
    ctx,
  );
  const lines = call.render(32);
  assert.equal(lines.length, 2);
  assert.ok(lines.every((line) => visibleWidth(line) <= 32));
  assert.match(lines[1].trimEnd(), /→ 6 entries$/);
  const read = renderer("read");
  const failed = context(
    { path: "missing.ts", summary: "inspect missing configuration" },
    { isError: true },
  );
  const failedCall = read.renderCall(failed.args, theme, failed);
  read.renderResult(
    { content: [{ type: "text", text: "ENOENT: missing file\nUnnecessary diagnostic details" }] },
    { expanded: false, isPartial: false },
    theme,
    failed,
  );
  assert.deepEqual(
    failedCall.render(80).map((line) => line.trimEnd()),
    ["📖 read missing configuration", "  missing.ts → failed: file not found"],
  );
});

test("long failed read paths preserve the filename and failure at normal widths", function failedPath() {
  const read = plugin().renderer("read");
  const path = "/tmp/" + "long/".repeat(40) + "missing-config.ts";
  const args = { path, summary: "inspect missing configuration" };
  const ctx = context(args, { isError: true });
  const call = read.renderCall(args, theme, ctx);
  read.renderResult(
    { content: [{ type: "text", text: `ENOENT: no such file or directory, access '${path}'` }] },
    { expanded: false, isPartial: false },
    theme,
    ctx,
  );
  const lines = call.render(80);
  assert.equal(lines.length, 2);
  assert.match(lines[1].trimEnd(), /missing-config\.ts → failed: file not found$/);
  assert.ok(lines.every((line) => visibleWidth(line) <= 80));
});

test("tool names start the sentence without repeated read or list verbs", function sentenceHeaders() {
  const { renderer } = plugin();
  const examples = [
    { name: "read", summary: "read repository overview", expected: "📖 read repository overview" },
    { name: "ls", summary: "list source directories", expected: "📂 ls source directories" },
  ];
  for (const { name, summary, expected } of examples) {
    const args = { path: "src", summary };
    const call = renderer(name).renderCall(args, theme, context(args));
    assert.equal(call.render(80)[0].trimEnd(), expected);
  }
});

test("summary schemas preserve native validation and registered tools stay inactive by default", async function nativeContract() {
  const { tools } = plugin();
  assert.deepEqual([...tools.keys()], ["read", "bash", "grep", "find", "ls", "edit", "write"]);
  assert.ok([...tools.values()].every((tool) => tool.defaultActive === false));
  const edit = tools.get("edit");
  assert.deepEqual(
    edit.prepareArguments({
      path: "config.txt",
      summary: "update configuration",
      edits: { oldText: "old", newText: "new" },
    }),
    {
      path: "config.txt",
      summary: "update configuration",
      edits: [{ oldText: "old", newText: "new" }],
    },
  );
  const read = tools.get("read");
  assert.equal(read.parameters.type, "object");
  assert.deepEqual(read.parameters.required, ["path", "summary"]);
  assert.throws(() => read.prepareArguments({ path: "unused" }));
  assert.throws(() => read.prepareArguments({ summary: "inspect file" }));
  const args = read.prepareArguments({ path: "unused", summary: "inspect file", limit: 2 });
  const signal = AbortSignal.abort();
  await assert.rejects(
    read.execute("cancelled", args, signal, undefined, { cwd: "/tmp" }),
    /Operation aborted/,
  );
});
