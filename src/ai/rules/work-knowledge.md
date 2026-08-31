---
applies_to: Work under /home/ozhang/drw or tasks requiring DRW/FICC domain knowledge
skip_if: Work outside DRW repositories that does not require DRW/FICC domain knowledge
---

# Work Knowledge

Terminology, repo map, and durable DRW/FICC desk facts for Oscar's work. All repos live under `~/drw/`.

## Terminology

- **PIP** is ambiguous. Context decides whether it means "Pricing Inputs Publisher" or the `pricing-inputs` Kafka topic prefix.
- **RVUVS** = `rv-utils-viz-server`, a Dash-based rates/vol-surface visualization app. It depends on `rv-utils` for surface-building logic. Its deployed frontend config lives in `k8s`, not in `rv-utils-viz-server`.
- **EORV** = Energy Options RV.
- **ARS** = `apo-risk-service`.
- **OPDS** = `option-pricing-data-service`.
- **Luna** = the `research` repository
- **YARDS** = "yet another reference data system". Has many clients, the current one is luna refdata client, `luna.refdata.RefdataClient`.
- **SOL** = firmwide analytics library. Luna contains wrappers for sol which are generally preferred. For Sol API semantics and quantitative or business-context questions, consult Polaris before drawing conclusions or changing behavior. Ask it to separate documented facts, runtime evidence, and inference, then verify the repository's configured production path when that can differ from the general domain answer.
- **Box / unboxing**: RTR keys positions by `(trading group, clearing account, instrument)`. A box is a set of offsetting positions that is flat when aggregated but remains nonzero in individual RTR keys, often after an instrument expires. For example, one trading group can be long 10 expired CME August BTC futures while another is short 10. Unboxing is the middle-office process of moving the position between groups or accounts so the individual keys are flat, not merely the aggregate.

## PIP 

### Client Selection 

Use `PIPSource` when a caller needs an independent point snapshot or historical
range and does not need to retain live state between calls. It suits reports,
dashboards, polling jobs, and batch calculations that fetch data, compute a
result, and discard the source state. It can read recent Kafka data and older
EventStore/Delta data through `fio.streams.UnifiedReader`; lookback is relative
to the requested `asof`. It does not require startup, catch-up, warming, or a
particular call order.

Use `UnifiedPricingInputsClient` when a long-running process needs a continuously
maintained live table, update notifications, retained near-live history, or its
pricing-client interface across live and historical data. Start it and wait for
catch-up before trusting live results. Catch-up establishes live-state readiness;
it does not make historical DB data more complete.

## Deployments and K8s

In the k8s declarative deployment repo, overlays under `overlays/desk-tools-managed/` are generated. Source of truth lives in `desk_tools/applications/`; edit the Python app definition/config source and regenerate, instead of editing generated jsonnet directly. Desk-tools image bumps should land on the app's QA/dev branch for QA testing and also update prod when applicable. Each app has its own QA branch from the QA ArgoCD Application `targetRevision`. Do not assume a shared QA branch.

### Haruko Dropcopy (HDC)

HDC avoids implementing a different booking integration for every crypto
exchange. It polls Haruko's normalized trades and balance-adjustment APIs,
joins the events to NERD and Cumberland refdata, converts them to DRW's trade
format, and books them into TI through Hodor.

For a new account, configure one `replicas=1` instance per Haruko instrument
category used by the account, such as `SPOT`, `FUTURES` (perpetuals and dated
futures), and `OPTIONS`. Confirm the exact Haruko account name, TI clearing
account ID, desk and default trading-group IDs, NERD platform, and Haruko
balance-adjustment types. The Haruko numeric account ID is not part of the HDC
configuration. Never run two instances for the same account and instrument
category because their in-memory deduplication state is not shared.

To test a production Haruko account end to end without booking into production
TI, start from its production config and create a temporary, uncommitted local
config. Keep the production Haruko endpoint and credentials so HDC reads the
account's real events, but repoint the TI-side dependencies to mirror:

- `hodor_base_url`: `http://ti-dev/hodor-mirror`
- `nerd_base_url`: `http://ti-dev/nerd-mirror/api`
- `tradio_base_url`: `http://ti-dev/tradio-mirror`
- `ti_auth_vault_path`: `/ti/qa.haruko_dropcopy`

Hodor is the write boundary. NERD and Tradio are reads, but they must use the
matching mirror environment so conversion, initial deduplication, and
reconciliation agree with the mirror bookings. HDC has no dry-run mode, so this
test books every eligible event in the configured lookback window into mirror.
Run instrument categories individually, inspect the resulting mirror bookings,
and ask the relevant desk owner to confirm the clearing account, trading group,
product, fees, and source trade ID. For Cumberland Options, `@jquartey` is the
current validation contact.

For a brand-new account that has no positions or transactions yet, use the same
production-Haruko, mirror-TI configuration as a startup smoke test. Run each
configured instrument category long enough to initialize and poll its upstreams.
If every process stays running without startup, credential, refdata, or polling
errors, the wiring is ready to deploy. After deployment, ask the desk to book a
controlled test trade and verify that it reaches TI with the expected fields.
