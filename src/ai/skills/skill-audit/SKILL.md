---
name: skill-audit
description: Audit existing skills and propose improvements or new skills based on patterns observed across conversations. Use when asked to review skills, improve workflows, or when conversations have surfaced repeated friction points that suggest a skill is missing or broken.
---

# Skill Audit

Review all skills for gaps, stale content, and improvement opportunities. Propose new skills when a pattern recurs across conversations that no current skill handles.

## Reference

The principles and vocabulary for writing skills well live in reference files. Load them when diagnosing why a skill underperforms (step 2) or when proposing/writing skill changes (steps 4–5) — they give the named levers and failure modes to reason with, not just "this feels off."

| Topic | Reference | When |
| ----- | --------- | ---- |
| How to write/edit a skill well | `references/writing-great-skills.md` | Diagnosing a weak skill, proposing improvements, or writing a new one |
| Definitions of the bold terms | `references/skills-glossary.md` | Looking up a term (predictability, leading word, progressive disclosure, premature completion, etc.) |

## Effectiveness criteria

A skill is effective when:

1. **Trigger fires correctly** — it activates on the right prompts and not on unrelated ones
2. **Workflow matches practice** — the steps reflect what actually happens, not an idealized version that gets overridden
3. **Output needs minimal correction** — the user accepts the output without restructuring it
4. **References are used** — reference files are loaded and consulted, not ignored
5. **No manual workarounds** — the user doesn't bypass the skill to do the work themselves

A skill needs attention when any of these fail consistently.

The criteria say *whether* a skill is failing; the **failure modes** in `references/writing-great-skills.md` say *why* and *what lever fixes it*. When a skill underperforms, name the failure mode driving it:

- **Premature completion** — a step ends before the work is genuinely done (fix the completion criterion first; split the sequence only if the bound is irreducibly fuzzy).
- **Duplication** — the same meaning in more than one place.
- **Sediment** — stale layers never cleared.
- **Sprawl** — too long even when every line is live; cure with progressive disclosure and splitting.
- **No-op** — a line the model already obeys by default (a weak leading word is a no-op; fix with a stronger word, not more prose).

## Workflow

### 1. Collect observations

Pull saved memory observations across **all project memory directories**:

```
find ~/.claude/projects -path '*/memory/*' -type f \( -iname 'skill?obs*' -o -iname 'skill-observation*' \)
```

Observations live in per-project (`~/.claude/projects/-home-ozhang-*/memory/`) and shared (`~/.claude/projects/-shared-*/memory/`) dirs — checking only the current project's memory misses ones logged elsewhere. These are saved ad hoc (there's no longer a Stop hook auto-prompting for them), so the pile is whatever has accumulated since the last audit — there may be few or none.

Reflecting on the current conversation matters more now that nothing auto-collects observations: did the user correct a skill's output, bypass a skill manually, or hit a gap the skill didn't cover? That live signal is a primary input, not a supplement.

### 2. Inventory all skills

List every skill in `~/.claude/skills/`. For each, read its `SKILL.md` and note:

- What it does (from description)
- Whether its workflow/references are complete or have placeholders
- Whether the trigger condition matches how it's actually being invoked
- Whether it passes the effectiveness criteria above
- **Whether it's user-modifiable.** Skills under `~/.claude/skills/` (symlinked from `~/dotfiles/src/ai/claude/skills/`) are editable. Built-in / plugin skills (e.g. `init`, `review`, `security-review`) are flag-only — observations targeting them can be surfaced but not fixed.

### 3. Cross-check observations against skills

For each observation, identify which skill it belongs to (or confirm no skill covers it). Mark each as **editable** or **flag-only** based on step 2. Build a map:

```
skill-name → [observation 1, observation 2, ...]
new skill candidate → [what triggered it, what it should do]
```

### 4. Propose changes

Present the full list to the user grouped by skill before making any edits:

- **Improvements** — specific changes to existing skills (wrong workflow step, missing reference, stale content, broken trigger)
- **New skill candidates** — pattern + what the skill would do + trigger condition
- **Skills to retire** — skills that overlap heavily with another or are never invoked

Get approval on the list before writing anything.

### 5. Apply

For approved improvements, edit the relevant `SKILL.md` or reference files directly. For new skills, create the directory and `SKILL.md` with the standard format (frontmatter with `name` and `description`, workflow, reference table if references exist).

Write to the principles in `references/writing-great-skills.md`, not just to fix the immediate complaint:

- **Invocation:** does this skill need a model-facing description (agent or another skill must reach it), or is it user-invoked? Don't pay context load for a description nothing fires on.
- **Description:** one trigger per branch, front-load the leading word, cut identity already in the body.
- **Information hierarchy:** keep SKILL.md legible — disclose bulky reference behind a context pointer (a linked file), inline only what every branch needs.
- **Leading words:** hunt restated triads and fuzzy phrases that collapse into one pretrained word; it sharpens both execution and invocation.
- **Pruning:** every line must change behaviour vs. the default (kill no-ops), and each meaning gets one source of truth (kill duplication).

After applying, clear the corresponding memory observations.
