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
