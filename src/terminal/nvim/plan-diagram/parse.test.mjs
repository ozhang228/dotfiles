import assert from "node:assert/strict";
import { test } from "node:test";
import { diagramsFromMarkdown } from "./parse.mjs";

test("nested tasks form separate root trees while notes stay out of diagrams", () => {
  const diagrams = diagramsFromMarkdown(`# A plan

Notes about the plan.

- [ ] Parent
  - [x] Finished child
  - [ ] Active child
- [ ] Another root
`);

  assert.equal(diagrams.length, 2);
  assert.match(diagrams[0], /task0\["Parent"\]:::pending/);
  assert.match(diagrams[0], /task1\["✓ Finished child"\]:::done/);
  assert.match(diagrams[0], /task0 --> task1/);
  assert.match(diagrams[0], /task0 --> task2/);
  assert.doesNotMatch(diagrams.join("\n"), /Notes about the plan/);
  assert.match(diagrams[1], /task3\["Another root"\]:::pending/);
  assert.doesNotMatch(diagrams[1], /task0 --> task3/);
});
