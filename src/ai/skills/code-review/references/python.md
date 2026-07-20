---
name: python-review
description: Python-specific code review standards for desk-tools and related FIO Python repos. Load for code review whenever the PR touches Python code. Covers idiomatic Python, constructor discipline, logging, config hygiene, and a pre-submit checklist. Distilled from real reviewer comments by pnickols, alchen, ajyang, abedra, opyper, thoueland.
---

# Python Review

Use this alongside the `code-review` skill for any Python PR. These are the patterns reviewers in this codebase flag consistently.

---

## Comments and docstrings — minimal by default

> "Comments should either fully describe what we're doing or link out to something that does. Don't appeal to authority" (abedra)
> "We're trying to move towards fewer explanatory comments, and instead reflecting the functionality through clearer code" (prawat)
> "The `Args` and `Returns` docstrings here are redundant with the type signature… comments can't be typechecked" (ajyang)

Default: no docstrings, no comments. Exceptions:

- Public-facing API with non-obvious domain terminology
- Load-bearing _why_: a workaround, a hidden invariant, a unit clarification

If tempted to write a comment, first ask: would a better name do the job?

---

## Idiomatic Python

> "Self?" (pnickols) — use `Self` not the class name
> "Isn't pop more idiomatic?" (pnickols) — use `dict.pop`
> "`expiry_to_listings.setdefault(expiry, set()).add(listing)`" (opyper)
> "You can get rid of the `set` call if you use `<=`" (pnickols)

Recurring nits: `Self` over class name, `dict.pop`, `dict.setdefault`, set-on-views (`d.keys() - other.keys()`), `<=` for subset, `removeprefix`/`removesuffix`.

---

## `zip(..., strict=True)`

> "strict zip" (alchen)
> "TIL about zipping with `strict=True`, we should start doing this everywhere where possible" (ajyang)

Default `zip` truncates silently. Always `strict=True` unless you explicitly want truncation and you know it.

---

## Parenthesize boolean / bitwise expressions when mixing

> "Parens please: `all_errors |= (source_errors | target_errors)`" (pnickols)
> "Brackets please, I am not even 100% sure I am right about which way round precedence happens between `not` and `and`" (pnickols)

If a reviewer can't tell precedence at a glance, parenthesize. Don't rely on `not`/`and`/`or`/`|` interaction being obvious.

---

## No truthy checks on `int | None` or `str | None`

> "Can we just be explicit with `is None` or `==`" (pnickols)
> "Is 0 being falsy fine?" (pnickols)

`if x:` on `int | None` silently treats `0` as falsy. Use `if x is None` / `if x is not None`.

---

## Config hygiene

URLs, hostnames, vault paths, port numbers belong in a Pydantic config model loaded from JSON — not in `main.py` branches or as default arguments. Hardcoded prod defaults are a foot-cannon; default to `qa` or no default at all.

> "Unless this is safe to rerun, I'd prefer not having prod as the default" (pnickols)

---

## Constructors, lifecycle, dependency injection

> "Don't do effectful things in the constructor; constructors should be pure to keep behavior predictable and to allow proper instantiation in tests" (ajyang)
> "We generally try to avoid expensive operations in constructors, and instead have a constructor which takes any necessary bootstrapped state and expose a classmethod or static function which does the convenient part" (ajyang)
> "This should be put into an explicit `start` method; it's better practice to avoid spawning threads/processes inside of a (pseudo)constructor" (ajyang)

Anti-pattern signals in `__init__`:

- Calls a network/DB client
- Reads from disk
- Spawns a thread
- Calls `time.now()` / records a timestamp

Pattern: `__init__` only stores fields; `from_config` / `from_*` classmethod for bootstrapping; `start()`/`stop()` (or `__enter__`/`__exit__`) for side-effecting lifecycle.

### Inject clocks; never call `now()` in domain code or tests

> "Unit tests are ideally hermetic, so we shouldn't call effectful functions like `datetime.now` in them" (ajyang)
> "We shouldn't have a `time.sleep` call in a test" (ajyang)
> "Inject clock interface" (alchen)
> "Do we wanna inject a clock?" (pnickols)

