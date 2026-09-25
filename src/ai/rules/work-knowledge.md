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

For a settle-to-settle current future return derived from option PIP rows,
match the canonical `underlying_products` to exactly one target future product.
Membership alone can select a multi-underlying spread: the CL/BZ `ABV` listing
`BYX2026` contained `(XNYM, CL)` in live PIP but lacked historical underlying
identity at the prior CL settlement. The older Metals dashboard classified
option listings through instrument specs; it rejected that spread and accepted
the nearer weekly CL listing `NL5U2026`, so restricting CL to monthly `LO`
also changes its selection. Keep the same listing for live and historical
prices, and surface missing-current-return errors while retaining stored RV.

For live Matrix Greeks dashboards, `select_option_listing_inputs` rejects
skews more than ten minutes older than Matrix publication by default.
`skew_forward_fill=True` is useful for counting omitted listings and their
skew ages; it can also admit days-old surfaces, so do not use it to price a
live heatmap without an explicit policy change. The gamma-efficiency cutover
showed 99 legacy listings, 98 fresh Matrix listings, and 107 Matrix listings
with forward fill in a near-time capture. Freeze the same inputs when checking
formula parity, and show excluded coverage and the freshness limit at the
dashboard boundary.
For the gamma-efficiency Plotly heatmaps, `hovertemplate` only controls hover
details; printed cell values require `texttemplate="%{z:.2f}"` and a readable
`textfont`. Moving precomputed charts into a Dash callback moves the initial
Matrix fetch and SOL pricing onto page load unless the default selection is
warmed in the background. Serve warmed figures and their matching snapshot
metadata and version in the initial Dash layout so the browser can render them
without waiting for a callback. Keep the empty-cache path able to load and let
the first callback fill it. Measure server work and browser rendering separately
when diagnosing a slower first view.

### BSKEW bid/ask statistic

`atm_mean_ba_spread` comes from `SingleSkewPricingData_WithVols` in ficcpp,
through data-utils' volatility ETL. It averages ask IV minus bid IV for eligible
two-sided strikes with absolute SD moneyness below 0.5, weighted by
`exp(-m*m/2)`, using the tightest eligible call/put IV quotes. Reproduction also
depends on its quote filters, approximate ATM moneyness and IV conventions.
Vol Manager's chart subscription exposes bid/ask IV separately; the checked
Coral/PIP skew schema does not carry this statistic. Live chart values cannot
replace historical observations for a daily volcube replay.

For volcube cutover checks, inspect the actual Delta file statistics and read an
epoch-bounded slice before assuming BSKEW covers a requested period. As of
2026-09-24, all eight monthly BSKEW input tables and all 40 saved volcube
output tables end on 2025-04-15; none contains rows for 2026-07-24 through
2026-09-23. The constant-maturity reader's 2021 source cutoff is a reader
policy, not the BSKEW ingestion end date. A recent PIP replay can prove new
runtime behavior, but it cannot establish direct numerical parity with absent
legacy rows. On 2025-04-15 the legacy `atm_mean_ba_spread` column was populated
for every inspected volcube row across the eight products, while historical
PIP does not supply that statistic.
The old scheduled writer overrides the library defaults with `max_t=0.8` for
daily and multiday PnL, and its persisted constant-maturity cubes include the
1-day tenor. For FX daily PnL it also stamps 18:00-19:30 rows using the first
quote after the 19:30 exclusion; a replacement driven only by observed start
timestamps drops seven labels per listing and session. Check the writer call
sites and stored row keys, not just the calculation function defaults.
The legacy 15-minute simulation grid also emits 17:00-17:45 reopening labels
on Sundays and holidays before a business day. It uses the first later eligible
quote for missing labels, and its final `groupby.sum` writes zero for a horizon
with no quote before its target. Replay row keys and null patterns on matched
inputs; counting only observed PIP timestamps misses both behaviors.
The archived `is_ffill` flag marks rows whose BSKEW surface or underlying
price failed quality filters and was forward-filled. A PIP skew-age flag does
not have the same meaning, even when both are stored under `is_ffill`.
Near expiry, SOL can return no implied strike for extreme attribution deltas:
the 2026-09-23 `4JYU2026` PIP skew returned NaN for 1% and 2% call deltas in
both scalar and vector inversion. The legacy attribution writer retains those
delta rows, and the saved schema permits null strike and initial Greeks. Keep
the row keys and make the unavailable pricing visible rather than failing the
whole product or silently dropping the deltas.

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

