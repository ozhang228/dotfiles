# RVUVS

RVUVS is `rv-utils-viz-server`. Map friendly widget names to telemetry labels:

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
