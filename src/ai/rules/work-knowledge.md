# Work Knowledge

Terminology, repo map, and durable DRW/FICC desk facts for Oscar's work. Applies whenever discussing these systems, regardless of which repo is open.

## Terminology

- **PIP** is ambiguous. Context decides whether it means "Pricing Inputs Publisher" or the `pricing-inputs` Kafka topic prefix.
- **RVUVS** = `rv-utils-viz-server`, a Dash-based rates/vol-surface visualization app. It depends on `rv-utils` for surface-building logic. Its deployed frontend config lives in `k8s`, not in `rv-utils-viz-server`.
- **EORV** = Energy Options RV.
- **ARS** = `apo-risk-service`.
- **OPDS** = `option-pricing-data-service`.
- **YARDS** is not a package. In current migration notes it means the luna refdata client, `luna.unstable.refdata.RefdataClient`.

## Repo map

All repos live under `~/drw/`.

- `1-desk-tools` is the primary desk-tools checkout. It houses `product_surface` and `vol_surface` under `python/fio/desk_tools/apps/surface_viz/`.
- `2-desk-tools`, `3-desk-tools`, and `4-desk-tools` are separate checkouts of desk-tools with identical paths. Always verify cwd before editing.
- `energy` contains EORV apps, notebooks, and the legacy `eorv_scripts` publishers.
- `rv-utils-viz-server` is RVUVS app source under `fio/app/rv_utils_viz_server/`. `tests/*.json` are test fixtures, not prod config.
- `rv-utils` is RVUVS's surface-building dependency, including `fio/rv_utils/builders/`.
- `k8s` owns deployed manifests/configs for desk-tools apps and RVUVS. Real RVUVS config pattern: `overlays/rv-utils-viz-server/<instance>/base/config/desk.libsonnet`.
- `option-pricing-data-service` owns ARS/OPDS source.
- `research` is the local luna source checkout. The package is `fio-luna`.
- `clownfish` has a load-bearing old desk-tools/luna pin set. See the clownfish section before bumping it.

## Surface Viz and RVUVS

RVUVS deployed instances include `sofr`, `ust`, `rates-rv`, `otc`, and `crypto`. Rates migration stakeholders: `sofr`/`ust` are Eric Chai; `otc`/`rates-rv` are Eric Chai and Jerry Li.

Confirmed SOFR prod snap from `k8s/overlays/rv-utils-viz-server/sofr/base/config/desk.libsonnet`: `15:59:50 America/Chicago`. Snapshot time is per instance, so check that instance's `desk.libsonnet`. `product_surface` only accepts `"HH:MM"` snap times, so truncate seconds (`15:59:50` -> `"15:59"`), do not round.

RVUVS migration into desk-tools surface_viz has two separable layers:
- Yield-offset moneyness axis first. UST is the long-end bond-basket path through `YieldVolClient`; SOFR short-end is simple `strike = underlying_price + offset`.
- Delivered realized-vol overlay later. It is an edo-metrics port (`calculate_daily_vols`) with `rv`, `rv_spot`, `rv_forward`, `atm_vol_modified`, and `yte_modified`; all `sofr`, `ust`, and `rates-rv` prod instances enable it.

RVUVS term-structure metrics map to Product Surface controls as follows. Let `C`, `P`, and `A` be call-wing, put-wing, and ATM vol; let `Pc`, `Pp` be OTM call and put prices. "Equivalent" means the same formula, not guaranteed live numerical parity: parity also requires the same surface snapshot, listing universe, moneyness convention, and tick conversion.

