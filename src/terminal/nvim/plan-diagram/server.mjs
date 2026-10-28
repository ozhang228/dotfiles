import { createServer } from "node:http";
import { readFile, realpath } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { createRequire } from "node:module";
import { diagramsFromMarkdown } from "./parse.mjs";

const [planPath, rendererPath] = process.argv.slice(2);
if (!planPath || !rendererPath) throw new Error("Expected plan file and mmdc executable");
const renderer = await realpath(rendererPath);
const require = createRequire(renderer);
const mermaidPath = resolve(dirname(require.resolve("mermaid")), "mermaid.min.js");
const [page, mermaid] = await Promise.all([
  readFile(new URL("./index.html", import.meta.url)),
  readFile(mermaidPath),
]);

const server = createServer(async (request, response) => {
  response.setHeader("Cache-Control", "no-store");
  try {
    if (request.url === "/") {
      response.setHeader("Content-Type", "text/html; charset=utf-8");
      response.end(page);
    } else if (request.url === "/mermaid.js") {
      response.setHeader("Content-Type", "text/javascript; charset=utf-8");
      response.end(mermaid);
    } else if (request.url === "/diagram") {
      const sources = diagramsFromMarkdown(await readFile(planPath, "utf8"));
      response.setHeader("Content-Type", "application/json");
      response.end(JSON.stringify({ sources }));
    } else {
      response.writeHead(404).end();
    }
  } catch (error) {
    response.writeHead(500, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ error: error.message }));
  }
});
server.listen(0, "0.0.0.0", () => process.stdout.write(`${server.address().port}\n`));
