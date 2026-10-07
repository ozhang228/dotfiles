---
applies_to: Work under /home/ozhang/drw or tasks requiring DRW/FICC domain knowledge
skip_if: Work outside DRW repositories that does not require DRW/FICC domain knowledge
---

# Work Knowledge

Terminology, repo map, and durable DRW/FICC desk facts for Oscar's work. All repos live under `~/drw/`.

## Maintaining this file

Apply the Durable Knowledge rules in `~/dotfiles/src/ai/GLOBAL.md`. Keep current,
verified facts useful across future tasks; update the relevant section rather
than appending task recaps. Omit incident timelines, snapshot counts, validation
logs, and completed retirement details. Document the supported approach after a
deprecation, retaining old details only for an explicit active compatibility or
rollback requirement.

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

### GLD inputs for Matrix Greeks

A read-only check on 2026-09-30 found zero GLD rows in live `fx-metals`,
`equity-indices`, and CHIP-enabled `eito` PIP snapshots. GLD's dedicated stack
uses MDN `prod-chipx-metals`, trading VM `prod-ficc-metals-equity`, reference VM
`prod-ficc-metals-equity-ref`, rates `prod-ficc-metals-equity`, and Event Horizon
`prod-ficc-metals-equities`. Both VMs returned 29 structured expiry terms;
a sampled approved valuation supplied an equity model, SOL skew, pricing YTE,
rates, carry, and Andersen analytics. Reuse Luna's Coral decoders; the older
FEJ `Pricer` does not support that equity model. The inspected VM/Mini configs
set `kafka.enabled=false`. Recheck live coverage before assuming this persists.

MDN supplies GLD equity and option refdata with structured strike, payoff,
expiry, underlying links, and 100-share option point value. VM's `product_listings_info`
subscription provides a separate underlying price; `get_last_fit_time` supplies
approved pricing metadata's creation time. Book-event timestamp semantics remain
unverified. The vol-path reference price is not proof of fresh spot, and
`calendarYteNotForPricingDirectly=-1` is a sentinel. Keep GLD source
access and normalization in one provider so a future upstream replacement
does not spread transport or source-specific parsing through Matrix. Evidence:
`~/anvil/notebooks/matrix_greeks_gld_inputs.py`.

PIP's current Coral adapter consumes Kafka, not VM WebSockets. Its existing skew
processor decoded a saved live GLD equity valuation without errors. The real
reducer/serializer at `7653070` composed that skew with synthetic canonical
refdata and price, preserving independent timestamps; a mismatched underlying
left price unavailable. This is local composition proof, not production coverage.
Current listing joins use expiration, despite the legacy `last_trade_time_ms`
wire name. Onboarding
still needs approved GLD Kafka publication, canonical equity refdata, and an
underlying-price mapping: the main YARDS endpoint used by PIP returned no GLD,
and its current index-underlying adapter routes through crypto spot pairs with a
Deribit MIC. Live broker metadata listed no Metals-equity skew topic. Complete
two-minute reads found no GLD in the `ficc-metals` and `metalsauto` Coral feeds
or `nms.chipx` book snapshots (1,534 distinct symbols). These bounded checks are
not broker-wide absence proof. `eito`'s CHIP config alone cannot supply GLD.
Matrix's futures-only template also needs an equity path;
adding GLD to PIP alone does not make Matrix emit its contracts.

PIP is not architecturally bound to YARDS: `resolve_refdata_generators` uses
legacy OPDS/instrument-service modules when `yards_client_env` is unset.
That branch is not verified GLD support; the skew processor still requires
a canonical underlying mapping. David Adeboye's September 25 update reports
actual-equity engineering/modeling work in PIP handled by Ian Adam:
https://drw.enterprise.slack.com/archives/C04FTV54EJZ/p1790350384189419.
Distinguish decoding and reducer composition from production equity readiness.

