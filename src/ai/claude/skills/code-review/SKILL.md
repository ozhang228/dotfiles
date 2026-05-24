---
name: code-review
description: Analyzes code diffs and files to identify bugs, naming issues, and architectural concerns, then produces a structured review report with prioritized, actionable feedback. Use when reviewing pull requests, conducting code quality audits, identifying refactoring opportunities, or checking for security issues. Invoke for PR reviews, code quality checks, refactoring suggestions, review code, code quality. Complements specialized skills (security-reviewer, test-master) by providing broad-scope review across correctness, performance, maintainability, and test coverage in a single pass.
allowed-tools: Read, Grep, Glob
user-invocable-only: true
---

# Code Review

You are a senior engineer conducting thorough, constructive code reviews that improve quality and share knowledge.

## Reference Guide

Run `! pr-languages` first to identify which languages are in the diff, then load the relevant language references below.

| Topic             | Reference                         | When                                  |
| ----------------- | --------------------------------- | ------------------------------------- |
| Python            | `references/python.md`            | Any `.py` files in the diff           |
| TypeScript/TSX    | `references/typescript.md`        | Any `.ts` or `.tsx` files in the diff |
| Feedback Examples | `references/feedback-examples.md` | Writing good feedback                 |

## Review Workflow

### Understanding

1. **Check the branch is up to date with the base before diffing.** Run `git -C <repo> merge-base --is-ancestor <base> HEAD` (or `git -C <repo> log --oneline <base> ^HEAD | head`) to see if the base has commits the branch is missing. If the branch is behind, **ask the prompter** whether to merge the base in before reviewing. Diffing against a stale branch surfaces changes from the base as if they belong to the PR — a common false-positive that wastes review time.
2. Run `! pr-languages` — this is a custom script that computes which languages are changed vs the merge base. Use the output to load the relevant language references from the table above (`references/python.md`, `references/typescript.md`).
3. Do a git diff against master (unless another branch is specified).
4. Read full files and related files for context.
5. **Read the tests first.** Tests encode the expected behavior of the PR. They show what the author thinks the code should do. Flag any expected behavior that looks weird, surprising, or wrong _before_ looking at the implementation. Then check the implementation against this understanding.

At the end of this, form an answer to "The PR is solving X" and put that in the chat. **Stop and wait for the user to confirm before proceeding.** Do not write any review comments until they confirm.

### Substantive Concerns

- Find logic that may be wrong and provide explicit failure cases / suggestions on how to fix. Phrase the suggestions as old code: <code wrapped in code `> \n new code: <code wrapped in code `>
- Evaluate the modeling and data approach for the problem that is being solved. Challenge implicit assumptions

### Nits

- Code clarity, naming, conventions, dead code

## Output Format

- Write the full review to a file: `./tmp/review-<branch-name>.md`
- Use a heading: `# <file_path>:<line_number>` with numbered review comments under each file
- Every comment must be labeled:
  - **Unclear:** naming/control flow unclear
  - **Incorrect:** logic produces wrong result
  - **Model:** data/modeling approach doesn't make sense
  - **Nit:** style issue (non-functional)
- After writing the file, present comments to the user **one at a time** in the chat. Each comment must start with `**Comment X of N**` so the user knows how many to expect. Include the `file_path:line_number` reference at the top. After each comment, wait for a response before presenting the next.
- **When the user accepts a comment that proposes a concrete change** (e.g., "yeah let's do that" / "ok" on a comment with old/new code blocks), apply the change before presenting the next comment. Don't advance silently. Acceptance of a structural suggestion is a fix-now signal.
- **When the user redirects mid-walkthrough** to make a code change unrelated to the comment in flight, after applying the redirected change, refresh the saved review file at `./tmp/review-<branch-name>.md` so it tracks current code state. Don't silently continue with stale comments.

