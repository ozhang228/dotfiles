import assert from "node:assert/strict";
import { test } from "node:test";
import { tasksFromMarkdown } from "./parse.mjs";
import { renderTaskTree } from "./render.mjs";

test("Markdown task bullets preserve roots, indentation, literal labels and all task states", () => {
  const markdown = [
    "# Work",
    "- [ ] Root `literal` & <tag>",
    "  * [-] Child",
    "\t+ [x] Grandchild",
    "  - [X] Sibling",
    "An ordinary paragraph",
    "- [x] Other root",
  ].join("\r\n");
  assert.deepEqual(tasksFromMarkdown(markdown), [
    {
      id: "task0",
      label: "Root `literal` & <tag>",
      status: "pending",
      children: [
        {
          id: "task1",
          label: "Child",
          status: "progress",
          children: [{ id: "task2", label: "Grandchild", status: "done", children: [] }],
        },
        { id: "task3", label: "Sibling", status: "done", children: [] },
      ],
    },
    { id: "task4", label: "Other root", status: "done", children: [] },
  ]);
});

test("uneven task branches flow left to right without card or connector collisions and escape labels", () => {
  const label = '</text><script>alert("x")</script><svg onload="alert(1)"> &';
  const markdown = [
    `- [ ] ${label}`,
    `  - [-] ${"W".repeat(80)}`,
    "    - [x] Nested task",
    ...Array.from({ length: 15 }, (_, index) => `  - [ ] Task ${index + 2}`),
    "- [x] Other root",
  ].join("\n");
  const roots = tasksFromMarkdown(markdown);
  const { svg, width, height } = renderTaskTree(roots[0]);
  assert.ok(width < 1000, "Sibling count must not widen a three-column tree");
  assert.match(svg, /font-size="16"/);
  assert.deepEqual(
    Array.from(svg.matchAll(/<tspan[^>]*>(W+)<\/tspan>/g), ([, text]) => text.length),
    [15, 15, 15, 15, 15, 5],
  );
  assert.match(svg, /&lt;script&gt;alert\(&quot;x&quot;\)&lt;\/script&gt;/);
  assert.doesNotMatch(svg, /<script|<foreignObject|<svg[^>]*\sonload=/);
  assert.match(svg, /Arrows point from subtasks toward their parent/);
  assert.match(svg, /id="plan-task0-arrow"/);
  assert.match(renderTaskTree(roots[1]).svg, /id="plan-task18-arrow"/);

  const cards = Array.from(
    svg.matchAll(/<rect x="(\d+)" y="([\d.]+)" width="280" height="(\d+)"/g),
    ([, x, y, cardHeight]) => ({ x: Number(x), y: Number(y), height: Number(cardHeight) }),
  );
  assert.equal(cards.length, 18);
  assert.ok(cards[0].x > cards[1].x && cards[1].x > cards[2].x);
  assert.ok(
    cards.slice(3).every((card) => card.x === cards[2].x),
    "All leaves belong on the left",
  );
  assert.equal(cards[1].y + cards[1].height / 2, cards[2].y + cards[2].height / 2);
  const directChildren = [cards[1], ...cards.slice(3)];
  assert.equal(
    cards[0].y + cards[0].height / 2,
    (directChildren[0].y + directChildren.at(-1).y + directChildren.at(-1).height) / 2,
    "The root must be centered over its child subtree band",
  );
  for (const [index, card] of cards.entries()) {
    assert.ok(card.x + 280 < width && card.y + card.height < height);
    for (const other of cards.slice(index + 1)) {
      const overlap =
        card.x < other.x + 280 &&
        card.x + 280 > other.x &&
        card.y < other.y + other.height &&
        card.y + card.height > other.y;
      assert.equal(overlap, false);
    }
  }
  const links = Array.from(
    svg.matchAll(/d="M (\d+) ([\d.]+) H (\d+) V ([\d.]+) H (\d+)" marker-end/g),
    ([, x, y, bendX, endY, endX]) => ({
      x: Number(x),
      y: Number(y),
      bendX: Number(bendX),
      endY: Number(endY),
      endX: Number(endX),
    }),
  );
  assert.equal(links.length, 17);
  for (const link of links) {
    assert.ok(
      link.x < link.bendX && link.bendX < link.endX,
      "Arrows must point right toward the parent",
    );
    assert.ok(cards.some((card) => card.x + 282 === link.x && card.y + card.height / 2 === link.y));
    assert.ok(
      cards.some((card) => card.x - 2 === link.endX && card.y + card.height / 2 === link.endY),
    );
    for (const card of cards) {
      const verticalCrossesCard =
        link.bendX > card.x &&
        link.bendX < card.x + 280 &&
        Math.min(link.y, link.endY) < card.y + card.height &&
        Math.max(link.y, link.endY) > card.y;
      const firstHorizontalCrossesCard =
        link.y > card.y &&
        link.y < card.y + card.height &&
        link.x < card.x + 280 &&
        link.bendX > card.x;
      const lastHorizontalCrossesCard =
        link.endY > card.y &&
        link.endY < card.y + card.height &&
        link.bendX < card.x + 280 &&
        link.endX > card.x;
      assert.equal(
        verticalCrossesCard || firstHorizontalCrossesCard || lastHorizontalCrossesCard,
        false,
      );
    }
  }
});
