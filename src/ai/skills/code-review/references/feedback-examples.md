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

"verified locally that if I run all 4 publishers I can still see it on frontend… and it works [images]"

Lesson: Test locally and report back. A reviewer who runs the code is more credible and catches integration issues that pure code reading misses.

---

"I prefer writing out `cumberland`, but NBD either way"

Lesson: Label nits as nits before stating them. "NBD either way" tells the author to deprioritize without guessing whether a response is required.

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
