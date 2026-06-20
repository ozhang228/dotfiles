---
name: code-explain
description: Deep codebase walkthrough that produces an ordered reading tour with prerequisites, inline opinions, and a follow-up conversation. Use when the user asks to understand how a system, feature, or concept works in the codebase.
allowed-tools: Read, Grep, Glob, Bash
user-invocable-only: true
---

# Code Explain

Produce a structured reading tour that lets the user understand a codebase concept by reading the real code in the right order, with enough context to actually follow it.

## Principles

- The user reads the real code. Don't paste large inline snippets — give `file:line` anchors and describe what to look for.
- Explain prerequisites before pointing at code that depends on them. If the code takes an invariant as a given, explain that invariant first.
- Include your opinions inline. If naming is confusing, say so and explain the real concept. If something could be done better, say how and why it was done this way instead.
- The goal is a verdict, not just comprehension. At the end the user should have a point of view on the design, not just a description of what it does.
- Length follows the concept. Don't pad, don't truncate. Some systems need 3 stops, some need 12.

## Workflow

### 1. Explore (silent)

Use Grep, Glob, and Read to build a complete mental model of the topic before producing any output. Trace through all relevant layers — entry points, core logic, data structures, abstractions. Understand the full shape, not just the surface.

Do not output anything during this phase.

### 2. Identify prerequisites

Before writing the tour, identify:
- Key invariants the code assumes (data shape, lifecycle, ordering guarantees)
- Abstractions or patterns the user needs to recognize before the code makes sense
- Any non-obvious vocabulary used in the code

### 3. Write the tour document

Produce a document in this format:

---

## Prerequisites

Explain the concepts, invariants, and data structures the user needs to understand before reading any code. Be specific: name the invariant, describe the data shape, explain the abstraction. This section exists so that when the user sees the code, it clicks immediately rather than needing to reverse-engineer context from the implementation.

## Reading Tour

### 1. [Short descriptive title] — `path/to/file.py:42`

What to look for here. Why start here. What this reveals about the system.

[If you have an opinion: "The name `X` is a bit misleading — this is really doing Y. It's called X because [history/reason]."]

### 2. [Short descriptive title] — `path/to/other.py:100`

What this builds on from the previous stop. What new concept it introduces. What to pay attention to.

[If relevant: "This could have been structured as X instead, which would make the Z flow cleaner. It's done this way because..."]

...continue for as many stops as the concept requires...

---

### 4. Conversation

After outputting the tour, invite the user to start reading and come back with questions. As they ask questions:
- Answer directly and concisely
- Push toward opinions: "does that structure make sense to you?", "what would you do differently here?"
- If something is confusing, don't just re-explain — ask what they expected and work from there
- The conversation ends when the user has a complete mental model and a point of view on the design