The vol-of-vol writer samples hourly fit rows and needs a valid 15:00 Chicago
fit for each listing's daily implied metrics. A fit can report `success=true`
while `bad_input_data=true`; the provider correctly excludes it. A valid 15:05
fit is also excluded by the hourly minute filter. When a daily partition is
empty, check `input_data_errors_string` and exact fit timestamps, then compare
realized rows with the implied-metric merge before its final `dropna()`.
If using a later fit for a scoped repair, preserve its actual timestamp and
verify complete row keys and numeric values before writing.

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
The total-open-interest heatmap includes options whose last-trade date is the
current Chicago date. The old RD API supplied a datetime and compared it with
today at midnight; Luna supplies a date, so use an inclusive date boundary.
Compare rendered expiry/strike bins with the old view as well as raw settle
identities: equal row counts and strikes do not prove the displayed totals.

## Intraday futures trade writers

`uds_legacy.fut_trades_{product}` and
`uds_legacy.metals_options_lead_future_screen_trade_data_{product}` are physical
Delta tables whose `epoch` column is UTC nanoseconds as `int64`; derive their
`_month` partition from that UTC epoch. Their catalog metadata lacks
`generated_partition`, so use `DeltaClient.merge_data` with the existing keys
instead of `get_delta_resource`. The preliminary ten-second futures bars use
`px_exchange_best_implied` and `qty_exchange_best_implied` for fallback quotes;
the standard ten-second bars use `px_implied` and `qty_implied`.

Blockworm's short symbol year digit is ambiguous: resolve the full listed year
from a historical YARDS future snapshot before querying bars. Tickster can
publish several fills with the same trade ID and timestamp but different
prices. The old screen writer sorts on timestamp alone and selects its `last`
price, so equal-timestamp order can change the stored price. Compare keyed
quantity and venue fields separately from price, inspect the fill sequence for
price differences, and settle an explicit price rule before a writer cutover.
The futures table's merge key includes `epoch`. When later fills move an
aggregate's final epoch, a merge inserts the new key but leaves the earlier
aggregate behind. For stored-only rows, match symbol, trade ID, resting flag,
and type against the candidate before treating them as missing source trades;
remove only exact verified stale keys after the current aggregate is present.

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

During the RV writer cutover, inspect Delta commit provenance as well as the
latest rows. The DED writer commits with `app=write-metals-rv-data` once per
product and table; the archived external writer uses `app=datahub` and makes
six RV plus four hedge merges per product. Compare table versions immediately
after the DED run and after later commits: the older writer can change past RV
values and add hedge keys even when the latest session still matches.

For App Launcher impact checks, RV Forecast Cross Product Viz is served by a
separate Research service. Its production config reads each product's UDS
`/realized_var_forecasts/settle_settle/auto_baseline/{MIC}/FUT/{product}`
`voltime_prompt` field and a sibling `5_day` path; its trailing realized values
come from settle-price bars. Do not equate those forecast datasets with Metals
`metals_options_realized_vol_data` or `metals_options_hedging_data` merely
because both are labeled RV.

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
STS also exposes positions it cannot tag with refdata. Merge those by the full
RDS ID, trading group, trading desk, and clearing account key; one RDS ID can
span accounts. Resolve their instrument kind through structured refdata where
possible, and make any unresolved population visible at the report boundary.
The archived report rewrites `VolPathSlope` before Sol repricing near expiry,
while Matrix prices the PIP skew. A matching price does not establish matching
adjusted delta or candidate membership; compare both against the 0.995 delta
and product tick thresholds on frozen, same-time inputs.
For a same-input early-exercise replay, query the archived SOD UDS window and
select its earliest epoch in the 61 minutes before previous close, as the old
loader does. SOD `yte < 1/252` sets the listing's manual multiplier to zero;
the live path applies that multiplier times its calculated ATM slope only when
live `yte <= 1/252`. Matrix clips Sol delta to `[0, 1]` for calls and
`[-1, 0]` for puts. Compare candidate membership and numeric price/delta
separately. This replay uses common frozen Matrix inputs; full old-job parity
also needs opening holdings and a synchronized EdgeServer snapshot.

## Deployments and K8s

In the k8s declarative deployment repo, overlays under `overlays/desk-tools-managed/` are generated. Source of truth lives in `desk_tools/applications/`; edit the Python app definition/config source and regenerate, instead of editing generated jsonnet directly. Desk-tools image bumps should land on the app's QA/dev branch for QA testing and also update prod when applicable. Each app has its own QA branch from the QA ArgoCD Application `targetRevision`. Do not assume a shared QA branch.

### Kafka retention during incident replay

Before computing historical rates with `offsets_for_times`, compare the requested start with the timestamp of the first retained record in every partition. Once retention advances past that start, the lookup can return the current low offset and make expired minutes appear empty instead of failing. Pin broker evidence while it is retained; use EventStore for older windows and check its offload coverage before treating recent archived counts as complete.

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
