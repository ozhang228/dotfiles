# Feedback Examples

Real comments from code reviews. For each: the verbatim comment, then the lesson.

---

"Does this mean we _need_ the new version of luna or just that we are compatible with it?"

Lesson: Ask whether something is a requirement or just compatible. Distinguishes blocking from optional dependency upgrades.

---

"Do we know if this has performance implications?"

Lesson: A short question that doesn't assume or accuse. Surfaces risk without asserting it exists.

---

"Did we consider just returning `Timestamped[DeskPortfolio]` from STS? otherwise, we will have an awkward time constructing `DeskPortfolio` from sources like tradio (or have to invent a fake timestamp)"

Lesson: When proposing an alternative, name the downstream consequence of NOT taking it. The alternative plus the pain it avoids is more persuasive than the alternative alone.

---

"I don't think this is a step in the right direction if we need to add two new TODOs (not counting the TODO about spot instruments) into the code. Can we resolve some of them here, or remove them if we don't think they're really necessary?"

Lesson: Name the concern (accumulating debt), make a concrete ask (resolve or remove), and scope the qualifier (not counting the spot one) — all in one sentence.

---

"This change is fine but do we anticipate making other things optional/more views? If so it may be cleaner to just group 'desk_optional_topics' and 'all_desk_topics' or something rather than make signal_ev specifically different"

Lesson: "Fine now, but..." framing for forward-compatibility concerns. Acknowledge the current correctness before raising the growth concern so you don't sound like you're blocking.

---

"I think we should hold a bigger discussion about this. This is not just a typescript problem — we need this in python dash apps as well. I think we should start with a spec wiki, and reach consensus before moving further with this"

Lesson: When a PR reveals a cross-cutting concern, propose a structured next step (spec wiki, wider discussion) rather than just blocking. Gives the author somewhere to go.

---

"can we lump this into #2361 and table this for now, or is this urgent?"

Lesson: Offer to defer rather than block. Asks the author to justify urgency before spending review time on something that could wait.

---

"N.B. I didn't review the code (i.e. `.cpp, .h` changes) under the statement that they were all deletes or just formats. If anything deserves attention, please let me know"

Lesson: Explicitly scope what you're NOT reviewing. The author should know which parts still need eyes.

---

"Logical-wise everything here mostly looks good to me 👍 with some key caveats — code needs to be split up a bit more — I agree with you that this doesn't fully achieve our goal of separating publishers… I'd like to agree on the end state there before proceeding with these intermediate changes"

Lesson: Separate logic approval from structural concerns. Naming both ("logic is fine, structure isn't") prevents the author from reading a positive signal as an unqualified approval.

---

"> Caltime is discretised based on dates, rather than continuous based on time till expiry

> this is really surprising and I'm curious why. code-wise I think this is a fine way to express it"

Lesson: Express genuine surprise at unexpected design. Saying "I'm curious why" invites explanation without blocking. It either surfaces a real problem or closes a knowledge gap for the reviewer.

---

"Please change the PR title, otherwise LGTM"

Lesson: Single small blocker as the only feedback signals the overall review is positive. Author knows the scope of what's needed.

---

"Fine change, think PR description could say why do this though?"

Lesson: Noting a gap in the PR description without blocking. Pushes for better context without treating it as a code issue.

---

"arguably the end state here is a different risk viewer from the desk one, analogous to how the empirical risk dashboard and the empirical risk management view are different apps. I think in an ideal world (with more dev work) we'd have a high-level overview for management that you can click to drill into the granular-level details"

Lesson: When asking for a rethink, articulate the ideal end state. "In an ideal world" is a useful softener that frames the vision without demanding it be done now.

---

"desk confirmed they want this?"

Lesson: Before approving a feature driven by a desk ask, verify the ask is actually confirmed. Prevents building things nobody asked for.

---

"What is the process to run e.g. crude or centerbook risk viewer locally now? How many processes need to run concurrently?"

Lesson: Ask about operational impact, not just code correctness. A change that makes local development significantly harder is worth flagging even if the code is correct.

---

"What are `products`/`expiries`? Can we use richer types and avoid symbology in this function?"