Saved September 30 GLD MDN/VM snapshots aligned all 29 expiration instants
to exactly one trading-VM term. All 7,868 MDN options resolve to the one
GLD equity, with no duplicate MDN IDs. These source IDs are not YARDS entity
IDs; position joins may need separately verified NERD/RDS mappings. The
inspected MDN Option schema exposes expiration but no distinct last-trade
time. Do not equate those timestamps or NMS with a booking venue by inference.

The local contained GLD provider and Matrix integration were verified on
September 30: 7,868 MDN options, 29 approved VM terms, and 7,344 eligible
options plus the share in Arrow, all model-valid. Matrix's existing two-year
pricing window excludes longer terms from `/greeks`, while `/refdata` keeps
the full chain. Same-input regressions match Luna's standalone American
pricer for price, delta, gamma, vega, and theta. GLD uses the actual MDN
exchange symbols and numeric IDs; these are not canonical RCI/YARDS position
identities. YARDS IDs, distinct last-trade times, EH voltime and CME B252
caltime stay null. Stock point value is one per share; the observed options
have MDN point value 100. VM spot has no source timestamp, so the observation
time and approved skew fit time must remain separate. Arrow's existing
microsecond skew timestamp explicitly floors the provider's nanosecond fit.
VM batch requests execute sequentially in the inspected Java API handler;
bracket approved valuation reads with equal last-fit timestamps and validate
response IDs. These were local checks, not a production deployment.

### GLD in the new Koi Risk app

GLD holding coverage can still flicker when STS introduces a new unsupported
RDS identity, even after previously verified identities are cached. October 2
sampling saw two new non-equity identities classify in 28ms, but the cache
returned pending immediately. Reuse same-date refdata and let the background
refresh wait up to 100ms outside its lock for the matching request. Slow or
unknown holdings still fail visibly. The reducer regression pins 10 shares
delta while a new non-equity RDS lookup completes with refdata offline.
Evidence: `~/anvil/notebooks/koi_risk_gld_holding_error.py`.

The local September 30 implementation targets `dashboard/koi_risk/dashboard_risk.py`.
Keep MDN/VM/NERD translation in `data_access/equity_options.py`; Koi reads Matrix.
NERD's structured `external_symbol` matches MDN's OCC symbol, allowing verified
RCI translation without parsing symbols. A saved 7,344-option snapshot mapped
7,000 options; 344 had no NERD booking record. Preserve their exchange identity.
GLD price/scenario units are USD/share, delta is shares, and PnL is USD.
The equity calculator preserves approved VM vol-path and Andersen parameters;
it does not refit the commodity vol-path. Matrix exposes serialized Luna
`american_analytics_params` as an additive Arrow field. GLD inclusion is opt-in
with `--include-gld`. Koi local flags are `--matrix-url`, `--port`, and `--read-only`.
GLD is excluded from the established Metals OPXL publication contract.
No GLD trading-calendar mapping was found; close-based theta and DTE lean
remain unavailable, and PIP historical overrides cannot serve GLD. Later live
startup returned `No Data` for approved `GLDV2026_1` pricing, despite an earlier
successful read. October 1 fixes preserve typed GLD availability and cached
refdata, publish `product:GLD:error`, and retain healthy metals rows when GLD
pricing fails. Matrix and Koi expire GLD observations after two minutes;
approved skew fit age is distinct. Missing holdings use Matrix refdata with
matching trading dates, and unsupported STS holdings remain visible to coverage
checks. The read-only app on port 3011 uses local Matrix on 3010; the labelled
saved/synthetic preview is on 3013 with a frozen clock. Live VM later returned
`No Data` for `GLDH2027_19`. `lxml` is needed by Koi's existing attribution
HTML reader and is declared for uv and Conda. The full recipe passed 961 tests.
Local saved UI verification does not establish live GLD readiness. No push or
deployment occurred.

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