| RVUVS output | Product Surface equivalent | Status |
| --- | --- | --- |
| `Atms` | Vol, SD `0`, Outright, no ATM normalization | Equivalent |
| `Vols (Call)` | Vol, SD `+M`, Outright, no ATM normalization | Equivalent |
| `Vols (Put)` | Vol, SD `-M`, Outright, no ATM normalization | Equivalent |
| `Vols over Flat (Call)`, `C - A` | Vol, SD `+M`, Outright, Diff ATM | Equivalent |
| `Vols over Flat (Put)`, `P - A` | Vol, SD `-M`, Outright, Diff ATM | Equivalent |
| `Slope (Squash)`, `C - P` | Vol, SD `M`, Risk Reversal, no ATM normalization | Equivalent |
| `Vols (Fly)`, `C + P - 2A` | None as one selection | Missing; Strangle plus Diff ATM would have the formula, but Product Surface disallows ATM normalization for non-Outright structures |
| `Ticks (Squash)`, `Pc - Pp` | Price (ticks), SD `M`, Risk Reversal, no ATM normalization | Equivalent when tick conversion agrees |
| `Ticks (Strangle)`, `Pc + Pp` | Price (ticks), SD `M`, Strangle, no ATM normalization | Equivalent when tick conversion agrees |
| `Ticks over Flat (Call/Put)` | None | Missing; RVUVS reprices the same wing strike with ATM vol, while Product Surface Diff ATM subtracts the ATM option at a different strike |
| `Forward Atms`, `Forward Vols (Call/Put)` | None | Missing forward-vol mode |
| `Realized*`, `Realized over Atms*`, `Realized minus Atms*` | None in Product Surface | Missing realized-vol overlay |
| `Strike (Call/Put)` | No metric equivalent | Product Surface can select strike moneyness, but does not display resolved wing strikes as the heatmap metric |

The RVUVS backend still has a `wings_as_ratios` parameter that can change Vols over Flat to `wing / ATM`, Slope to `call / put`, and Fly to `(call + put) / (2 * ATM)`. Do not present those as current frontend plot modes. The current `k8s` tree has no Wings As Ratios control. Its historical App Launcher `surfaceTermStructure` widget exposed the control with a default of `False`, but that widget config was removed from `k8s` in the 2021 widget migration. Product Surface's ATM normalization is per-Outright metric and would only reproduce the backend ratio form of Vols over Flat, not ratio Squash or Fly.

Product Surface Price plus Diff ATM is not `Ticks over Flat`: it computes wing option price minus ATM option price, whereas RVUVS holds the wing strike fixed and changes only its pricing vol to ATM vol.

`SurfaceOptionConfiguration.underlying_pricer_type` defaults to `linear`. `linear_forward_by_rate` is specifically for deribit-like spot underlyings without yte. Do not use it just because a config is rates/treasuries.

For `apps/surface_viz/product_surface`, place code by layer:
- Pure `greeks -> HeatmapData` logic: root `heatmaps.py`.
- Pure `HeatmapData -> go.Figure` and display formatting: root `plotting.py`.
- API/Dash callback orchestration: `callbacks/`.
- Dash UI/component IDs/styles: `layout/`.

Surface pricing cost is driven by skew interpolations per listing/yte, not by visual grid points. Threading the product loop is slower because solpy holds the GIL. Warm-render cache helps UI interactions, but cold renders still scale with listing count and solpy cost. The shipped fast VOL path is `SurfaceGreeksForProduct.vols_from_skews`, used only where native-yte listing vols are structurally valid. Do not reuse that shortcut for vega/theo/delta.

For `cachetools @cached` in surface_viz, never key on numpy-backed surface/greeks objects (`PlottableSurface`, `SurfaceGreeksForProduct`, `Surface`). Build keys from stable identity such as config id, `asof`, scalar settings, and enum values. Cache expensive surface computation, not cheap Plotly assembly.

Surface viz URL-reset investigation: after a server restart, tabs may race URL-to-settings against settings-to-URL and overwrite each tab's URL with defaults. Relevant files: `lib/dash/url_sync.py`, `lib/dash/url_params.py`, `apps/surface_viz/layout/url_sync.py`, `apps/surface_viz/layout/user_settings.py`, and `lib/dash/components/app_with_togglable_toolbar.py`. SSO and parsing/version mismatch were ruled out; next useful step is logging callback order or initializing component defaults from URL params.

## Risk Viewer and EORV

Risk Viewer computes PnL/risk columns desk-independently in the aggregator, then the webserver projects per desk using that desk's `MetricDefinition` list. To add a desk-specific metric, compute/publish it globally and add its `MetricDefinition` only to that desk's schema list. Do not conditionally produce columns in the aggregator. Prefer additive columns because publisher and webserver deploy separately.

YTE/time convention has two independent axes:
- Live pricing: `pricing_inputs.yte_convention` or a `transform_yte_convention` mapper block.
- Shock dataset selection: `input_shock_dataset.time_convention_tag`, which requires a matching precomputed shock dataset.

Crude's precedent switched risk-aggregator configs to event horizon but left empirical-risk publishers on caltime. As of 2026-06, energy/natgas shock data exists only as `energy_settle_skews_caltime`; do not flip EORV empirical shock tags to voltime unless a voltime dataset exists. Event-horizon instance names look like `prod-<desk>-mirror`.

