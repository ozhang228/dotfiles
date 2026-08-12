---
name: respond-to-feedback
description: Evaluate incoming PR or code-review feedback with the author one comment at a time. Use when the user pastes review comments, links to PR feedback, asks to go through feedback, decide whether a reviewer is right, or address comments interactively. Verify each claim against the current code, explain the context and tradeoffs, wait for the user's decision before editing, and collect durable lessons for a later dotfiles update. Not for proactively reviewing a diff.
---

# Respond to Feedback

Help the author decide what to do with incoming review feedback. Treat every comment as a premise to verify, regardless of the reviewer's seniority.

## Boundaries

- Work one comment at a time. Batch comments only when the user explicitly asks.
- Keep GitHub read-only. Never post, edit, delete, resolve, or react to comments, and never mutate PR state.
- Do not edit code until the user decides what to do with the current comment.
- Do not propose a patch or draft a response unless the user asks. Give the user enough verified information to make the decision.
- Do not push without explicit approval. Preserve unrelated work and untracked files.

## Prepare the Walkthrough

1. Confirm the repository and branch match the PR under discussion.
2. Accept pasted comments, links, or a request to inspect the PR. When reading GitHub, use read-only operations and retrieve the full thread context.
3. Inventory comments privately. Deduplicate repeated feedback and note comments that depend on one another, but do not dump the whole inventory on the user.
4. Read the relevant repository rules, changed code, nearby code, tests, and history needed to evaluate the first comment. Verify the load-bearing premise before agreeing or pushing back.

## Discuss One Comment

Present only the current comment. Include:

- **Feedback:** the reviewer's exact claim or question.
- **Context:** what the referenced code does and how it fits into the surrounding path.
- **Verification:** whether the premise is supported, partially supported, or unsupported, with concrete evidence.
- **Why it matters:** the likely concern behind the comment and the behavioral, maintenance, or readability impact.
- **Assessment:** whether accepting, rejecting, or clarifying the feedback makes sense and why.

Do not include replacement code or a suggested reply unless requested. Ask what the user wants to do, then wait.

If the user asks for more context, investigate that question and stay on the same comment. If the user accepts the feedback, make the agreed change, run the smallest check that proves it, and inspect the diff before moving on. If the change exposes a larger design decision, pause and resolve that decision instead of silently expanding scope.

Record rejected or deferred feedback and the reason so the final recap is accurate. Then continue to the next comment without re-presenting settled comments.

## Collect Durable Lessons

Collect candidate lessons during the walkthrough without interrupting it or editing dotfiles. A candidate must be:

- verified against the current code or repository conventions;
- likely to recur beyond this specific line or PR; and
- specific enough to change future behavior.

Treat one reviewer's preference as a hypothesis, not a rule. Look for repository guidance, repeated feedback, or multiple examples before calling it a convention. Exclude one-off implementation details and rules already captured elsewhere.

After every comment is settled, present each candidate with its evidence and suggested home:

- a global workflow or language rule in `~/dotfiles/src/ai/rules/`;
- a reusable workflow change in the relevant skill; or
- a genuinely project-specific convention in the project's instructions.

Wait for explicit approval before editing dotfiles or project instructions. Search existing guidance first and update or consolidate it instead of adding a duplicate rule.

## Finish

After all accepted changes are complete:

1. Run the relevant format, static-analysis, and test gates in proportion to the risk.
2. Review the final diff for correctness, scope, and unnecessary changes.
3. Report the decisions, implemented changes, verification, unresolved feedback, and approved learning candidates.
4. Leave every GitHub thread untouched.
