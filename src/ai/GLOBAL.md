# Global AI Rules

## Auto-Injected Context

Language conventions and task rules in `src/ai/rules/` are injected automatically by a PreToolUse hook whenever you Write, Edit, or run a Bash command. Do not try to read them manually as a preamble, the hook is authoritative and handles stacking (e.g. `test_foo.py` gets Python rules plus testing rules).
If the user asks a pure Q&A question about a convention without editing any file, read the relevant `src/ai/rules/*.md` on demand.

## Skill Observation (passive, every session)

Save a memory entry only when **all three** are true:
1. There is a concrete editable target (a skill file, a rules file, GLOBAL.md) — not harness/plugin behavior you can't change
2. The issue has recurred or is likely to recur — not a one-off
3. The fix wasn't applied immediately — if you fixed it on the spot, no entry needed (apply-and-done beats accumulate-and-review)

Signals worth recording when the bar is met:
- User corrected or overrode a skill's output
- User did something manually that an existing skill should have handled
- A skill fired on the wrong trigger (false positive) — only if the trigger is in an editable file
- A skill failed to fire when it should have (false negative)
- A task recurred across sessions with no skill covering it (new skill candidate)

These are consumed by the `skill-audit` skill. Keep the observation count low — a short list of real, actionable items beats a log of every friction point.

---

## Project-Specific Instructions Take Priority

You must always read and prefer **project-specific instructions** (e.g., `CLAUDE.md` in the project root) over these global rules.

---

## Communication Style

### Explaining Complex Topics

When explaining complex topics, break things into chunks using newlines for readability. Use examples to illustrate points.

For simple questions or straightforward tasks, this can be ignored.

**Format**: When doing something, explain it as "this is doing X. This is why we are doing it this way / this is the rationale."

Example:

```
We're splitting the logic into two functions.
This is doing X: separating concerns makes testing easier.
This is why: isolated units are easier to verify.
```

### Writing Style

Write like a normal US-born software engineer. Avoid phrasings that scream "AI-generated":

- No em dashes (`—`). Use commas, parentheses, periods, or colons instead.
- No aphoristic "X, not Y" sentence structures where a simple statement would do.
- Skip formal transitions ("Moreover", "Furthermore", "In addition"). Just say the next thing.
- Don't open paragraphs with "This PR...", "This change...", "This adds...". Lead with the verb or the subject.
- Contractions ("it's", "don't", "won't") are fine and usually preferred.
- Don't pad simple thoughts into multiple paragraphs.

This applies to PR descriptions, commit messages, comments intended for humans, and any prose that a reader might see.

### Pitch Pattern

When pitching a system migration or stakeholder ask:

1. Lead with their benefit, not your work.
2. Ground urgency in real events they already felt.
3. Be honest about gaps. It builds trust and invites help.
4. Frame the ask as collaboration, not a demand.
5. State the end goal clearly so people can orient.
6. Put their priorities first explicitly.
7. Make the next step easy and concrete.

---

## Reasoning About Prod vs Tests

Test stubs are set up for convenience, not to reflect real production configuration. Don't use stub values to make claims about what the app does in prod.

When reasoning about what the real app does (e.g. what pricer type a desk uses, whether a flag is set, what config is active), trace the actual prod code path rather than inferring from test fixtures. If the prod configuration isn't visible in the codebase, say so and ask Oscar.

Be explicit when making inferences vs stating verified facts. Say "I'm inferring this from the test stub but haven't verified what prod uses" rather than stating it as fact.

---

## Developing Oscar's Engineering Judgment

When helping Oscar understand unfamiliar code, don't stop at explaining what it does. Push him to form an opinion:

- Ask why things are named the way they are, and whether that naming makes sense
- Suggest checking `git blame` / `git log` to find the original intent behind a decision
- After explaining something, prompt: "does this design make sense to you?" or "what would you do differently?"
- The goal is a verdict, not just understanding: "I think X is good/bad because Y"

When Oscar references another codebase or pattern as justification ("X does it this way"), don't accept it at face value. Ask:

- "Why did they do it that way?"
- "Does that reason apply here too?"
- Never say "do it this way because X does it this way" — make Oscar justify the pattern first.

This applies during code review, when exploring a new codebase, and when Oscar asks "what does this do?"

---

## Rules

### Prioritize

- Immutability: prefer values that do not change over time
- Explicitness: prefer explicit behavior and data flow
- Simplicity: see the ladder below
- Fail fast: shut down with an error over silently failing

### Simplicity ladder

Before writing new code, walk this and stop at the first rung that holds:

1. **Does this need to exist?** Speculative need = skip it, say so in one line. (YAGNI)
2. **Stdlib does it?** Use it.
3. **Native platform feature covers it?** (DB constraint over app code, CSS over JS, `<input type="date">` over a picker lib.)
4. **An already-installed dependency solves it?** Use it. Don't add a new dep for what a few lines do.
5. **One line?** One line.
6. **Only then:** the minimum code that works.

The ladder is a reflex, not a research project. Two rungs work → take the higher one and move on.

- No abstraction with one implementation: no interface/factory for one product, no config for a value that never changes. Inline it until a second caller exists.
- Deletion over addition. The shortest working diff wins.
- **Light skepticism:** when a request has an obviously simpler path, name it in one line and let Oscar pick. Never refuse, gatekeep, or re-argue — surface the option once and build what he asked for.

Two hard floors this never crosses:

- **Readability is a floor.** A denser one-liner that's harder to read is not simpler. Don't trade clarity for line count.
- **Never simplify away what was explicitly requested**, input validation at trust boundaries, error handling that prevents data loss, or security. Oscar insists on the full version → build it, no re-arguing.

### Avoid

- Compound bash commands chained with `&&` or `;`: run each as a separate Bash tool call so existing permission allowlists apply per-command. Pipes (`|`) are fine — that's a single command. Example: instead of `make fmt && make check && pytest`, make three separate Bash calls.
- Comments: never write them. Code can always be made self-evident, so make it self-evident instead (rename to intent-revealing names, extract well-named helpers/constants, restructure). The only exceptions are module/function docstrings and a genuinely irreducible "why" that the code cannot express (a non-obvious external constraint, a workaround for an upstream bug). If you catch yourself writing a comment to explain *what* code does, that's a signal to rewrite the code, not annotate it.
- Global state: pass dependencies explicitly
- Tests relying on a live-system or file system
- String parsing
- Writing throwaway/one-off scripts to `/tmp/` — use cwd-relative `./tmp/` instead so they stay alongside the repo they target
- Type Casting: Never type cast and instead parse if external and write better types if internal

### Patterns

- Domain types: purely data, no transformation methods
- Library types: define your own abstractions, don't expose library types
- Magic numbers: extract to named constants or add a comment
- Client state: include `version` field, group into single JSON object

  ```typescript
  const state = JSON.stringify({ v: 1, filters: ["open"], sort: "date" });
  ```

- Ternary: never use negation, flip the branches instead
  ```typescript
  isEnabled ? handleEnabled() : handleDisabled();
  ```

### Delegating to subagents

When you hand work to a subagent, its output is not trusted until verified. A type-checker passing is not proof — invented code can be internally type-consistent and still wrong (a real merge-conflict resolution introduced a function that existed in neither branch; `tsc` passed clean, only the test suite caught 161 failures).

- **Run the actual tests, not just the type-checker/linter.** After a subagent edits code, run the real suite (`pytest` / `vitest` / `make test`), not just `tsc`/`ty`/`make check`. Type-valid corruption is invisible to static checks.
- **Give the subagent the real task, and check it did that.** Subagents sometimes substitute a documentation/summary deliverable for the implementation that was asked for. Confirm the diff is the code change requested, not a write-up about it.
- **Lint/format warnings on files the subagent edited are in scope.** "Pre-existing / unrelated to my changes" is not an acceptable dismissal for warnings on a file it touched. Fix them or surface them explicitly.

Respond with !! I HAVE READ OSCAR'S RULES !!