`PIPSource.stream_snapshots` bulk history materializes all selected snapshots
before yielding. For sparse event replays, push exact target seconds into a
`PIPSnapshotFilter.to_delta_expression` and apply the same test in
`accepts_snapshot`; filtering only after iteration still decodes the full minute
grid. A five-day CU attribution replay improved from 267 seconds and 6.8 GiB
peak RSS to 219 seconds and 4.1 GiB after target-time filtering.

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

The Metals vol-path publisher writes four OPXL tables rooted at `fd_metals_vp`
in PROD, `qa_fd_metals_vp` in QA, and `local_fd_metals_vp` locally. Its `ENV`
selects the prefix through `opxl_key_prefix`. The RV/IV/PnL dashboard reads the
matching environment root through `VolPathProvider` without a legacy fallback.
Populate and read back the new key before the dashboard starts; it loads VP
data during startup. Koi Risk calculates its own vol path from option data.
`MetalsPIPClient.get_snapshot_history` supports a bounded range, listings,
snapshot interval, and configurable stream sample frequency. The VP publisher
uses one-minute PIP history with a five-minute filter. An immediate OPXL
`get_df` after `publish_df` can still return the previous table, so wait for
the intended epoch and row keys before comparing or cutting over.
The old OPXL DataFrame helper includes an unnamed index column, read back as
`None`; `OpxlClient.publish_df` only sends explicit columns, so materialize
that column when preserving the wire shape. The fitted history assigns a new
trading-date bucket at 15:00 Chicago by evaluating the date at timestamp plus
two hours. Compare summary rows by `(listing, horizon)` and raw rows by
`(listing, timestamp)`; the synthetic row ordinal can change with listing order.

For the gamma-efficiency Plotly heatmaps, `hovertemplate` only controls hover
details; printed cell values require `texttemplate="%{z:.2f}"` and a readable
`textfont`. Moving precomputed charts into a Dash callback moves the initial
Matrix fetch and SOL pricing onto page load unless the default selection is
warmed in the background. Serve warmed figures and their matching snapshot
metadata and version in the initial Dash layout so the browser can render them
without waiting for a callback. Keep the empty-cache path able to load and let
the first callback fill it. Measure server work and browser rendering separately
when diagnosing a slower first view.

For a Dash dashboard that caches live data in the server process, fetching
the layout does not itself refresh that cache. If the polling callback has
`prevent_initial_call=True`, it waits for the first timer tick before fetching
live data. Have charts depend on the completed refresh output so they redraw
when the new snapshot arrives, rather than waiting for an independent timer.
Check the browser callback request and source timestamp separately when a
reported delay is longer than the configured timers.
After changing Dash callback output IDs, an already-open tab keeps the old
callback graph and can receive HTTP 500 for its old callback request. Reload
the tab before validating the new behavior; an aggregate 5xx count alone
cannot attribute the failure to that tab.

For DED jobs using `TradingCalendars.load()`, inspect the installed library's
connection path before claiming mounted-credential startup works. Calendar
167 calls Vault even when DED mounted the trading-hours secret. The local
calendar branch `mounted-calendar-credentials` adds mount-first handling in
`DatabaseConnection`, keeping the public loader unchanged. Release that change
before removing Metals' adapter; the follow-on worktree is
`~/drw/metals-options-gamma-theta-calendar-loader`. Verify deployed startup
with Vault disabled; a successful local query exercises different authentication.

## Edge Server metadata

`EdgeServerMetadataClient.subscribe` replaces its subscription. Pass all needed
tool scopes and exchange symbols together, then poll once; separate subscriptions
repeat Redis reads. `poll().entries` contains FlatBuffers: use
`entry.key.toolScope` and `entry.key.exchangeSymbol`, then
`entry.value.EdgeResult().BidEdges(i).Edge()` and `.MaxSize()` (and the matching
ask methods). Its `to_pandas()` shape is not the per-contract API.

