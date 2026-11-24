import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const sandbox = fileURLToPath(new URL("../../sandbox", import.meta.url));
const [cli, root] = execFileSync(
  "python3",
  [
    "-c",
    "import sys;sys.path.insert(0,sys.argv[1]);from runtime import find_runtime,module_root;cli=find_runtime()[1];print(cli);print(module_root(cli))",
    sandbox,
  ],
  { encoding: "utf8" },
)
  .trim()
  .split("\n");
const require = createRequire(cli);
const { createJiti } = require("jiti");
const modules = join(root, "@earendil-works/pi-coding-agent");
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": join(modules, "dist/index.js"),
    "@earendil-works/pi-tui": join(root, "@earendil-works/pi-tui/dist/index.js"),
    typebox: join(root, "typebox/build/index.mjs"),
    "typebox/value": join(root, "typebox/build/value/index.mjs"),
  },
});
const { subagents } = await jiti.import("./index.ts");
const { createAssistantMessageEventStream } = await jiti.import(
  join(root, "@earendil-works/pi-ai/dist/utils/event-stream.js"),
);

function message(model, content, stopReason = "stop") {
  return {
    role: "assistant",
    api: model.api,
    provider: model.provider,
    model: model.id,
    content,
    stopReason,
    timestamp: Date.now(),
    usage: {
      input: 1,
      output: 1,
      cacheRead: 0,
      cacheWrite: 0,
      totalTokens: 2,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    },
  };
}

function response(model, content, stopReason = "stop") {
  const answer = message(model, content, stopReason);
  const stream = createAssistantMessageEventStream();
  stream.push({ type: "start", partial: answer });
  stream.push({ type: "done", reason: stopReason, message: answer });
  return stream;
}

function gate() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

test("real SDK workers inherit parent routing/effort and reject a requested mutation tool", async () => {
  const repo = mkdtempSync(join(tmpdir(), "pi-subagent-sdk-"));
  writeFileSync(join(repo, "sentinel"), "original");
  const model = {
    id: "inherited-model",
    name: "Managed parent",
    provider: "managed-parent",
    api: "openai-completions",
    reasoning: true,
    input: ["text"],
    contextWindow: 200000,
    maxTokens: 4096,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  };
  let refreshes = 0;
  const provider = {
    id: model.provider,
    name: "Trusted managed parent",
    auth: {
      apiKey: {
        async resolve() {
          return { auth: { apiKey: "simulated-provider" } };
        },
      },
    },
    getModels() {
      return [model];
    },
    async refreshModels() {
      refreshes += 1;
      throw new Error("Child discovery forbidden");
    },
    streamSimple(selected, context, options) {
      assert.equal(selected.id, "inherited-model");
      assert.equal(options.reasoning, "high");
      assert.deepEqual(
        context.messages
          .filter((message) => message.role === "system")
          .flatMap((message) => message.toolsAdded ?? [])
          .map((tool) => tool.name)
          .sort(),
        ["bash", "find", "grep", "ls", "read"],
      );
      const results = context.messages.filter((message) => message.role === "toolResult");
      if (!results.length)
        return response(
          selected,
          [
            {
              type: "toolCall",
              id: "blocked-write",
              name: "write",
              arguments: { path: "sentinel", content: "damaged" },
            },
          ],
          "toolUse",
        );
      assert.equal(results[0].isError, true);
      if (results.length === 1)
        return response(
          selected,
          [{ type: "toolCall", id: "allowed-read", name: "read", arguments: { path: "sentinel" } }],
          "toolUse",
        );
      assert.match(JSON.stringify(results[1].content), /original/);
      return response(selected, [
        {
          type: "text",
          text: `inherited-model/high: ${context.messages.find((message) => message.role === "user").content[0].text}`,
        },
      ]);
    },
  };
  const previousControl = process.env.PI_SANDBOX_CONTROL;
  process.env.PI_SANDBOX_CONTROL = "1";
  const tools = new Map();
  const hooks = new Map();
  subagents({
    registerTool(tool) {
      tools.set(tool.name, tool);
    },
    on(name, handler) {
      hooks.set(name, handler);
    },
    getThinkingLevel() {
      return "high";
    },
  });
  try {
    const result = await tools.get("subagent").execute(
      "batch",
      {
        tasks: [
          { name: "investigation", task: "inspect sentinel", context: "explicit parent context" },
        ],
      },
      undefined,
      undefined,
      {
        cwd: repo,
        model,
        modelRegistry: {
          getProvider() {
            return provider;
          },
        },
      },
    );
    const workers = JSON.parse(result.content[0].text);
    assert.equal(workers[0].status, "done", workers[0].answer);
    assert.match(workers[0].answer, /inherited-model\/high:.*explicit parent context/s);
    assert.equal(readFileSync(join(repo, "sentinel"), "utf8"), "original");
    assert.equal(refreshes, 0);
    const log = await tools
      .get("subagent_log")
      .execute("log", { handle: workers[0].log, limit: 16384 });
    assert.match(log.content[0].text, /blocked-write/);
    assert.match(log.content[0].text, /allowed-read/);
  } finally {
    await hooks.get("session_shutdown")();
    rmSync(repo, { recursive: true, force: true });
    if (previousControl === undefined) delete process.env.PI_SANDBOX_CONTROL;
    else process.env.PI_SANDBOX_CONTROL = previousControl;
  }
});

