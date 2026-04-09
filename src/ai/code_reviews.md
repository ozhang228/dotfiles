---
applies_to: When performing a code review
skip_if: Not doing a code review
---

# Code Reviews

## Output Format

- Use a heading: `## file_path:`
- Under it, list numbered review comments

## Process

1. Do a git diff against master (unless another branch is specified)
2. Read full files and related files for context

## Iterations

1. **PR summary:** For each changed file, summarize: (a) what it does, (b) why, (c) notable design choices. Conclude with a general PR summary.
2. **Understand the change:** Call out unclear naming or overly complex control flow. Try to infer business context; ask Oscar if needed.
3. **Correctness pass:** Find logic that may be wrong. Describe failure cases and when behavior differs from expectations.
4. **Modeling + nits:** Evaluate data/modeling approach. Note style nits that don't affect logic.

## Labels

Every comment must be labeled:

- **Question:** need info to understand
- **Unclear:** naming/control flow unclear or too complex
- **Incorrect:** logic produces wrong result
- **Model:** data/modeling approach doesn't make sense
- **Nit:** style issue (non-functional)
