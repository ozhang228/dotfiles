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

## How to write comments (distilled from pnickols, alchen, ajyang)

### Ask questions, don't just flag

Prefer "what does it mean for a product to be lognormal" over "this naming is bad". Questions surface intent; declarations provoke defense.

Real examples:
- "Does this mean we *need* the new version of luna or just that we are compatible with it?" (pnickols — clarifying dependency semantics)
- "Do we know if this has performance implications?" (alchen — short, doesn't assume, just flags)
- "Did we consider just returning `Timestamped[DeskPortfolio]` from STS? otherwise, we will have an awkward time constructing `DeskPortfolio` from sources like tradio (or have to invent a fake timestamp)" (ajyang — proposes alternative and explains downstream consequence)

### Explain the *why* when you flag something

Flagging without reasoning makes the author guess. A one-clause explanation tells them how to fix it and whether the concern applies to their specific situation.

Real example (ajyang):
> "I don't think this is a step in the right direction if we need to add two new TODOs (not counting the TODO about spot instruments) into the code. Can we resolve some of them here, or remove them if we don't think they're really necessary?"

The concern (accumulating debt), the ask (resolve or remove), and the scope qualifier (not counting the spot one) are all one sentence.

### State forward-compatibility concerns explicitly

Strong reviewers in this codebase raise "what if this grows?" before it becomes a problem.

Real example (pnickols):
> "This change is fine but do we anticipate making other things optional/more views? If so it may be cleaner to just group 'desk_optional_topics' and 'all_desk_topics' or something rather than make signal_ev specifically different"

Pattern: "this is fine BUT if [anticipated growth], THEN [here's the cleaner alternative]."

### Escalate to process when scope exceeds the PR

When a comment reveals a cross-cutting concern, propose a structured next step instead of just blocking.

Real example (alchen):
> "I think we should hold a bigger discussion about this. This is not just a typescript problem — we need this in python dash apps as well. I think we should start with a spec wiki, and reach consensus before moving further with this"

Real example (alchen):
> "can we lump this into #2361 and table this for now, or is this urgent?"

### Say what you're NOT reviewing

When you're scoping your review to a subset of the diff, say so explicitly so the author knows what still needs eyes.

Real example (pnickols):
> "N.B. I didn't review the code (i.e. `.cpp, .h` changes) under the statement that they were all deletes or just formats. If anything deserves attention, please let me know"

### Separate logic approval from structural concerns

You can approve correctness while still asking for refactoring. Name both explicitly.

Real example (ajyang):
> "Logical-wise everything here mostly looks good to me 👍 with some key caveats — code needs to be split up a bit more — I agree with you that this doesn't fully achieve our goal of separating publishers… I'd like to agree on the end state there before proceeding with these intermediate changes"

### Express genuine surprise at unexpected design

If something is surprising but technically correct, say it. It invites the author to explain the rationale, which might reveal a real problem or close a knowledge gap.

Real example (ajyang):
> "> Caltime is discretised based on dates, rather than continuous based on time till expiry
> this is really surprising and I'm curious why. code-wise I think this is a fine way to express it"

### Verify claims by doing it yourself

Strong reviewers test locally and report back.

Real example (alchen):
> "verified locally that if I run all 4 publishers I can still see it on frontend… and it works [images]"

### Label nits as nits

When something is genuinely non-blocking style, say so up front. It signals to the author they don't need to respond.

Real examples:
- "I prefer writing out `cumberland`, but NBD either way" (ajyang)
- "Please change the PR title, otherwise LGTM" (ajyang — single nit as the only blocker)
- "Fine change, think PR description could say why do this though?" (pnickols — notes a gap without blocking)

### Articulate the ideal end state when proposing a rethink

Don't just say "this is wrong". Show what good looks like.

Real example (ajyang):
> "arguably the end state here is a different risk viewer from the desk one, analogous to how the empirical risk dashboard and the empirical risk management view are different apps. I think in an ideal world (with more dev work) we'd have a high-level overview for management that you can click to drill into the granular-level details"

### Verify stakeholder alignment before unblocking

For features or config changes driven by desk asks, check that the ask is confirmed.

Real examples:
- "desk confirmed they want this?" (alchen)
- "What is the process to run e.g. crude or centerbook risk viewer locally now? How many processes need to run concurrently?" (pnickols — asking about operational impact)

## Reviewer voice reference

| Reviewer | Strength | Signature patterns |
|---|---|---|
| pnickols | Forward-compatibility, operational impact, PR description quality | "Does this mean...", "If so it may be cleaner to...", "N.B. I didn't review...", "nothing blocking", "maybe am being dumb" |
| alchen | Architectural alternatives, API/config sprawl, long-term planning, stakeholder alignment | "Can we...", "What's the long term plan", "This is not just a X problem", "verified locally", "let's make sure to" |
| ajyang | Design implications, type system, test quality, downstream consequences | "Did we consider...", "I'm curious why", "in an ideal world", "no more blockers from my side", "I really like the tests" |

## What NOT to do

- **Comment on what the diff already shows.** "This adds a new `FooClient` class" — the diff shows that.
- **Raise correctness concerns without describing the failure case.** "This might be wrong" with no scenario is useless.
- **Block on nits without labeling them as nits.** The author can't prioritize if everything looks equally weighted.
- **Ask questions you could answer yourself by reading context.** Read the related files first.
- **Write multiple paragraphs for a one-sentence concern.** If it takes more than two sentences, you probably haven't identified the core question yet.