test(
  "session shutdown cancels an active SDK worker and waits for cleanup before expiring logs",
  { timeout: 5000 },
  async () => {
    const repo = mkdtempSync(join(tmpdir(), "pi-subagent-shutdown-"));
    const started = gate();
    const aborted = gate();
    const cleanup = gate();
    const model = {
      id: "shutdown-model",
      name: "Managed parent",
      provider: "managed-parent",
      api: "openai-completions",
      reasoning: true,
      input: ["text"],
      contextWindow: 200000,
      maxTokens: 4096,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    };
    const provider = {
      id: model.provider,
      name: "Managed parent",
      auth: {
        apiKey: {
          async resolve() {
            return { auth: { apiKey: "simulated-provider" } };
          },
        },
      },
      getModels() {
        return [model];
      },
      streamSimple(selected, _context, options) {
        const stream = createAssistantMessageEventStream();
        stream.push({ type: "start", partial: message(selected, []) });
        options.signal.addEventListener(
          "abort",
          () => {
            aborted.resolve();
            void cleanup.promise.then(() => {
              stream.push({
                type: "error",
                reason: "aborted",
                error: message(selected, [], "aborted"),
              });
            });
          },
          { once: true },
        );
        started.resolve();
        return stream;
      },
    };
    const previousControl = process.env.PI_SANDBOX_CONTROL;
    process.env.PI_SANDBOX_CONTROL = "1";
    const tools = new Map();
    const hooks = new Map();
    subagents({
      registerTool(tool) {
        tools.set(tool.name, tool);
      },
      on(name, handler) {
        hooks.set(name, handler);
      },
      getThinkingLevel() {
        return "medium";
      },
    });
    let pending;
    try {
      pending = tools.get("subagent").execute(
        "batch",
        {
          tasks: [{ name: "held", task: "review", context: "parent diff" }],
        },
        undefined,
        undefined,
        {
          cwd: repo,
          model,
          modelRegistry: {
            getProvider() {
              return provider;
            },
          },
        },
      );
      await started.promise;
      let closed = false;
      const closing = hooks
        .get("session_shutdown")()
        .then(() => {
          closed = true;
        });
      await aborted.promise;
      await new Promise((resolve) => setImmediate(resolve));
      assert.equal(closed, false);
      cleanup.resolve();
      const result = JSON.parse((await pending).content[0].text);
      await closing;
      assert.equal(result[0].status, "cancelled");
      await assert.rejects(
        tools.get("subagent_log").execute("log", { handle: result[0].log }),
        /expired/,
      );
    } finally {
      cleanup.resolve();
      await hooks.get("session_shutdown")();
      await pending;
      rmSync(repo, { recursive: true, force: true });
      if (previousControl === undefined) delete process.env.PI_SANDBOX_CONTROL;
      else process.env.PI_SANDBOX_CONTROL = previousControl;
    }
  },
);
