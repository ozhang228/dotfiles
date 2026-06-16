---
name: revise-message
description: Revise short work messages (Slack DMs, stakeholder emails, announcements, pitches, signoff requests, re-pings) so they read clearly and land the ask. Applies Oscar's writing rules, cuts hedges that undermine the point, and concretizes vague phrases. TRIGGER on "help revise this", "make this sound better", "help me reframe", "reword plz", "tighten this up", "what should I type", "how should I phrase this" applied to a paragraph of work prose. SKIP for PR descriptions and commit messages (those have their own conventions) and for code.
allowed-tools: Read
user-invocable-only: true
---

# Revise Message

Revise a short work message so it's clear, direct, and gets the response Oscar wants. The input is usually a Slack DM, a stakeholder email, a feature announcement, a pitch, a signoff request, or a re-ping after silence.

## What you produce

Two things, always:

1. **The revised message** — ready to paste, no placeholders.
2. **A short bulleted list of what changed and why** — so Oscar learns the pattern, not just gets a rewrite. One bullet per substantive change. Skip trivial typo fixes from the list unless they change meaning.

## Writing rules (from GLOBAL.md, applied here)

- No em dashes. Use commas, parentheses, periods, or colons.
- No "X, not Y" aphorisms where a plain statement works.
- No formal transitions ("Moreover", "Furthermore", "In addition"). Just say the next thing.
- Contractions are fine and usually better.
- Don't pad. If a sentence isn't doing work, cut it.
- Don't open with "This change..." / "I wanted to..." — lead with the verb or the subject.

## What to fix

- **Cut hedges that undermine the ask.** "not a huge deal", "while this could be user error", "I wanted to get ahead of the curve", "sorry to bother" — these tell the reader the message is low-priority or that Oscar isn't sure. Remove them unless the hedge is doing real diplomatic work.
- **Concretize vague phrases.** "aggregation magic" → what it actually does. "the thing broke" → what broke. Vague phrasing makes the reader do work and erodes confidence.
- **Fix grammar** that makes Oscar look careless ("ended up created" → "ended up creating").
- **Don't over-soften a real ask.** If Oscar needs something, the message should make that obvious and easy to act on.

## Sub-patterns

These recur and have a specific right move:

- **Rhetorical-question stacks / complaint-shaped framing.** Oscar's drafts sometimes stack pointed questions or hedges that read as a complaint or as a decision already made. Reframe to invite context rather than agreement: add a genuine open-ended close ("curious if I'm missing something here", "open to other ways to slice it"). This turns "why is this like this" into "help me understand this," which gets cooperation instead of defensiveness.
- **Re-pings after silence or vacation.** Acknowledge the gap warmly ("welcome back", "hope the time off was good"), signal continuation ("circling back on"), compress the original message since they're reading it fresh with no context, and drop now-stale pleasantries from the first attempt.
- **Pitches / stakeholder asks.** Follow the Pitch Pattern in GLOBAL.md: lead with their benefit, ground urgency in something they already felt, be honest about gaps, frame as collaboration, make the next step concrete.

## Flow

1. Read the draft and infer the goal: what response does Oscar want from the reader? If it's genuinely unclear, ask one short question. Otherwise infer and proceed.
2. Revise per the rules and the relevant sub-pattern.
3. Output the revised message, then the bulleted changes.

Keep it fast. This is a high-frequency, low-ceremony task. Don't over-explain.
