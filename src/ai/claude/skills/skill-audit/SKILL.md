---
name: skill-audit
description: Audit existing skills and propose improvements or new skills based on patterns observed across conversations. Use when asked to review skills, improve workflows, or when conversations have surfaced repeated friction points that suggest a skill is missing or broken.
---

# Skill Audit

Review all skills for gaps, stale content, and improvement opportunities. Propose new skills when a pattern recurs across conversations that no current skill handles.

## Effectiveness criteria

A skill is effective when:

1. **Trigger fires correctly** — it activates on the right prompts and not on unrelated ones
2. **Workflow matches practice** — the steps reflect what actually happens, not an idealized version that gets overridden
3. **Output needs minimal correction** — the user accepts the output without restructuring it
4. **References are used** — reference files are loaded and consulted, not ignored
5. **No manual workarounds** — the user doesn't bypass the skill to do the work themselves

A skill needs attention when any of these fail consistently.

## Workflow

### 1. Collect observations

Pull saved memory observations (`skill-observation:` entries) plus reflect on the current conversation for the signals listed in "Passive observation" above.

### 2. Inventory all skills

List every skill in `~/.claude/skills/`. For each, read its `SKILL.md` and note:

- What it does (from description)
- Whether its workflow/references are complete or have placeholders
- Whether the trigger condition matches how it's actually being invoked
- Whether it passes the effectiveness criteria above

### 3. Cross-check observations against skills

For each observation, identify which skill it belongs to (or confirm no skill covers it). Build a map:

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

After applying, clear the corresponding memory observations.
