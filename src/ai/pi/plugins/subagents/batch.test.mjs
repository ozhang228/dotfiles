import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const sandbox = fileURLToPath(new URL("../../sandbox", import.meta.url));
const cli = execFileSync(
  "python3",
  [
    "-c",
    "import sys;sys.path.insert(0,sys.argv[1]);from runtime import find_runtime;print(find_runtime()[1])",
    sandbox,
  ],
  { encoding: "utf8" },
).trim();
const require = createRequire(cli);
const { createJiti } = require("jiti");
const jiti = createJiti(import.meta.url);
const { BatchRunner } = await jiti.import("./batch.ts");

function gate() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

test("concurrent tasks inherit context/model/effort, retain sibling answers and inspectable bounded logs", async () => {
  const bothStarted = gate();
  const release = gate();
  let started = 0;
  let disposed = 0;
  const status = [];
  const runner = new BatchRunner({
    workerBytes: 1600,
    totalBytes: 6400,
    async create(options) {
      let listener;
      return {
        subscribe(value) {
          listener = value;
          return () => {
            listener = undefined;
          };
        },
        async prompt(prompt) {
          started += 1;
          if (started === 2) bothStarted.resolve();
          await release.promise;
          listener?.({ type: "tool_execution_start", toolName: "read", args: { path: "file" } });
          listener?.({
            type: "tool_execution_end",
            result: { content: [{ type: "text", text: "file bytes" }] },
          });
          if (options.task.name === "testing") throw new Error("review failed");
          this.answer = `${options.model.id}/${options.effort}: ${prompt}`;
        },
        answer: "",
        async abort() {
          release.resolve();
        },
        dispose() {
          disposed += 1;
        },
      };
    },
  });
  try {
    const pending = runner.run({
      tasks: [
        { name: "correctness", task: "inspect races", context: "shared diff" },
        { name: "testing", task: "inspect tests", context: "test context" },
      ],
      model: { id: "parent-model" },
      effort: "high",
      update: (rows) => status.push(rows),
    });
    await bothStarted.promise;
    assert.equal(started, 2);
    release.resolve();
    const results = await pending;
    assert.equal(results[0].status, "done");
    assert.match(results[0].answer, /parent-model\/high:.*shared diff/s);
    assert.match(results[0].answer, /inspect races/);
    assert.equal(results[1].status, "failed");
    assert.match(results[1].answer, /review failed/);
    assert.equal(disposed, 2);
    assert.ok(status.some((rows) => rows.every((row) => row.status === "running")));
    const page = runner.readLog({ handle: results[0].log, offset: 0, limit: 200 });
    assert.match(page.text, /shared diff/);
    const rest = runner.readLog({ handle: results[0].log, offset: page.nextOffset, limit: 10000 });
    assert.match(rest.text, /file bytes/);
    assert.equal(rest.done, true);
    assert.match(
      runner.readLog({ handle: results[1].log, offset: 0, limit: 10000 }).text,
      /test context/,
    );
    assert.equal(runner.readLog({ handle: results[0].log, offset: 0, limit: 200 }).text, page.text);
    assert.throws(() => runner.readLog({ handle: "missing", offset: 0, limit: 200 }), /expired/);
    await runner.close();
    assert.throws(
      () => runner.readLog({ handle: results[0].log, offset: 0, limit: 200 }),
      /expired/,
    );
  } finally {
    await runner.close();
  }
});

test("batch cancellation waits for tool cleanup before disposing or returning", async () => {
  const started = gate();
  const cleanup = gate();
  const stopped = gate();
  const signal = new AbortController();
  let disposed = false;
  const runner = new BatchRunner({
    async create() {
      return {
        subscribe() {
          return () => {};
        },
        async prompt() {
          started.resolve();
          await stopped.promise;
        },
        answer: "",
        async abort() {
          await cleanup.promise;
          stopped.resolve();
        },
        dispose() {
          disposed = true;
        },
      };
    },
  });
  try {
    let returned = false;
    const pending = runner
      .run({
        tasks: [{ name: "benchmark", task: "run", context: "scratch" }],
        model: {},
        effort: "medium",
        signal: signal.signal,
      })
      .then((value) => {
        returned = true;
        return value;
      });
    await started.promise;
    signal.abort();
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(returned, false);
    assert.equal(disposed, false);
    cleanup.resolve();
    const results = await pending;
    assert.equal(results[0].status, "cancelled");
    assert.equal(disposed, true);
  } finally {
    await runner.close();
  }
});

test("large recorded results remain fully pageable while cumulative updates do not exhaust logs", async () => {
  const runner = new BatchRunner({
    workerBytes: 200000,
    totalBytes: 800000,
    async create(options) {
      let listener;
      return {
        subscribe(value) {
          listener = value;
          return () => {};
        },
        async prompt() {
          const text = "x".repeat(options.task.name === "too-large" ? 250000 : 100000);
          for (let index = 0; index < 10; index += 1)
            listener({ type: "message_update", message: { content: text } });
          listener({ type: "message_end", message: { content: text } });
        },
        answer: "complete",
        async abort() {},
        dispose() {},
      };
    },
  });
  try {
    const results = await runner.run({
      tasks: [{ name: "large", task: "inspect", context: "provided" }],
      model: {},
      effort: "medium",
    });
    assert.equal(results[0].status, "done");
    let text = "";
    let offset = 0;
    while (true) {
      const page = runner.readLog({ handle: results[0].log, offset, limit: 8192 });
      text += page.text;
      offset = page.nextOffset;
      if (page.done) break;
    }
    assert.equal(JSON.parse(text.split("\n")[1]).message.content, "x".repeat(100000));
    const overflow = await runner.run({
      tasks: [{ name: "too-large", task: "inspect", context: "provided" }],
      model: {},
      effort: "medium",
    });
    assert.equal(overflow[0].status, "failed");
    assert.match(overflow[0].answer, /transcript budget exceeded/);
    assert.match(
      runner.readLog({ handle: overflow[0].log, offset: 0, limit: 8192 }).text,
      /transcript budget exceeded/,
    );
    assert.throws(
      () => runner.readLog({ handle: results[0].log, offset: 0, limit: 8192 }),
      /expired/,
    );
  } finally {
    await runner.close();
  }
});
