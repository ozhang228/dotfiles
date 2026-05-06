---
name: update-wiki
description: Add, update, or prune entries in Oscar's wiki (`~/forge/ai_wiki/`). Use when the user says "add this to the wiki", "wiki this", "update the wiki", "document X in the wiki", or when a conversation surfaces durable business/domain knowledge that Claude should recall in future sessions. Enforces the rule "only non-derivable knowledge belongs here" — rejects architecture dumps and file-path inventories that will rot.
---

# Update Wiki

Wiki location: `~/forge/ai_wiki/`. It lives in the `forge` monorepo.

## The one rule

**The wiki stores knowledge that isn't in the code and can't be grepped out of it.**

If a future refactor, rename, or file move would force a wiki edit, that content probably shouldn't have been in the wiki. Claude can always read the code; Claude can't always guess why a desk trades what it trades, or why a production pod needs a restart.

## Belongs in the wiki

| Type | Example | Why |
|---|---|---|
| **Business / domain concepts** | "Scallop = PnL decomposition into greek components" | A trader would explain this verbally; code uses the term as a given |
| **Desk knowledge** | "Natgas market quiets at noon — best demo window", "PH/PHE are mirrors of NG" | Market structure, not code |
| **Product relationships** | "TTP and TTFC are the CME listings of the same underlying as TFOI (ICE)" | Cross-exchange mapping you'd never derive from a single file |
| **Conventions that span the repo** | OPXL key naming, Kafka topic naming, "use sneagle MIC here not exchange symbol" | Load-bearing patterns a grep won't surface |
| **Design constraints** | "Trader screens are cramped — every panel must be collapsible" | Stakeholder reality, not code |
| **"Restart fixes it" operational knowledge** | What state is frozen at startup vs. live-mutated vs. self-healing in a long-lived pod | Failure modes that cost hours to rediscover |
| **Counterintuitive gotchas** | "`NerdListingSymbol` is a class not a NewType — pass `.nerd_symbol` to refdata lookups" | Looks like a bug, is intentional. Saves the next person the same confusion. |
| **Design rationales for absences** | "We deliberately don't have a `ProductSurfaceGrid` type because…" | Prevents well-meaning refactors from undoing past decisions |
| **External reference pointers** | Confluence URL, Linear project code, Grafana dashboard URL, Slack channel | Where to go to find live state |
| **Stakeholders** | "App Launcher is owned by <team>; bugs go to <channel>" | Social graph isn't in git |

## Does NOT belong

**If you're tempted to write any of these, stop and reconsider.**

| Type | Why not | Where it should live |
|---|---|---|
| Module / file / class inventories ("`foo.py` contains `FooClient` which does X") | Rots the second anyone renames a file | Let Claude read the code |
| Architecture diagrams describing current code structure | Same | Let Claude read the code |
| Per-function signatures or method lists | Same | Let Claude read the code |
| Embedded scripts (100 lines of Python pasted in) | Two sources of truth → drift | Link to the actual script path |
| Refactor history ("we moved X from Y to Z in PR #2607") | That's what `git log` is for | `git log`, PR descriptions |
| Deleted / renamed file notes ("was briefly `VolSurfaceGrid`, renamed back") | Noise once the rename is a year old | Delete |
| Restatement of things visible in the code itself | Code is authoritative | Delete |
| Per-task ephemeral state ("currently working on X") | Belongs in conversation / PR / tasks | TaskCreate, not wiki |
| Anything already in a `CLAUDE.md` or an `ai_rules/` file | Duplication → drift | Point at the existing doc |

## Shape of a good entry

```markdown
# <Name>

<One-line description. What it is, what it replaces if anything.>

Code: <path>
User docs: <URL if any>

## What it does (one paragraph max)

<Only if the name alone doesn't convey it. Skip for obvious cases.>

## <Business concept this touches>

<The non-obvious *why*. Link to trading_definitions.md when a term has one.>

## Gotchas

- **<One-line summary of the trap>.** <Why it's a trap. What to do instead.>

## Restart-fixes-it state (long-lived services only)

<What's frozen at startup, live-mutated, periodic, cached. Helps diagnose "only a restart fixes it" incidents.>

## External references

- <Confluence / Linear / Grafana / Slack pointers>
```

Not every entry needs every section. A 10-line entry pointing at the code path + one gotcha is fine. **Empty is better than filler.**

## Process

1. **Read `~/forge/ai_wiki/` layout first.** Top-level `trading_definitions.md` + `deployment.md`; subdirs `desks/`, `projects/`, `software_teams/`. Pick the right location.
2. **Grep before writing.** The user may have an existing entry on the same topic. `grep -ri "<topic>" ~/forge/ai_wiki/`. Update the existing entry in place if there is one — don't create a duplicate.
3. **Prune while you're there.** If the existing entry has any of the "does NOT belong" content, delete it in the same commit. The wiki rule from `GLOBAL.md`: *"If a change contradicts an existing entry, update or remove the old entry."* The same applies to entries that are merely stale, not contradictory.
4. **Match the existing style.** Look at `trading_definitions.md`, `desks/natgas.md`, and `deployment.md` — those are the reference quality bar. Terse, fact-first, tables where a table helps.
5. **Follow Oscar's writing rules.** No em dashes. No "This adds…" openers. Contractions are fine. No padding.
6. **Prefer lists over prose.** Gotchas, state descriptions, and conventions read better as bulleted lists with a bolded lead.
7. **Link, don't copy.** External docs → URL. Scripts → file path, not embedded code. Cross-wiki terms → reference the other file.
8. **After writing, verify the diff.** `git -C ~/forge diff`. Scan for any line that a rename would invalidate — if you find one, ask whether it really belongs.

## Promoting from conversation

When the user says "add X to the wiki" based on something they just told you:

1. Restate the fact as you'd write it. Ask "does this capture it?" before writing. Oscar-style prose not Claude-style prose.
2. Check whether it's a desk-specific fact (→ `desks/`), project-specific (→ `projects/`), cross-project (→ `trading_definitions.md` or a new top-level file), or operational (→ `deployment.md`).
3. If the fact overlaps an existing entry, merge rather than append.
4. Surface anything you had to guess at. Better to confirm than invent.

## Red flags when reviewing a wiki edit

- Every heading in the entry matches a file path → architecture dump, not business knowledge.
- Length > 100 lines for a single entry → probably needs pruning or splitting.
- Contains class/function names as primary content → grep territory, not wiki.
- Contains a fenced code block longer than ~20 lines → should be a file reference instead.
- Reads like a PR description → belongs in git, not the wiki.
- Contains dated statements ("as of 2026-Q2 we are migrating…") without a **Why** and a clear expiration → will mislead once the migration finishes.