Pass a `Clock: Callable[[], Instant]`. Tests get a deterministic fake; prod gets `datetime.now`.

---

## Logging

### Pick levels deliberately

> "Is warning the appropriate level here? This seems quite bad/weird, rather than just unusual?" (pnickols)
> "Given it's only going to get logged once at startup, this seems like it should be info-level" (pnickols)

Startup identity → INFO. Per-event happy path → DEBUG. Recoverable but worth noting → WARNING. Real problem → ERROR.

### Don't log + raise the same string

> "Looks weird to me that this is the exception string and the debug log line. If they're always coupled, do you need both?" (opyper)
> "Why log here if it's essentially passed on as-is and caller needs to deal with the error condition anyway" (thoueland)

### Bound log-line size

> "As a rule I prefer bounding log-lines that otherwise look unbounded" (pnickols)

Don't log entire dataframes, lists, or scenario grids. Truncate.

### Add context

> "WDYT about logging requests (handler, username, query params, and ok/missing-params outcome)?" (thoueland)
> "Please log in a more explicit way to distinguish between the early return and not for debugging sake (ideally log the ids too)" (pnickols)

### Use `timed_block` / `Histogram`, not bare `time.time()`

> "We can use `timed_block` defined in `time.py` for this purpose" (alchen)
> "Histogram probably more informative here" (alchen)

### `from fio import logging` — only in `main.py`

> "Shouldn't this be default logging not `fio.logging` since it's not a main?" (pnickols)

`from fio import logging` sets up the root formatter. It belongs only in an app's `main.py`.

---

## PR-level signals

### Split unfocused PRs

> "Please leave just the vectorisation change which gives the speedup and not renaming" (pnickols)
> "This change will need to be broken into multiple PRs" (pnickols)
> "Would prefer a formatting PR separately if the PR is already hundreds of lines" (pnickols)

Renames, formatting, "while I'm here" cleanups → separate PRs. The diff for the actual change should be visually scannable.

### New code in `unstable/` until proven

> "This should probably be in unstable until it's properly tested" (prawat)

Large unproven additions go to `unstable/`. `quarantine/` is for legacy code we can't yet remove.

---

## What NOT to over-flag

These appear in the codebase already; don't gate on them unless egregious:

- Trailing-comma style on tight diffs
- `dict[K, V]` vs `Mapping[K, V]` for return types of private helpers
- Single-letter loop variables in 3-line comprehensions with nothing to gain from a longer name
- `f"..."` vs `.format()` (always `f"..."`, but rarely worth a comment)
- "This could be a one-liner" — only if the one-liner is genuinely clearer
- Extracting a helper used exactly once — inline is fine

Mark everything else `nit:` and non-blocking. Before adding a nit, ask: "would this change make the code better in 6 months, or is this a personal preference?"

---

## Pre-submit checklist

Before approving or submitting:

- [ ] No `try/except: pass` — every fallible path either returns an error type or raises
- [ ] Errors carry breadcrumbs (operation name + parameters)
- [ ] No magic numbers — literals in business logic have named constants with units in the name
- [ ] No `Any`, `cast`, `# type: ignore` without an explanatory comment
- [ ] No effectful work in `__init__` (no I/O, no threads, no clock reads)
- [ ] No `assert` outside tests (except `assert_never`)
- [ ] No `pytest.fixture`, no mocks, no test classes
- [ ] Test files mirror source (`apps/foo/bar.py` ↔ `tests/apps/foo/test_bar.py`)
- [ ] No `utils.py` / `core.py` / `helpers.py` / `shared_*.py` modules
- [ ] No abbreviations in identifiers (`oid`, `ltt_res`, `q`, `t`)
- [ ] No `from fio import logging` outside `main.py`
- [ ] No hardcoded refdata, env strings, or vault paths
- [ ] PR is one concern — no piggybacked renames/formatting/refactors
- [ ] Tests cover new branches and edge cases, not just the happy path
- [ ] Imports are absolute
- [ ] `zip` uses `strict=True` where lengths must match
- [ ] `make fmt && make check && make test` passes (run from `python/`, not repo root)
