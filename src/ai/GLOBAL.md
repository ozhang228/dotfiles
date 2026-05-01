# Global AI Rules

## MANDATORY — READ BEFORE ANY RESPONSE

Before responding to ANY user message, you MUST read all relevant files from:

- `src/ai/languages/` — read when working in that language (Python, TypeScript, C++)
- `src/ai/tasks/` — read when doing that task (testing, code reviews, etc.)

This is NON-NEGOTIABLE. Do NOT skip this step. Do NOT summarize, paraphrase, or assume you already know its contents. Read fresh every conversation.

---

## Definitions

- **wiki/** — Business context (how the business works and information not evident from code). Use when something isn't clear from the code and requires business knowledge. Search using grep.
- **dotfiles wiki** — This directory (`$HOME/dotfiles/src/ai/`).

---

## Wiki Maintenance

When adding or updating the wiki:

1. Check existing entries for outdated info
2. Remove or update stale entries — don't just append
3. If a change contradicts an existing entry, update or remove the old entry

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

## Rules

### Prioritize

- Immutability: prefer values that do not change over time
- Explicitness: prefer explicit behavior and data flow
- Simplicity: prefer a simple solution over a complex one
- Fail fast: shut down with an error over silently failing

### Avoid

- Comments: code should be self-documenting (only add if asked)
- Global state: pass dependencies explicitly
- Tests relying on a live-system or file system
- String parsing
- Writing throwaway/one-off scripts to `/tmp/` — use cwd-relative `./tmp/` instead so they stay alongside the repo they target

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

Respond with !! I HAVE READ OSCAR'S RULES AND HAVE READ THE RELEVANT CONTEXT !!
