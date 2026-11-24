# Review Feedback

## Make feedback actionable

- Ask a specific question or propose a concrete change. Avoid observations that require no response.
- Distinguish a required dependency upgrade from compatibility with a newer version.
- Ask for performance evidence without assuming a regression exists.
- Explain the downstream consequence when proposing an alternative interface or data model.
- Resolve new TODOs that are necessary for the change to work; omit speculative follow-up work.
- Separate approval of the logic from concerns about structure, scope, or naming.
- State the scope of a small remaining blocker so the author knows what would resolve it.
- Ask the author to explain surprising domain behavior before treating it as a bug.
- Explain why a change is needed when reviewing the title and description.

## Verify the premise

- Confirm the intended user behavior before approving a feature.
- Distinguish universal invariants from caller-specific policy before hardcoding a mapping.
- Verify a fallback preserves missing values and legitimate zero values through calculation and display.
- Establish the downstream migration before approving a breaking API change.
- Review the local development and operational consequences, including any added processes or services.
- State which files or behaviors were not reviewed and why.
- Ask whether a nonessential change is urgent or can be deferred to an existing task.

## Explain architectural changes

- When a change reveals a shared problem, propose a scoped design discussion with the affected owners.
- Describe the desired end state when asking for a redesign, without requiring speculative work now.
- Keep fetching and transport at the client boundary rather than coupling them to domain logic.
- Replace vague collection names and string identifiers with meaningful domain types.
- Keep raw dictionaries and library representations behind the domain object that owns them.
- Give duplicated domain logic one owner so implementations cannot drift.
- Use a public constructor when normal construction otherwise requires knowledge of private fields.
- Pair a control-flow simplification with evidence that the underlying domain rules are correct.
- Evaluate an intermediate implementation against the known end state: avoid duplicate work for a stable design, but preserve iteration speed when migration risk remains.

## Request useful verification

- Test domain invariants alongside representative examples, with independently known expected values.
- Use a round-trip test only when intermediate values are also checked; matching bugs can cancel out.
- Ask for evidence of the user-visible result rather than inferring it from a transformation test.
