const CARD_WIDTH = 280;
const PADDING = 18;
const LINE_HEIGHT = 22;
const COLUMN_GAP = 56;
const GAP = 20;
const STATUSES = {
  pending: { label: "Pending", color: "var(--pending, #8aadf4)" },
  progress: { label: "In progress", color: "var(--progress, #eed49f)" },
  done: { label: "Done", color: "var(--done, #a6da95)" },
};

function escapeText(text) {
  return text.replace(/[&<>"']/g, (character) => {
    switch (character) {
      case "&":
        return "&amp;";
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      case '"':
        return "&quot;";
      case "'":
        return "&apos;";
    }
  });
}

function measureFallback(text) {
  return Array.from(text).length * 16;
}

function wrapLabel(label, measureText) {
  const width = CARD_WIDTH - PADDING * 2;
  const lines = [];
  let line = "";
  for (const word of label.split(/\s+/).filter(Boolean)) {
    if (line && measureText(`${line} ${word}`) <= width) {
      line += ` ${word}`;
      continue;
    }
    if (line) lines.push(line);
    line = "";
    for (const character of word) {
      if (line && measureText(line + character) > width) {
        lines.push(line);
        line = "";
      }
      line += character;
    }
  }
  if (line) lines.push(line);
  return lines.length ? lines : [""];
}

function measureTask(task, measureText) {
  const lines = wrapLabel(task.label, measureText);
  const children = task.children.map((child) => measureTask(child, measureText));
  const height = PADDING * 2 + lines.length * LINE_HEIGHT;
  const childrenHeight =
    children.reduce((total, child) => total + child.subtreeHeight, 0) +
    Math.max(0, children.length - 1) * GAP;
  return {
    task,
    lines,
    children,
    height,
    childrenHeight,
    subtreeHeight: Math.max(height, childrenHeight),
    column: children.length ? Math.max(...children.map((child) => child.column)) + 1 : 0,
  };
}

function placeTask(subtree, top, cards) {
  const card = {
    task: subtree.task,
    lines: subtree.lines,
    x: PADDING + subtree.column * (CARD_WIDTH + COLUMN_GAP),
    y: top + (subtree.subtreeHeight - subtree.height) / 2,
    width: CARD_WIDTH,
    height: subtree.height,
  };
  cards.push(card);
  const links = [];
  let childTop = top + (subtree.subtreeHeight - subtree.childrenHeight) / 2;
  for (const child of subtree.children) {
    const placed = placeTask(child, childTop, cards);
    links.push({ parent: card, child: placed.card }, ...placed.links);
    childTop += child.subtreeHeight + GAP;
  }
  return { card, links };
}

function renderCard({ task, lines, x, y, width, height }) {
  const status = STATUSES[task.status];
  if (!status) throw new Error(`Unknown task status: ${task.status}`);
  const label = lines
    .map(
      (line, index) =>
        `<tspan x="${x + PADDING}" y="${y + PADDING + 16 + index * LINE_HEIGHT}">${escapeText(line)}</tspan>`,
    )
    .join("");
  return `<g role="group" aria-label="${escapeText(`${task.label}: ${status.label}`)}">
    <rect x="${x}" y="${y}" width="${width}" height="${height}" rx="16" fill="var(--surface, #363a4f)" stroke="${status.color}" stroke-width="1.5" />
    <text fill="var(--ink, #cad3f5)" font-size="16" font-weight="500">${label}</text>
  </g>`;
}

// The browser supplies canvas text measurement for its system font; the default is conservative.
export function renderTaskTree(root, measureText = measureFallback) {
  const cards = [];
  const subtree = measureTask(root, measureText);
  const { links } = placeTask(subtree, PADDING, cards);
  const width = Math.max(...cards.map((card) => card.x + card.width)) + PADDING;
  const height = subtree.subtreeHeight + PADDING * 2;
  const id = escapeText(`plan-${root.id}`);
  const connectors = links
    .map(
      ({ parent, child }) =>
        `<path d="M ${child.x + child.width + 2} ${child.y + child.height / 2} H ${parent.x - COLUMN_GAP / 2} V ${parent.y + parent.height / 2} H ${parent.x - 2}" marker-end="url(#${id}-arrow)" />`,
    )
    .join("");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}" role="img" aria-labelledby="${id}-title ${id}-desc" font-family="system-ui, sans-serif">
    <title id="${id}-title">${escapeText(root.label)}</title>
    <desc id="${id}-desc">Task hierarchy. Arrows point from subtasks toward their parent, showing completion progressing toward the root. Blue borders mean pending, yellow mean in progress, and green mean done.</desc>
    <defs><marker id="${id}-arrow" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="8" markerHeight="8" markerUnits="userSpaceOnUse" orient="auto"><path d="M 0 0 L 8 4 L 0 8" fill="none" stroke="var(--line, #5b6078)" stroke-width="1.5" /></marker></defs>
    <g fill="none" stroke="var(--line, #5b6078)" stroke-width="1.5" stroke-linejoin="round">${connectors}</g>
    ${cards.map(renderCard).join("")}
  </svg>`;
  return { svg, width, height };
}
