export function tasksFromMarkdown(markdown) {
  const roots = [];
  const parents = [];
  let index = 0;
  for (const line of markdown.split(/\r?\n/)) {
    const task = line.match(/^([ \t]*)[-*+] \[([ xX-])\] (.+)$/);
    if (!task) continue;
    const indent = task[1].replace(/\t/g, "    ").length;
    while (parents.length && parents.at(-1).indent >= indent) parents.pop();
    const node = {
      id: `task${index++}`,
      label: task[3].trim(),
      status: task[2] === " " ? "pending" : task[2] === "-" ? "progress" : "done",
      children: [],
    };
    if (parents.length) parents.at(-1).node.children.push(node);
    else roots.push(node);
    parents.push({ indent, node });
  }
  return roots;
}
