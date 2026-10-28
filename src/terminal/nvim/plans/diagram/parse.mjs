const LABEL_COLUMNS = 28;
const HEADER = [
  "flowchart TD",
  "classDef pending fill:#363a4f,stroke:#939ab7,color:#cad3f5",
  "classDef progress fill:#504d50,stroke:#eed49f,color:#cad3f5",
  "classDef done fill:#3e4b4c,stroke:#a6da95,color:#cad3f5",
];

function wrapWords(text) {
  const lines = [];
  let line = "";
  for (let word of text.split(/\s+/).filter(Boolean)) {
    while (word.length > LABEL_COLUMNS) {
      if (line) lines.push(line);
      lines.push(word.slice(0, LABEL_COLUMNS));
      line = "";
      word = word.slice(LABEL_COLUMNS);
    }
    if (line && line.length + 1 + word.length > LABEL_COLUMNS) {
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

export function diagramsFromMarkdown(markdown) {
  const trees = [];
  const parents = [];
  let index = 0;
  for (const line of markdown.split(/\r?\n/)) {
    const task = line.match(/^([ \t]*)[-*+] \[([ xX-])\] (.+)$/);
    if (!task) continue;
    const indent = task[1].replace(/\t/g, "    ").length;
    while (parents.length && parents.at(-1).indent >= indent) parents.pop();
    const name = `task${index++}`;
    const status = task[2] === " " ? "pending" : task[2] === "-" ? "progress" : "done";
    const label = wrapWords(task[3].trim()).map(escapeLabel).join("<br/>");
    const node = `${name}["${label}"]:::${status}`;
    if (parents.length) {
      const parent = parents.at(-1);
      parent.tree.push(node, `${parent.name} --- ${name}`);
      parents.push({ indent, name, tree: parent.tree });
    } else {
      const tree = [...HEADER, node];
      trees.push(tree);
      parents.push({ indent, name, tree });
    }
  }
  return trees.map((tree) => tree.join("\n"));
}