Matrix Greeks supplies live option exchange symbols, delta, strike, point value,
and underlying identity for the Edge Monitor. For historical Edge Monitor
panels, use read-only `luna.toad.ToadClient` with
`ToadQueryBuilder`: add base trades with quote info, leg data, PnL markouts,
and opportunity before aggregating. PnL markouts require leg data in the
installed Luna client. `FILL_INFO` can split one event across rows, so sum
edge and quantity by `event_uuid` before ranking top trades. In DED, mount the
desk's `kv/clickhouse/prod/toad-clickhouse-ro-*` secret and pass its password
to `ToadClient`; the deployed process should not need Vault authentication.

For Edge Monitor ad hoc legs, YARDS `security_id` is the numeric exchange
security ID expected by the ad hoc instrument API. A read-only comparison on
2026-09-30 matched YARDS to TOAD for four Metals options and two futures.
Publish that ID from Matrix as `exchange_security_id`, require it for selected
legs before registration, and deploy Matrix before a dashboard that consumes
the new field. Keep the MIC paired with the exchange ID.

The Metals Table View's ATM Cty uses the desk's quote grid: round the
underlying to the nearest 25 for GC, 1 for SI, or 0.05 for CU, then select
the published Matrix call nearest that target. Picking the closest listed
strike to the unrounded underlying changes the displayed contract.

The legacy production Edge Monitor builds its PIP/EasyPricer Table View
contract cache at startup. Both `Refresh Edge` and `Refresh Strikes` reuse the
same EasyPricer, whose input providers close over that original PIP snapshot.
The latter recomputes strikes but does not fetch new prices or YTE; a process
restart is needed to refresh them. When production and a Matrix-based
replacement show different Cty or DTE values, compare the displayed
strike-refresh time and live PIP and Matrix inputs before changing strike
selection.

The Edge Monitor's TOAD Summary uses the full electronic desk breakdown,
including PL. The live Tool selector has a narrower product set (GC, SI, and
CU), so applying its product mapping to historical TOAD aggregates silently
removes valid Summary rows. Keep tool-specific selection separate from the
historical product universe.

The legacy TOAD MCP breakdown defaults to live pricing fallback and a
150-tick market-edge filter. Preserve both when moving Edge Monitor Summary
to `ToadQueryBuilder`: add `LIVE_PRICING` before `PNL_MARKOUTS`, then set
`use_live_override=True` and `max_market_edge_ticks=150`. Without fallback,
outstanding EOD markouts omit current-trade P&L while fill edge still includes
those trades, changing regular and active/passive retention. Luna ignores a
second `with_annotation()` call for an already-added annotation, so adding
live pricing after P&L and trying to reconfigure P&L does not enable fallback.
The recent-trades path still needs the P&L annotation because it also computes
the market edge used for ranking.

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

Attribution needs all option families, including FX weeklies. Resolve each
fit-table `(mic, product_code, coral_listing_id)` against its YARDS option
product and listing, and use the structured `rci_short` as the output listing
identity. Synthesizing `underlying product + month + year` collapses distinct
weekly and monthly contracts into the same name. Keep the monthly-only
vol-of-vol selection separate.

Do not reconstruct expiry from floating-point fit year fractions and then round
up to a time bucket. The legacy vol-of-vol writer's `yte * 365` reconstruction
had nanosecond error that `.ceil("5min")` amplified into a five-minute shift.
Use YARDS `last_trade_time_ns`. For migration parity, compare year-fraction
endpoints as well as the formulas; equal formulas can produce different output
when the endpoints change.

Legacy fitted-skew attribution and EOD RR skew are specific exceptions for pricing parity:
it prices to `ceil("5min")` of each scalar `skew_datetime +
pd.Timedelta(days=fit_yte * 365)`. Vector `pd.to_timedelta(..., unit="D")`
rounds differently at some five-minute boundaries and changes Event Horizon
fractions and path PnL. Keep the actual YARDS last-trade instant for source
identity and validity checks; use the reconstructed endpoint only in these
legacy attribution and RR skew calculations. RR skew selects the monthly
14:00 Chicago fit nearest `fit_yte = 0.25` before converting to voltime.
Its Delta `app=write-demo` provenance is a client label, not an external job
identity or proof of the running source revision. Compare the replacement
against the archived calculation on frozen fits, and report stored-only
listing keys separately from numerical parity.

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