Event Horizon `CALENDAR_TIME` is not plain a365 wall-clock time. It appears market-activity-weighted: weekends are compressed, not skipped or fully counted. A populated EH yte does not prove voltime. Join `client.get_product_list()` and check `calculation_type`; only `VOLTIME_WITH_USER_WEIGHTS` and `RESEARCH_VOLTIME` are real voltime.

Event Horizon's live and ad hoc year-fraction APIs are not interchangeable. `get_year_fractions` follows the product's live calculation type, while `get_adhoc_year_fractions` without an explicit request configuration can return user-weight voltime even when product metadata says `CALENDAR_TIME`. For cross-app theta parity, identify which API each app calls and query both over the exact same interval.

Risk Viewer `ForwardYteKind.VOLTIME_24H` is not always a literal 24 elapsed hours. `AttachOneDayLengths` chooses the endpoint from its interval convention; EORV uses `NEXT_SETTLE_DATE`, so the voltime interval ends at the same clock time on the next settle date and can span a weekend. EORV's additional A365 caltime source uses `WALL_CLOCK`, so `CALTIME_24H` is literally now plus 24 hours.

EORV theta reconciliation facts:
- Edo-risk PIP `theta-new` is annual Sol `Theta / 252`, with legacy non-positive and negative-theo floors. `theta-vt-new` is separately scaled by the configured Event Horizon one-business-day fraction.
- The existing EORV downstream publisher selects different edo-risk fields by complex: NG uses `theta-vt-new`, while TTF uses `theta-new`.
- Risk Viewer analytical theta divided by 252 matches edo `theta-new` for both NG and TTF. Risk Viewer 24h caltime and voltime are finite-difference repricings; use NG voltime only when targeting NG's separately selected edo `theta-vt-new`. Do not switch Risk Viewer from ad hoc to configured Event Horizon to reconcile TTF.
- Published Risk Viewer `theta_analytical_24h_voltime`, computed as analytical business-day theta multiplied by `365 * forward_ytes[VOLTIME_24H]`, matches NG edo `theta-vt-new` materially better than finite-difference voltime. Published `theta_analytical_24h_caltime` uses the corresponding `CALTIME_24H` fraction and matches edo `theta-new` for both NG and TTF. Use the stored fractions from `PricingInputs.forward_ytes_by_listing`; a finite-difference voltime/caltime ratio is only a diagnostic proxy.
- Theta PnL is a separate start-to-live attribution path and does not consume the displayed 24h theta fields.
- `theta_eod` is a partial-day horizon and should be dropped from 24h comparisons.
- `prod.energyoptionsrv.total.main.ngf` is NG complex only; TTF is `prod.energyoptionsrv.ttf-total.main.ngf` in a separate deployment.
- Prod OPXL snap timestamps are settle/EOD, not live. Only live totals compare cleanly until as-ofs are aligned.

EORV weighted greeks plan is deferred. Current live `weighted_delta == delta` and `weighted_gamma == gamma` until custom inputs are populated. Canonical energy formula uses Delta UDS regression tables: cumulative product of predicted variance ratios by tte, `vol_ratio = sqrt(cumulative_var_ratio)`, `price_ratio = underlying_price / front_month_underlying_price`, `beta = vol_ratio * price_ratio`, `weighted_delta = delta * beta`, `weighted_gamma = gamma * beta**2`. Resume via an EORV mapper pattern, not the reverted `rv_weights_source` or `ExtraSnapshotData` path.

EORV RV-sourced strike-map/expiry-risk publisher decisions:
- Input feed is the single combined `qa.risk_viewer.eorv`/risk-viewer EORV key, not split futures/options/error keys from older config.
- Product column selects NG Total vs TTF Total. Same `entity_id` can appear in multiple trading groups, so strike maps must sum by `(strike, term)` and must not dedupe by entity id.
- Build EORV-scoped refdata from luna/JWT. Do not reuse deprecated `fio.greek_client`, `fio.position`, or `fio.unified_data` plumbing.
- Publish parallel test keys for compare, not direct replacement, until cutover is explicit.
- Vega parity uses `mapped_position * live_vega * 10000 / point_value`. The 0.25 scale product set is hardcoded and should fail fast on unknown product.
- Nerd product symbols and legacy product prefixes differ. Use an explicit mapping and fail fast on unknowns.
- Expiry-risk/limits math should be ported verbatim; source columns change, not the formulas.

