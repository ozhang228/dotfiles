# Work Knowledge

Terminology and repo map for Oscar's work at DRW (fixed-income-options desk). Applies whenever discussing these systems, regardless of which repo is open.

## Terminology

- **PIP** is ambiguous — context decides which:
  - "Pricing Inputs Publisher" (the app)
  - "pricing-inputs" (the Kafka topic prefix)
- **RVUVS** = `rv-utils-viz-server`, a Dash-based rates/vol-surface visualization app. Depends on `rv-utils` for surface-building logic. Its frontend config is deployed via the `k8s` repo (ArgoCD), not checked into `rv-utils-viz-server` itself.

## Repo map

All repos live under `~/drw/`. Relevant ones for surface_viz / RVUVS work:

- `1-desk-tools` (primary checkout) — houses `product_surface` and `vol_surface` under `python/fio/desk_tools/apps/surface_viz/`. `2-desk-tools`/`3-desk-tools`/`4-desk-tools` are separate checkouts of the same repo at the same path — verify cwd before editing (see skill-obs memory).
- `rv-utils-viz-server` — RVUVS app source (`fio/app/rv_utils_viz_server/`). Test-only example configs live in `tests/*.json`; these are NOT the deployed prod config.
- `rv-utils` — RVUVS's surface-building dependency (`fio/rv_utils/builders/`, e.g. `skews.py` has default snap-time logic).
- `k8s` — deployment manifests for all desk-tools apps, including RVUVS. Real prod config lives here, not in `rv-utils-viz-server`. Path pattern: `overlays/rv-utils-viz-server/<instance>/base/config/desk.libsonnet` (jsonnet, and prod configs commonly include `snaptime_overrides`/`market_open_overrides` for holidays). ArgoCD app definitions: `overlays/argocd/<cluster>/applications/desk-tools/rv-utils-viz-server/<instance>-prod.yaml`.

## RVUVS snap time

Confirmed from `k8s/overlays/rv-utils-viz-server/sofr/base/config/desk.libsonnet` (prod): SOFR's `data_cache.snapshot_hour/minute/second` = **15:59:50 America/Chicago**. This is a per-instance override on `DataCache.__init__`'s defaults (`rv-utils-viz-server/fio/app/rv_utils_viz_server/data_cache.py`) — other instances (crypto, lfi_se, ttf, ng, cl, soybeans) each set their own value, so never assume one instance's snap time for another; check that instance's `desk.libsonnet` in `k8s`.

`product_surface`'s own `SnapTimeConfig.time` field (`fio/desk_tools/domain/surface_viz/config.py`) only supports `"HH:MM"` (parsed via `strptime(..., "%H:%M")` in `Timing.from_config`, `fio/desk_tools/domain/surface_viz/time.py`) — no seconds. When mirroring an RVUVS snap time into a `product_surface` config (e.g. `configs/surface_viz/product_surface/dash/<instance>.json`), truncate to the minute (e.g. `15:59:50` → `"15:59"`), don't round to `"16:00"`.