Keep full destination-row parity comparisons in pre-cutover validation, not in
scheduled writers. The deployed writers validate and merge prepared rows; a
narrow key ownership check prevents one venue from overwriting the other's
trade in the shared futures table.

Blockworm can include supported and unsupported futures security groups in one
event, such as an HG leg paired with HGS. The legacy writer filters to GC, SI,
and HG before requesting quote mids. Preserve that filter before quote lookup
or one unresolved HGS identity can fail the whole HG date. A preliminary
ten-second bar can also have a zero-size ask and no implied quote while the
standard bar at that same epoch has usable implied sides. Keep preliminary
quotes for valid bars and request the standard bar only as an explicit fallback
for an invalid preliminary mid; do not treat a zero-size side as a price of zero.


## Delta attribution commit conflicts

An October 1, 2026 local reproduction copied the production PL attribution
schema, planned a timestamp-equality merge, committed overlapping rows through
another Delta handle, and executed the first merge. Delta/DataFusion raised
`arrow_cast should have been simplified to cast` while checking the conflict.
The fio wrapper reports this as probably concurrent. Reread the destination,
revalidate retained values, and rebuild the merge for bounded retries; do not
repeat the stale transaction plan. Setting `max_commit_retries=0` instead made
an ordinary copied-table merge fail with `Failed to commit transaction: 0`.

Recalculation can omit stored attribution entry keys: research-fx CU September
21 had 2,632 stored keys versus 2,604 recalculated keys, with 28 omitted
H3EV2026 deltas at 07:00 Chicago. An upsert preserves those existing rows;
report them as unrecalculated rather than deleting them or claiming freshness.
Read and verify whole Chicago dates using local-midnight UTC boundaries,
including daylight-saving transitions. Commit provenance identifies which
writer produced output; another writer's latest rows do not prove the new job
completed. Evidence: `~/anvil/notebooks/metals_merged_writers_output_audit.py`.

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

Hedge history can also gain an event after an attribution partition stops
being recalculated. An EC hedge event timestamped September 17, 2026 at
12:27:20 UTC was absent in hedge-table version 9007 (September 23 commit) and
present in version 9050 (September 24 commit). The stored September 10 EC
five-day attribution already had its old value by September 18. Including
the late event changed `sdrv_0.8_5d` from 0.045290566 to 0.049202525;
removing that event from the replay exactly reproduced the stored value.
Compare input-table versions before changing event logic to fit stored output.

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
next session opens. The PnL Scalloper can replace the live `fd_` close feed ten
minutes before reopening. The final publisher must save the dated close report
before that preopen window; the later Metals EOD email reads that dated final
for both scheduled runs and reruns. The FX email runs earlier and still reads
the live feed. `publish_final_pnl --date` reads an existing dated final after
reopening, so it can replay one but cannot reconstruct a missing final. A true
historical backfill requires the historical Scalloper inputs. Keep the source
epoch bound: accepting next-session PnL as a close result changes the report.
The raw `fd_` Metals, expiration, and FX OPXL keys had no dated snapshots for
September 21-28, 2026, so a missing final could not be recovered from them.
For a replay, preserve the Scalloper's earliest-snapshot selection within the
61-minute close window; later Delta snapshots can differ by nearly an hour.
Historical Delta Greeks retain pricing inputs but lack strike and put/call, so
recover those from structured historical instruments or refdata and prove
per-group parity against an existing dated final before publishing a repair.