Lesson: Question vague collection names and string identifiers together. Rich domain types can clarify both what the values mean and which inputs are valid.

---

"Can we add some higher-level tests here too, like
- theo increases when YTE increases
- call/put delta is monotonic
- strikes/SDs round-trip

generally, exercising pricing calls against the skew model"

Lesson: Test domain invariants in addition to examples. Monotonicity and round trips cover broad behavior without coupling tests to implementation details.

---

"We should have a better constructor ex. `new` classmethod so we don't need to have private kwargs"

Lesson: If normal construction requires callers to know private fields, ask for a public constructor that owns those invariants.

---

"Can we put this on `SabrSwaptionSkew` so we aren't as exposed to the raw dictionary API?"

Lesson: Keep unstructured library representations behind the domain object that owns them. This reduces how much application code depends on a fragile raw API.

---

"Why are there two different implementations of `_is_shorter_tenor`?"

Lesson: Call out duplicated domain logic directly. Two implementations of the same rule can drift even when both look correct today.

---

"Is this mapping always what people want for each currency? If not, we should let callers pass this in"

Lesson: Separate universal rules from caller-specific policy. Ask whether a hardcoded mapping is truly invariant before moving it into configuration.

---

"Let's move this to luna/clients/sol so the data fetching isn't coupled with our domain"

Lesson: Place code according to ownership. Fetching belongs at the client boundary so domain logic does not become coupled to an external system.

---

"Sorry, I am blind. I am confused though why this is getting called in more than one place - can we tidy up the control flow so it looks something like

```py

def swaption_expiry(self, ...):
    if _is_shorter_tenor(tenor, SwaptionTenorCutoff, reference_dt):
        ...
    elif _is_shorter_tenor(tenor, ShortTenorSwaptionTenorCutoff, reference_dt):
        ...
    else:
        ...

```

Also, why do we compare against `ShortTenorSwaptionTenorCutoff` after `SwaptionTenorCutoff`? This is a complicated function that is basically doing refdata - how do we know it's correct?"

Lesson: Pair a concrete control-flow simplification with the deeper correctness question. For complicated reference-data logic, readable branching helps review but does not replace evidence that the rules are authoritative.

---

"as in, knowing that we're pushing more and more things into cpp (skew models included), we're effectively writing everything twice (in python, then convert to cpp with nanobinding, then optionally get rid of the python version for consistency). If that's the case, we can consider just go directly to the end state, circumventing the intermediate step to avoid duplicative work for anything that doesn't have migration risk.

But if we think this might still need some iterations / might not be stable / can benefit from python iteration speeds, I think this is fine in python for now. But once we start to move orchestration layer to cpp for apps in general (which is one of the primary reasons to move to cpp in the first place - python doesn't allow us to use more than 1 core, orchestration is hands-tied), we'll need this in cpp. We can do a mechanical port then"

Lesson: Evaluate an intermediate implementation against the known end state. Make the tradeoff explicit: avoid duplicate work when the design is stable, but preserve iteration speed when migration risk is still high.

---

"I think this \"stringly-typed\" logic (and what we do in one_day_length_metrics.py) is kind of brittle. Can we express this as a mapping of `ForwardYteKind` to `Yte`, where `ForwardYteKind` is an enum over VoltimeEOD Voltime24H etc.?"

Lesson: Do not stop at calling strings brittle. Propose the domain key, value type, and data structure that make invalid states harder to express.

---

"this is a breaking change for desk-tools, but I like this a lot more - do you have a sense yet of what the desk-tools changes will look like yet?"

Lesson: Acknowledge that an API improvement is directionally right while still requiring a concrete downstream migration story.

---

"Why `fill_null(0.0)` / if we don't have any nonzero values, don't we want it to be NaN (therefore show up as orange cell to the user)?"

Lesson: Challenge fallback values by tracing them to visible behavior. Zero and missing are different domain states, and the UI may rely on that distinction.

---

"I think this assumes that underlying prices are never actually zero which is not always true (ex. spread underlyings). Can we do something like `first_not_nan` and use nan as the nullish value?"

Lesson: Disprove a sentinel assumption with a real counterexample, then suggest a representation that preserves legitimate zero values.
