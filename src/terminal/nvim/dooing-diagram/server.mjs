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

const LABEL_COLUMNS = 28;

function wrapWords(text, columns) {
  const lines = [];
  let line = "";
  for (let word of text.split(/\s+/).filter(Boolean)) {
    while (word.length > columns) {
      if (line) lines.push(line);
      lines.push(word.slice(0, columns));
      line = "";
      word = word.slice(columns);
    }
    if (line && line.length + 1 + word.length > columns) {
      lines.push(line);
      line = word;
    } else {
      line = line ? `${line} ${word}` : word;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function escapeLabel(text) {
  return text.replace(/["<>#&\\]/g, (char) => `#${char.charCodeAt(0)};`);
}

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
  const header = [
    "flowchart TD",
    "classDef pending fill:#363a4f,stroke:#939ab7,color:#cad3f5",
    "classDef progress fill:#504d50,stroke:#eed49f,color:#cad3f5",
    "classDef done fill:#3e4b4c,stroke:#a6da95,color:#cad3f5",
  ];
  const trees = new Map();
  for (const todo of todos) {
    const seen = new Set([todo.id]);
    let root = todo;
    while (root.parent !== undefined) {
      if (seen.has(root.parent)) throw new Error("Task hierarchy contains a cycle");
      const ancestor = nodes.get(root.parent);
      if (!ancestor) break;
      seen.add(root.parent);
      root = ancestor;
    }
    if (!trees.has(root.id)) trees.set(root.id, [...header]);
    const lines = trees.get(root.id);
    const status = todo.done ? "done" : todo.inProgress ? "progress" : "pending";
    const prefix = todo.done ? "✓ " : "";
    const missingParent = todo.parent !== undefined && !nodes.has(todo.parent);
    const text = `${prefix}${todo.text}${missingParent ? " (parent missing)" : ""}`;
    const label = wrapWords(text, LABEL_COLUMNS).map(escapeLabel).join("<br/>");
    lines.push(`${todo.name}["${label}"]:::${status}`);
    if (todo.parent !== undefined && !missingParent) {
      lines.push(`${nodes.get(todo.parent).name} --> ${todo.name}`);
    }
  }
  return [...trees.values()].map((lines) => lines.join("\n"));
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
      const sources = diagramFromTodos(JSON.parse(await readFile(todoPath, "utf8")));
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
