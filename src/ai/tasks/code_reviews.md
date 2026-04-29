---
applies_to: When performing a code review
skip_if: Not doing a code review
---

# Code Reviews

## Output Format

- Print review output directly to the chat. Do not write it to a file.
- Use a heading: `## file_path:`
- Under it, list numbered review comments

## Process

1. Do a git diff against master (unless another branch is specified)
2. Read full files and related files for context
3. **Read the tests first.** Tests encode the expected behavior of the PR — they show what the author thinks the code should do. Flag any expected behavior that looks weird, surprising, or wrong *before* looking at the implementation. Then check the implementation against this understanding.

## Running git commands

- Never prepend `cd <path> && git …` — that triggers a "cd before git" permission prompt and requires human approval. Use `git -C <path> …` instead, or just run git from the current working directory (it already operates on the current tree).
- The review must run end-to-end without permission prompts. If a command would require approval, pick an equivalent that doesn't.

## Iterations

### Phase 1 — Build understanding (do these first, then STOP)

1. **PR summary:** For each changed file, summarize: (a) what it does, (b) why, (c) notable design choices.
2. **Understand the change:** Call out unclear naming or overly complex control flow.

**After completing steps 1–2, STOP and enter interview mode.** Present your summary and understanding to the prompter, then ask targeted questions. Do NOT proceed until the prompter says to continue.

### Phase 2 — Deep review (only after interview is resolved)

3. **Correctness pass:** Find logic that may be wrong. Describe failure cases.
4. **Modeling + nits:** Evaluate data/modeling approach.

## Labels

Every comment must be labeled:

- **Question:** need info to understand
- **Unclear:** naming/control flow unclear
- **Incorrect:** logic produces wrong result
- **Model:** data/modeling approach doesn't make sense
- **Nit:** style issue (non-functional)

