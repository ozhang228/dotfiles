import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { tasksFromMarkdown } from "./parse.mjs";

const [planPath] = process.argv.slice(2);
if (!planPath) throw new Error("Expected plan file");
const [page, renderer] = await Promise.all([
  readFile(new URL("./index.html", import.meta.url)),
  readFile(new URL("./render.mjs", import.meta.url)),
]);

const server = createServer(async (request, response) => {
  response.setHeader("Cache-Control", "no-store");
  try {
    if (request.url === "/") {
      response.setHeader("Content-Type", "text/html; charset=utf-8");
      response.end(page);
    } else if (request.url === "/render.mjs") {
      response.setHeader("Content-Type", "text/javascript; charset=utf-8");
      response.end(renderer);
    } else if (request.url === "/diagram") {
      const roots = tasksFromMarkdown(await readFile(planPath, "utf8"));
      response.setHeader("Content-Type", "application/json");
      response.end(JSON.stringify({ roots }));
    } else {
      response.writeHead(404).end();
    }
  } catch (error) {
    response.writeHead(500, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ error: error.message }));
  }
});
server.listen(0, "0.0.0.0", () => process.stdout.write(`${server.address().port}\n`));
