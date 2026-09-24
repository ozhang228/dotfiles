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

### Snapshot timestamps

A historical PIP snapshot label precedes entry assembly. A price or skew can
arrive after the labelled second, including in the next second, before
`entry_assembled_at_ns`. Validate source timestamps against entry assembly,
and check assembly lag separately. A fresh snapshot label does not prove the
skew itself is fresh; use its own timestamp.

### BSKEW bid/ask statistic

`atm_mean_ba_spread` comes from `SingleSkewPricingData_WithVols` in ficcpp,
through data-utils' volatility ETL. It averages ask IV minus bid IV for eligible
two-sided strikes with absolute SD moneyness below 0.5, weighted by
`exp(-m*m/2)`, using the tightest eligible call/put IV quotes. Reproduction also
depends on its quote filters, approximate ATM moneyness and IV conventions.
Vol Manager's chart subscription exposes bid/ask IV separately; the checked
Coral/PIP skew schema does not carry this statistic. Live chart values cannot
replace historical observations for a daily volcube replay.

### QA configuration

Check `ALP_CONFIG_DIR` before changing PIP's Alp config: a mounted JSON file
overrides the Alp API. The `data-pip-qa` branch in `k8s` owns the mounted
`overlays/pricing_inputs_publisher/qa/pip-deployments/fx-metals/config/pricing_inputs_publisher.json`.
Render that instance to verify the generated ConfigMap, deployment mount, and
Kafka destinations. The separate `fx-metals-fpp` canary has its own config.

## Historical skew identities

`data_gold.research_intraday_skew_fit_results` stores Coral listing IDs.
Matrix's `/greeks` and `/refdata` do not expose that join key. Resolve it through
Luna YARDS `coral_listing_id`, using structured `listed_year`, `listed_month`,
and `last_trade_time_ns`. For listings expired by the end of a history window,
query refdata at an actual observation timestamp. Platinum's fit-table option
product is `PO`; its desk and underlying product are `PL`.

For monthly fit history, resolve the future by NERD product and select its option
family through `future_product_entity_id` and `contract_expiration_interval ==
"MONTHLY"`. Require one matching family, then read its venue and exchange symbols
from YARDS. Keep the job's enabled-product list separate from those reference facts.
Use YARDS' keyed `try_get_future_product_by_nerd_product_symbol` and
`try_get_venue_by_entity_id` lookups rather than scanning snapshots for those
entities. `get_future_option_listings_by_option_product_entity_id` scopes listing
retrieval to the resolved option family. The current Luna client accepts `Instant`
directly in `query_snapshot`.

Do not reconstruct expiry from floating-point fit year fractions and then round
up to a time bucket. The legacy vol-of-vol writer's `yte * 365` reconstruction
had nanosecond error that `.ceil("5min")` amplified into a five-minute shift.
Use YARDS `last_trade_time_ns`. For migration parity, compare year-fraction
endpoints as well as the formulas; equal formulas can produce different output
when the endpoints change.

## Historical Metals open interest identities

`uds_legacy.settles_daily_xcec_fopt_og` carries option `usym` IDs. Matrix
`/refdata` provides option fields but uses different instrument IDs and holds a
current template, so it cannot resolve every contract in a historical settle
window. Resolve each settle `usym` through Luna YARDS
`try_get_future_option_outright_by_usym`, then use the outright's listing and
product entity IDs for strike, payoff, listed month and year, product exchange
symbol, and last trade date. Query refdata at a settle date for IDs missing from
the current snapshot; current snapshots exclude recently expired options. Keep
every settle row or fail on unresolved IDs rather than silently inner joining.

## Historical volatility partitions

Historical Metals constant-maturity volatility rows can have null `_month`
partitions. UDS epoch slices add month pruning and omit those rows, even when
the direct Delta read sees them. For writer/reader migrations, compare raw
epoch-bounded rows with the UDS slice before claiming parity. Preserve units
and previous-observation shifts while restoring available dates; do not carry
the UDS month predicate into a direct ATM-history reader. September 17, 18 and
21, 2026 exhibited this for all eight RV-writer products.

Historical RV replay must retain the full input history and filter the output
window afterward: 30-minute sampling is anchored to the first input price.
Pivot triggers use a strict absolute-price tolerance. Backward price
reconstruction from a later endpoint can change historical prices by a few
floating-point ULPs without changing historical returns, flipping samples
exactly at that tolerance. Freeze the prepared inputs for calculation parity;
compare stored rows separately, including stored-only hedge events retained
by upserts. A stable boundary convention is a behavior change, not a rename.

For RV cutover materiality, run restored rows through the actual 10-/20-observation
reader and compare hedge schedules after each attribution reader's minute rounding
and session exclusions. Additional valid dates can materially change SD RV and
attribution even with exact same-input formula parity. Reconcile stale event keys
separately; an upsert does not replace a recalculated schedule.

For a bounded Delta schedule repair, rehearse a single scoped merge that inserts
desired events and deletes source-missing target events. Preserve before/desired
snapshots, guard the table versions before writing, and verify the full table
against its pre-repair version plus the approved replacement rows. Do not use a
whole-partition overwrite when the approved scope is narrower than that partition.