Edo-risk OPXL keys are authoritative for TTF/NG PnL unless Oscar asks to investigate a discrepancy. Known keys: `prod.energyoptionsrv.total.main.ngf` and `prod.energyoptionsrv.ttf-total.main.ngf`.

Known consumers of prod EORV OPXL keys in `energy`: `eorv_scripts` publishers and `ttf_slide_risk` dev notebooks. No deployed snapshot-email app in `energy` reads those keys. The deployed `ttf-slide-risk` app uses slasher + `PipGreekClient` and posts to Slack; notebook OPXL reads are not deployed behavior.

For EORV display hierarchy comparisons, PH/NP/HP/NH roll into NG by delivery month on the Risk Viewer side while edo may keep child underlyings. Check aggregate reconciliation before per-underlying diffs, and normalize grouping before joining.

## Energy Migration and Testing

In `energy`, checked-in notebooks are production consumers, not scratch. Count `.ipynb` callers in dep-kill/migration audits and keep their behavior working.

Energy deploys per branch: `ded.yaml` entries carry `git_ref`, and master is only one branch. Before calling code/deps dead, audit every deployed branch, not just master. Code that looks dead on master can be live on a deployment branch.

Avoid new dependencies on deprecated `fio.*` libraries in energy: `fio.greek_client`, `fio.position`, `fio.unified_data`, `fio.data_access.oracle`, and `fio.refdata`. Prefer `fio.desk_tools` and luna.

Canonical `fio.greek_client` replacement pattern: use `PIPSource(pip_instance, env).build_snapshot()` for raw PIP, plus `ListingRefdataSource(pip_instance, env).build_snapshot()` for strikes. Shared helper lives in `fio/energy/greeks/pip_greeks.py`. It emits flat greek rows and listing-skew rows and preserves legacy business rules. Always diff prices/counts against live legacy output, not just instrument sets.

`fio.position -> STS` and `fio.refdata -> luna` are not drop-ins for energy:
- STS uses gRPC/Sneagle/JWT and `get_snapshot()`, not the old RabbitMQ/user-pass `PositionSet` API.
- STS lacks `collapse_trading_group` and old `to_position_series/_dict` helpers. An adapter is required.
- luna refdata has no `.sel()`; old SQL-like `fio.refdata` selectors need client-side rewrite against a snapshot.
- Energy's `Provider.refdata_accessor_filtered` is already close to the luna RefdataClient/YARDS shape, but the STS migration still needs staging because RCI-short symbols may differ from old slasher `Contract` strings.

Local energy pytest collection often aborts on Vault auth. Use `conda run -n fio-energy pytest -n 0 -q --continue-on-collection-errors` for signal. Vault-rooted collection/import failures are usually not regressions, and manual import checks of deployed app entrypoints are not useful locally when they load Vault at import time.

Energy `/deps` PRs should name concrete app/module names and affected DED entries, not vague clusters. `gh pr edit --title/--body` can fail in this repo because of a Projects Classic GraphQL issue; use `gh api -X PATCH repos/fixed-income-options/energy/pulls/<N> ...` and re-read the title afterward.

## Deployments and K8s

In the k8s declarative deployment repo, overlays under `overlays/desk-tools-managed/` are generated. Source of truth lives in `desk_tools/applications/`; edit the Python app definition/config source and regenerate, instead of editing generated jsonnet directly.

Promote a Settings Gateway document from QA to prod with `~/forge/notebooks/utils/settings_gateway.py`. Run it without flags to compare first, then rerun with `--apply`; a differing prod document requires the explicit `--overwrite` flag. The helper reads the QA value, writes that exact document, and verifies prod by reading it back.

Desk-tools image bumps should land on the app's QA/dev branch for QA testing and also update prod when applicable. Each app has its own QA branch from the QA ArgoCD Application `targetRevision`. Do not assume a shared QA branch.

Current shared image tag format is `ficc/desk-tools:uv-<N>`, not the old `py311-uv-<N>` prefix. After a bump, grep the app directory for the old tag to confirm no qa/prod/per-instance override remains.

For edo-risk crude mdp-snapshot instances, prior per-instance image overrides were removed, so crude should inherit the shared `overlay-2` base. Do not re-add per-instance overrides. Crude pods are large and pinned to `default-bmh`; image rollouts can wedge if the node group cannot schedule a surge pod.

## OPDS and ARS Incidents

For edo-risk `loop_staleness`, the default first move is usually to bounce the affected instance/component if logs do not quickly explain it.