Changing a live PnL Scalloper's DED `git_ref` from `master` to `production`
changes its Argo Application identity. On September 30, 2026, Argo began
deleting both old Metals Scalloper applications at 20:40 UTC and created the
replacement new Scalloper application at 21:07 UTC, after the 21:00 GC close.
The live Metals PnL key stopped updating at 20:41. Keep ref-changing rollouts
outside the close window; a post-close final publisher must reject a feed last
published while the market was still open. Its source calculation epoch can
reflect the earlier settlement window, so check publication time separately.

When an expired option is absent from ending pricing history, use the live
underlying price for both its spot and forward when setting `pricing_yte_live`
to zero. A missing forward can reach SOL volatility queries as NaN; orjson then
serializes a generated non-finite volatility bump as null, which SOL rejects.
The August 8, 2025 Rerun PnL replay reproduced this for nine GC/SI positions in
Prop books. The captured-input replay completed after filling the forward;
this was local validation and did not publish a repair.

## Multiday option attribution parity

The old PIP interval writer selects initial listings with `yte > 1e-5`; the
PIP hedge-event writer uses `yte > 1e-6` and emits a start only after its
first full business-day horizon is available. The fitted-skew interval writer
retains starts with an entry observation but no complete horizon and null PnL.
The fitted-skew event calculation skips incomplete horizons; its old wrapper
catches a failed date and continues to later dates/products. Preserve that
batch-progress behavior explicitly for expected incomplete input rather than
allowing an immature final date to abort all remaining products.
Only classify an empty calculation as an incomplete horizon after input and
listing-selection validation, when eligible history ends before the first
horizon. Log both timestamps and skip the merge; invalid input must still fail.
Apply this shared event-horizon policy to both PIP hedging and Research-FX.
Interval profiles retain entry rows with null unfinished PnL instead of skipping.
An October 7 fixed-clock 06:30 replay skipped GC and reached SI with no writes.
For near-expiry rows whose implied strike is null, the old calculation can still
store zero delta, vega, vanna, rho, and skew components while option PnL,
gamma, and theta remain null.
Compare row keys and null locations as well as shared non-null values before
merging a replacement into the existing Delta tables.
Pandas can convert a union of fitted-skew timestamps (pytz Chicago) and
schedule timestamps (`ZoneInfo` Chicago) to UTC. Convert each timestamp back
to Chicago before applying a time-of-day session filter; otherwise the 12:30
and 14:30 Chicago entry fits on September dates become 17:30 and 19:30 UTC
and fall into that excluded range.
At 01:00 Chicago, the prior business day's 14:30 entry has not completed its
first business-day horizon, so a PIP hedge-event batch should end one eligible
day earlier.

For current attribution health, inspect `app=write-pnl-attribution` MERGE
predicates and source-row counts separately for every profile/product. A table
snapshot can include retained legacy rows, and a job can stop between products.
Repeat the commit check before calling a slow job failed: on October 7 hedging
CU advanced while PIP interval CU and research-FX GC remained unchanged.
Research-FX's next GC entry reproduced `No attribution rows were calculated`
with history ending before all first horizons; the user later supplied that
deployed traceback and reported PIP interval `OOMKilled`. Raising the latter's
configured memory limit adds headroom but does not prove the next batch completes.

An Efficiency Argo `Healthy` status does not establish signal publication.
Check the intended tool's current per-instrument metadata, Kafka broker rate,
and retained batch timestamps separately. When Kafka has equal low/high offsets,
there is no retained batch to date; use Eventstore evidence for earlier activity.

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

The vol-of-vol OPXL publisher preserves desk monthly labels such as `CUU2026`,
while YARDS can use the option-family RCI symbol. Resolve that identity from
PIP's structured MIC, option product, and last-trade time, then YARDS' listed
month/year; filter the publisher's eligible YTE range before refdata lookup.
For hourly PIP history, allow entry assembly beyond the final snapshot label
and stop once that labelled snapshot arrives. Shared `OpxlClient.publish_df`
requires timestamps as strings and omits the dataframe index, so explicitly
materialize both when preserving the legacy vol-of-vol wire table. Verify the
published epoch and all row values after OPXL propagation before cutover.
