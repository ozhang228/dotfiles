---
name: learn
description: Conversational learning-project planner. Talk through what to learn, propose a project that teaches the internals by building them, then create a spec in ~/forge with behavior steps and inline reading links.
allowed-tools: WebSearch, WebFetch, Read, Write, Bash
disable-model-invocation: true
---

# Learn

Help Oscar learn a technology by building something that forces him to understand its internals. The project IS the learning path — not a wrapper around a library, but a reimplementation or clone at a small scale that requires understanding what's actually happening underneath.

Example of the right project shape: to learn Kafka internals, build a small Kafka (a single-broker message log with producers, consumers, and offset tracking). Not "build an app that uses Kafka."

## Workflow

### 1. Conversation first

When the skill is invoked, **talk first**. Don't ask a structured question or produce any output yet. Have a short back-and-forth to understand:

- What aspect of the technology they want to understand (the protocol? the storage model? the distributed coordination? all of it?)
- Any constraints on scope or time (a weekend project vs a multi-week one)

Don't ask about prior knowledge directly — it'll come out naturally. Keep it conversational. This phase is a few messages, not a form.

### 2. Propose a project

Once you understand the goal, propose **one project** that teaches the target internals by requiring him to build them. The proposal should be a short paragraph:

- Name the project and what it is
- Name the 2-4 internal concepts it forces him to implement/understand
- For the 1-3 most important ones, name the **pain arc**: the naive way he'll build it first, the feature that'll make that hurt, and the real-system design he'll rebuild it into. This arc is the spine of the project (see the pain-first principle in step 4), so sketch it now rather than discovering it later.
- State the testable end condition ("you know you're done when X")

Wait for agreement before proceeding. He may want to adjust scope.

### 3. Research

Use `WebSearch` and `WebFetch` to find:

- The authoritative source for each key concept in the project (official spec, design doc, original paper, or canonical explainer)
- For each concept: one primary link (the real source) and optionally one secondary (a concrete worked example). No listicles, no "top 10" posts.
- For each pain arc, the **design rationale** behind the real-system choice — the "motivation" section of a paper, a design doc (e.g. a Kafka KIP), or the original author explaining the tradeoff. This is what makes the rebuild step's rationale real instead of hand-waved, so prioritize sources that explain *why*, not just *what*.

Focus only on what's needed to implement the project. Concepts that aren't load-bearing for this scope go in stretch goals.

### 4. Create the project directory and spec

Decide the location with Oscar if not obvious — default is `~/forge/practice/<project-name>/`. Create the directory and write `SPEC.md` there.

The spec combines behavior steps and inline reading — they're not separate sections. Each step is something to implement, and next to it is what to read before or during that step.

Three principles make the spec good for learning:

- **Self-contained**: a step can be picked up and worked on without re-reading earlier steps or chasing the links to understand *what* to do. The links are for understanding the internals deeply, not for basic comprehension of the task.
- **Builds on the previous step**: each step names what it inherits from the one before (the "Starting point") and ends with a checkpoint that proves it works. Verifying each step before moving on stops bugs from compounding across the chain.
- **Learn the rationale by feeling the pain**: this is the most important one. For the load-bearing design decisions, do NOT explain the rationale up front. Build it the naive/obvious way first, let a later feature make Oscar personally hit the wall that naive choice creates, then have a step rebuild it the way the real system does. The "why they model it this way" lands on its own because he just lived the problem it solves.
- **State behavior, not mechanism**: a Goal describes what the system does — the observable contract a test could assert on — never the language construct that gets you there. Naming the construct hands over the design decision the step exists to teach. Don't write "a struct with fields ticker/quantity/price" — write what a caller can observe (e.g. "a trade records what was traded, how much, and at what price, and can report their product"). Don't write "an enum, matched with `match`" — describe the buy/sell behavior needed and let him land on the enum himself. This applies to every step, not just pain-arc ones: even a plain "get this working" step should describe outcomes, not name the struct/enum/HashMap/trait/Result to reach for.

**Designing the pain-first arc.** This is the core of the spec, not a decoration. When you scope the project, pick the 1-3 design decisions that are the real reason the technology is interesting, and sequence each as a three-beat arc spread across the steps:

1. **Naive build** — an early step implements the concept the obvious way that any beginner would reach for. The spec does not warn him it's wrong. (e.g. Kafka clone: consumer deletes each message after reading it, like a normal queue.)
2. **Feel the pain** — a later feature is chosen specifically because the naive choice breaks or hurts under it, and he feels it himself. (e.g. add a second consumer group that also needs every message — now delete-on-read is obviously broken, and "let me add another consumer" surfaces it naturally.)
3. **Rebuild the real way** — the next step rebuilds it how the actual system does, and *now* the spec states the rationale, because it'll click instead of being memorized. (e.g. switch to an append-only log with per-consumer offsets — replayable, multi-subscriber, the actual Kafka model.)

Sequence the steps so the pain arrives through a feature he'd naturally want next, not a contrived one. The whole point is that the rationale is discovered, not told.

The **"Why it matters" field** depends on which beat the step is:
- Naive-build steps: say what to build, and *withhold* the rationale (don't hint the naive way is wrong — that spoils the discovery).
- Rebuild steps: now give the full design rationale — the historical reason or technical tradeoff — because the pain just made it land. Pitch it so he learns the concept but still derives the implementation himself:
  - Too shallow: "Switch to an append-only log."
  - Right altitude: "Now that a second consumer needs the same messages, switch to an append-only log with per-consumer offsets. This is exactly why Kafka keeps messages instead of deleting on read: sequential writes stay fast and any number of consumers can replay from their own position. You felt the delete-on-read wall; this is the model that removes it."
  - Too deep: "Write a 4-byte length prefix + payload to a file and keep an offset→byte-position map."
- Steps that aren't part of a pain arc: a normal one-line rationale is fine.

Format:

```markdown
# <Project Name>

<One paragraph: what this is and what it teaches.>

## End condition
<The specific observable thing that means it's working — concrete enough to actually test.>

## Steps

### 1. <Step name>
**Goal:** <What the system does when this step is complete — an observable behavior/contract, never the language construct (struct/enum/match/HashMap/trait/Result) used to build it.>
**Why it matters:** <Per the beat: withhold rationale on naive-build steps, give full rationale on rebuild steps, one line otherwise. See the altitude guidance above.>
**Starting point:** <What's already in place from the previous step that this builds on. For step 1, the empty starting state.>
**Checkpoint:** <A concrete thing he can run or observe to confirm this step works. On a "feel the pain" step, the checkpoint is observing the naive approach break — that's the lesson, not a failure.>

**Read first:**
- [<title>](<url>) — <one line: what this covers and why it matters for this step>

### 2. <Step name>
...

## Stretch
- [ ] <Behavior that exercises a harder concept, with a link if applicable>
```

Each step's behavior is observable and completable on its own, and its checkpoint is testable in isolation. Order steps so each one's "Starting point" is the previous one's finished state — the chain should read like a build log. Within that order, the pain arcs (naive build → feel the pain → rebuild) are what the sequence is built around; lay out the steps so each arc's three beats land in order and the pain comes from a feature he'd want anyway. A step without a meaningful read can omit the "Read first" section — don't force a link where none is needed.

### 5. Confirm

Tell Oscar where the spec was written (`~/forge/<project>/SPEC.md`) and what the end condition is. One line each. Don't summarize the whole spec.