For ARS/APO staleness, investigate before bouncing. ARS stale rows have been caused by upstream/merge bugs that a bounce does not fix and can re-cache bad data.

The 2026-04-13 ARS partition-merge bug was caused by a protobuf/schema version bump changing serialized key bytes and therefore Kafka partition assignment. The permanent fix keeps the newest proto by `publishing_time` per `(snap_ms, product_code, listing_expiration_ms)`. If the staleness alert fires with that fix present, suspect upstream listing absence or a new fallback/eviction issue, not the exact old higher-partition-wins bug.

## Luna, Sol Skews, and Clownfish

For local desk-tools testing against an unpublished luna branch, temporarily add an editable `fio-luna` source in `python/pyproject.toml`:

```toml
[tool.uv.sources]
fio-luna = { path = "../../research", editable = true }
```

Do not commit that override. `uv sync` re-resolves the whole lock and may shift unrelated deps, so suspect re-resolution if unrelated tests fail.

Do not warm `Skew.sol_skew` on real `PricingInputs` objects that flow into desk-tools `MultiprocessCache`. `Skew.sol_skew` caches a SWIG `SolObjectHandle`, which is unpicklable and breaks the pickle path. If validating skews via `try_to_sol()`, use a throwaway/copy or clear the cached attr afterward. On crude, validating every skew at parse time was cheap (~15-26 ms per snapshot), but correctness filtering must not leave the real cache warm.

`clownfish` pins `fio-conda-meta >=179`, `desk-tools ==1624`, and `luna ==565` as a coupled set. Do not bump desk-tools above 1624 or luna above 565 without a full luna migration. The old luna function `bfo_implied_strike_vols_with_delivery_probabilities` exists only in luna <=565, while newer desk-tools moved to the new luna/YieldVol result shape.

Sol's real API docs live at `https://gqma.drw/sol-api-docs/index.html` (Doxygen, reachable via plain `curl`, no auth needed from a DRW-networked shell). The Python docstrings surfaced via `help(sol.foo)` in solpy are a subset and often omit field-level semantics — e.g. `sol.getModel`'s `ModelBuildMethods` dict fields (`SwaptionTenorCutoff`, `ShortTenorSwaptionTenorCutoff`, `ShortTenorSwaptionConvention`, `FundingIndex`, etc.) aren't documented anywhere in `solpy/__init__.py`, only on the corresponding C++ class page on this site (e.g. `class_sol_1_1_model_build_method_s_a_b_r.html` for `ModelBuildMethodSABR`). The site also serves a full offline mirror as a zip (`soldocumentation.zip`, linked from the index page, ~600 HTML pages) — download and grep that locally instead of guessing page URLs or scraping the live site page-by-page, since the live site's per-page URLs use opaque Doxygen hashes that aren't guessable from a symbol name.

Confirmed via `ModelBuildMethodSABR`'s doc page: `SwaptionTenorCutoff` (default `1Y`) is genuinely a sol-documented three-tier threshold, not something rv-utils invented — below it, sol treats the tenor as a caplet on the funding index (not a swaption at all); `ShortTenorSwaptionConvention`/`ShortTenorSwaptionTenorCutoff` is a second, higher cutoff for a short-tenor swaption convention distinct from the main `SwaptionConvention`. Sol's own worked example uses EUR-EURIBOR-6M with `SwaptionTenorCutoff=1Y`, `ShortTenorSwaptionTenorCutoff=2Y` — matching live `SABR-EUR-EURIBOR-6M` model data exactly. So code that checks `SwaptionTenorCutoff` before `ShortTenorSwaptionTenorCutoff` (lower threshold first) is implementing sol's documented tiering correctly, not an arbitrary/unverified port.

Prefer `fio.bitemporal.time.Instant` over raw `datetime.datetime` at function boundaries and in dataclass fields, wherever the codebase already exposes an `Instant` (e.g. `asof`, snap times, model-fetch timestamps). `Instant` is just UTC nanos-since-epoch — it has no timezone/locale ambiguity and forces callers to be explicit about conversion. Only drop to `datetime.datetime` at the edge of a function that genuinely needs local wall-clock semantics (DST-aware calendar math, a specific market's trading-day convention, an external API like `sol` that takes `datetime`) — convert via `.to_datetime()` right there, not earlier. Passing a bare `datetime` further than necessary risks accidentally doing calendar-date math in the wrong timezone (e.g. converting an `Instant` snap to UTC and reading its calendar date, when the intended date was the local trading day's).
