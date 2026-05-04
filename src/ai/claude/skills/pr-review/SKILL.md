---
name: pr-review
description: Review a pull request the way Oscar wants it reviewed. Use when asked to review a PR, review a branch, review a diff, or give code-review feedback on pending changes. Runs in two phases (interview first, deep review second), labels every comment (Question/Unclear/Incorrect/Model/Nit), and prints output directly to chat under `## file_path:` headings. Prefer this over the generic built-in review for Oscar's projects.
---

# PR Review

## Output Format

- Print review output directly to the chat. Do not write it to a file.
- Use a heading: `## file_path:`
- Under it, list numbered review comments

## Running git commands

- Never prepend `cd <path> && git …` — that triggers a "cd before git" permission prompt and requires human approval. Use `git -C <path> …` instead, or just run git from the current working directory (it already operates on the current tree).
- The review must run end-to-end without permission prompts. If a command would require approval, pick an equivalent that doesn't.

## Process

1. **Check the branch is up to date with the base before diffing.** Run `git -C <repo> merge-base --is-ancestor <base> HEAD` (or `git -C <repo> log --oneline <base> ^HEAD | head`) to see if the base has commits the branch is missing. If the branch is behind, **ask the prompter** whether to merge the base in before reviewing. Diffing against a stale branch surfaces changes from the base as if they belong to the PR — a common false-positive that wastes review time.
2. Do a git diff against master (unless another branch is specified).
3. Read full files and related files for context.
4. **Read the tests first.** Tests encode the expected behavior of the PR. They show what the author thinks the code should do. Flag any expected behavior that looks weird, surprising, or wrong *before* looking at the implementation. Then check the implementation against this understanding.

## Iterations

### Phase 1: Build understanding (do these first, then STOP)

1. **PR summary:** For each changed file, summarize: (a) what it does, (b) why, (c) notable design choices.
2. **Understand the change:** Call out unclear naming or overly complex control flow.

**After completing steps 1–2, STOP and enter interview mode.** Present your summary and understanding to the prompter, then ask targeted questions. Do NOT proceed until the prompter says to continue.

### Phase 2: Deep review (only after interview is resolved)

3. **Correctness pass:** Find logic that may be wrong. Describe failure cases.
4. **Modeling + nits:** Evaluate data/modeling approach.

**Draft the full review to `./tmp/pr-review-<branch>.md` first** (a cwd-relative scratch file). Include every comment with its label, file:line, and message. Then **walk the user through one comment at a time**, in file order. Print only the single current comment and wait for the user's response before moving on. Update the scratch file as you go if the user's response changes the status (e.g. "nvm, that's fine" → strike it out). This prevents the "wall of 15 comments at once" problem where users skim instead of engaging.

## Labels

Every comment must be labeled:

- **Question:** need info to understand
- **Unclear:** naming/control flow unclear
- **Incorrect:** logic produces wrong result
- **Model:** data/modeling approach doesn't make sense
- **Nit:** style issue (non-functional)