## PnL expiration

Delta and PnL Scalloper cache their historical close snapshots in memory.
After repairing historical Greeks, restart an already-running process to load
the repair. Verify the exact epoch selected by each historical provider: the
close lookup can select the earliest snapshot in its lookback window, so
repairing only the snapshot nearest the close can leave the reader unchanged.

An option bought intraday can expire without an opening position. Preserve the
legacy scalloper's expiration trade transfers, but calculate opening hedge
crossings only for trades matching its expiring opening-risk universe. Inventing
zero-opening rows changes book attribution even when total PnL is unchanged.
Compare actual legacy position preparation and trade transfers on frozen inputs;
matching valuation formulas on already-prepared rows does not prove book parity.

For scalloper snapshot comparisons, published `delta_pnl` excludes
`fut_spread_pnl`. Add them before inferring a contract's underlying move from
its previous-close Delta. Gamma PnL uses that contract move with the
previous-close skew, time and rates; a product's displayed front price alone
does not reconstruct deferred-contract gamma. Validate instrument sums against
aggregate reports before comparing separately published keys.

For EOD PnL, `TradingCalendar.settle_date` advances at the close, before the
next session opens. Keep reading the close feed during the daily break;
switch same-day reruns to dated final snapshots at
`calendar.open_time.strictly_next.get_for_ts(close)`. Calendar-date equality
alone permits next-session data after reopening, while using settlement-date
inequality selects snapshots before the scheduled final publisher creates them.

## Metals email jobs

Keep active Metals email modules under `fio/metals_options/email/` and update any
external shell launcher when moving one. Use Desk Tools `Email` with an HTML
`EmailMessage`; a string body is sent as plain text. Verify a new report with
`StubEmailClient` before SMTP. For a requested live test, temporarily hardcode
Oscar as the sole recipient, verify that To, Cc, and Bcc contain no desk
recipients, and remove the override after testing. Label the subject as a test.
SMTP success proves relay acceptance, not delivery to Oscar's inbox.

The early exercise job uses current positions. STS supplies instrument entity
IDs; keep them through aggregation and reject one symbol mapped to different
IDs before joining Matrix's structured `is_option` rows. Matrix's option
`listing_entity_id` is a different identity from STS's option entity ID.

## Deployments and K8s

In the k8s declarative deployment repo, overlays under `overlays/desk-tools-managed/` are generated. Source of truth lives in `desk_tools/applications/`; edit the Python app definition/config source and regenerate, instead of editing generated jsonnet directly. Desk-tools image bumps should land on the app's QA/dev branch for QA testing and also update prod when applicable. Each app has its own QA branch from the QA ArgoCD Application `targetRevision`. Do not assume a shared QA branch.

### RTR frontend readiness

RTR Breakdown can stay on `Loading...` when `/api/breakdown` fails; the loader
logs errors without setting an error state. Check frontend HTTP status codes
and publisher startup separately from Trade Aggregator health. The HTTP
publisher starts its web server only after Kafka initialization, which waits
for the first snapshot within five seconds. Check the `atomized-full-kafka`
and `full-summary` calculators when publisher initialization fails.

### RTR QA cashflow reference data

Cumberland Reference Data QA reads NERD mirror; RTR QA reads that Cumberland QA
instance. The reference-data loader inserts cashflows only when their numeric
NERD `id` is absent. If NERD mirror presents a different RDSID under an ID
already stored in QA, later cron runs skip it indefinitely. Compare the
unfiltered NERD mirror and Cumberland QA `/cash_flows` lists by both `id` and
`rds_id`. Avoid `/cash_flows?rds_id=...` for read-only triage: a miss triggers
an insert from NERD. RTR trade-aggregator logs and skips an intraday cashflow
trade whose RDSID lacks a mapping; repair refdata before republishing or
rebuilding the trade stream.

### Futures mapping into Liquidation Monitor

For a Basis Model instrument missing market data, first check its exact ticker
in Select and record `sourceTicker` and destination. Then check that ticker in
Liquidation Monitor. If absent there, search Slack (including bot messages) for
the source symbol and "inferred", or the warning "Cumberland symbols with zero
positions were inferred from Haruko static data". An explicit source/output
pair in that warning identifies the refdata fallback; absence in a bounded Kafka
tail alone does not. Repair the missing mapping and verify Liquidation Monitor
and Basis Model readback. Reusable checks and the NIL example live in
`~/anvil/utils/liquidation_monitor.py` and
`~/anvil/postmortems/2026_09_24-basis_model_missing_market_data.md`.

Cumberland `/futures` lists exclude ignored rows even with `include-partial` and
`include-unmodeled`; a direct `?rds_id=<UUID>` lookup can reveal the hidden row.
Compare its numeric NERD ID, RDS ID, RCI symbol, and future product with live
NERD before applying a mapping. The futures loader inserts only IDs absent from
its database, and the manual futures override updates mapping fields only. A
stale row whose RCI identity changed needs reconciliation before a mapping
override. Liquidation Monitor looks up futures by Haruko's exchange symbol and
Cumberland destination, then infers a ticker from Haruko assets on a miss.

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
