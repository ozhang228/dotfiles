# RVUVS

RVUVS is the shared `rv-utils-viz-server` family, not an application heading in usage reports. Treat each friendly widget name below as a user-facing application. Group its `sofr`, `ust`, `rates-rv`, and `crypto-coral` deployments beneath it as instances when they have usage.

| Friendly name | `labels.widget` |
|---|---|
| Product Surface, Prod Surface | `surfaceGridByProductAndExpiration` |
| Vol Surface | `surfaceGridByMoneynessAndExpiration` |
| Event Weights by date | `rvUtilsEventWeightsByDate` |
| Event Weights by product | `rvUtilsEventWeights` |
| Surface Term Structure, Term Structure | `surfaceTermStructure` |

Query both Event Weights widgets when the user says only "Event Weights." Query all five labels when the user asks broadly about RVUVS usage.

Extract the instance and discard unrelated URLs with:

```spl
| rex field=url "/rvutils_viz_server/(?<instance>[^/?]+)"
| where isnotnull(instance)
```

App Launcher telemetry can attach an RVUVS widget label to an unrelated URL, so do not group every matching label without this path check.
