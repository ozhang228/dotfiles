import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const sandbox = fileURLToPath(new URL(".", import.meta.url));
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
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": join(root, "@earendil-works/pi-coding-agent/dist/index.js"),
    typebox: join(root, "typebox/build/index.mjs"),
    "typebox/value": join(root, "typebox/build/value/index.mjs"),
  },
});
const { sandboxReadonlyBash } = await jiti.import("./tools.ts");

function gate() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

async function wire(handler, run) {
  const server = createServer(async (request, response) => {
    let body = "";
    for await (const chunk of request) body += chunk;
    handler(JSON.parse(body), response);
  });
  await new Promise((resolve) => server.listen(0, "0.0.0.0", resolve));
  const fetch = globalThis.fetch;
  globalThis.fetch = (_url, options) =>
    fetch(`http://localhost:${server.address().port}/control`, options);
  try {
    await run();
  } finally {
    globalThis.fetch = fetch;
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  }
}

function result(response, value) {
  response.end(`${JSON.stringify({ type: "result", result: value })}\n`);
}

test(
  "terminal controller errors do not cancel; broken transport or protocol does",
  { timeout: 5000 },
  async () => {
    for (const failure of ["at most four running", "Command timed out", "protocol", "transport"]) {
      const requests = [];
      await wire(
        ({ tool }, response) => {
          requests.push(tool);
          if (tool === "readonly_cancel") result(response, { cancelled: true });
          else if (failure === "transport") response.destroy();
          else if (failure === "protocol") response.end("not-json\n");
          else response.end(`${JSON.stringify({ type: "error", error: failure })}\n`);
        },
        async () => {
          await assert.rejects(
            sandboxReadonlyBash(process.cwd()).execute("run", { command: "true" }),
          );
          assert.deepEqual(
            requests,
            failure === "protocol" || failure === "transport"
              ? ["readonly_bash", "readonly_cancel"]
              : ["readonly_bash"],
            failure,
          );
        },
      );
    }
  },
);

test(
  "user abort waits for cleanup and acknowledgement, preserving acknowledgement failures",
  { timeout: 5000 },
  async () => {
    for (const first of ["command", "acknowledgement", "failed-acknowledgement"]) {
      const started = gate();
      const cancelled = gate();
      let commandResponse;
      let cancelResponse;
      const signal = new AbortController();
      await wire(
        ({ tool }, response) => {
          if (tool === "readonly_bash") {
            commandResponse = response;
            started.resolve();
          } else {
            cancelResponse = response;
            cancelled.resolve();
          }
        },
        async () => {
          let settled = false;
          const pending = sandboxReadonlyBash(process.cwd())
            .execute("run", { command: "sleep 10" }, signal.signal)
            .finally(() => {
              settled = true;
            });
          const rejected = assert.rejects(pending, (error) => {
            if (first === "failed-acknowledgement") {
              assert.equal(error instanceof AggregateError, true);
              assert.match(error.errors[0].message, /abort/i);
              assert.equal(error.errors[1].message, "acknowledgement unavailable");
            } else assert.match(error.message, /abort/i);
            return true;
          });
          await started.promise;
          signal.abort();
          await cancelled.promise;
          const commandDone = () =>
            result(commandResponse, { content: [{ type: "text", text: "stopped" }] });
          const acknowledge = () => {
            if (first === "failed-acknowledgement")
              cancelResponse.end(
                `${JSON.stringify({ type: "error", error: "acknowledgement unavailable" })}\n`,
              );
            else result(cancelResponse, { cancelled: true });
          };
          (first === "command" ? commandDone : acknowledge)();
          await new Promise((resolve) => setTimeout(resolve, 20));
          assert.equal(settled, false, first);
          (first === "command" ? acknowledge : commandDone)();
          await rejected;
        },
      );
    }
  },
);
