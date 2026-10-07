import { createServer } from "node:http";
import { readFile, realpath } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { createRequire } from "node:module";

const [todoPath, rendererPath] = process.argv.slice(2);
if (!todoPath || !rendererPath) throw new Error("Expected todo file and mmdc executable");
const renderer = await realpath(rendererPath);
const require = createRequire(renderer);
const mermaidPath = resolve(dirname(require.resolve("mermaid")), "mermaid.min.js");
const [page, mermaid] = await Promise.all([
  readFile(new URL("./index.html", import.meta.url)),
  readFile(mermaidPath),
]);

function diagramFromTodos(value) {
  if (!Array.isArray(value)) throw new Error("Todo file must contain a list");
  const nodes = new Map();
  const todos = value.map((todo, index) => {
    if (
      !todo ||
      typeof todo !== "object" ||
      typeof todo.text !== "string" ||
      typeof todo.done !== "boolean" ||
      (todo.in_progress !== undefined && typeof todo.in_progress !== "boolean") ||
      (typeof todo.id !== "string" && !Number.isFinite(todo.id)) ||
      (todo.parent_id != null &&
        typeof todo.parent_id !== "string" &&
        !Number.isFinite(todo.parent_id))
    ) {
      throw new Error(`Invalid task at position ${index + 1}`);
    }
    const id = String(todo.id);
    if (nodes.has(id)) throw new Error(`Duplicate task ID: ${id}`);
    const node = {
      id,
      name: `task${index}`,
      text: todo.text,
      done: todo.done,
      inProgress: todo.in_progress === true,
      parent: todo.parent_id == null ? undefined : String(todo.parent_id),
    };
    nodes.set(id, node);
    return node;
  });
  const lines = [
    "flowchart TD",
    "classDef pending fill:#ebdbb2,stroke:#665c54,color:#282828",
    "classDef progress fill:#fae5a3,stroke:#82560e,color:#282828",
    "classDef done fill:#d5e2ba,stroke:#67630c,color:#282828",
  ];
  for (const todo of todos) {
    const seen = new Set([todo.id]);
    let parent = todo.parent;
    while (parent !== undefined) {
      if (seen.has(parent)) throw new Error("Task hierarchy contains a cycle");
      const ancestor = nodes.get(parent);
      if (!ancestor) break;
      seen.add(parent);
      parent = ancestor.parent;
    }
    const label = todo.text.replace(/["<>#&\\\r\n]/g, (char) =>
      char === "\n" || char === "\r" ? " " : `#${char.charCodeAt(0)};`,
    );
    const status = todo.done ? "done" : todo.inProgress ? "progress" : "pending";
    const prefix = todo.done ? "✓ " : "";
    const missingParent = todo.parent !== undefined && !nodes.has(todo.parent);
    lines.push(
      `${todo.name}["${prefix}${label}${missingParent ? " (parent missing)" : ""}"]:::${status}`,
    );
    if (todo.parent !== undefined && !missingParent) {
      lines.push(`${nodes.get(todo.parent).name} --> ${todo.name}`);
    }
  }
  return lines.join("\n");
}

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
      const source = diagramFromTodos(JSON.parse(await readFile(todoPath, "utf8")));
      response.setHeader("Content-Type", "application/json");
      response.end(JSON.stringify({ source }));
    } else {
      response.writeHead(404).end();
    }
  } catch (error) {
    response.writeHead(500, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ error: error.message }));
  }
});
server.listen(0, "0.0.0.0", () => process.stdout.write(`${server.address().port}\n`));
