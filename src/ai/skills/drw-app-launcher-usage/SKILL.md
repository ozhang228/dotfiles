---
name: drw-app-launcher-usage
description: Query and chart production App Launcher widget usage through the Splunk MCP, grouped by application instance and user. Use for requests about who uses an App Launcher application or widget, how often they use it, or production usage comparisons. Includes known mappings for rv-utils-viz-server widgets such as Product Surface, Vol Surface, Event Weights, and Surface Term Structure.
---

# DRW App Launcher Usage

Query production App Launcher telemetry and report sessionized usage by application instance, widget, and user.

## Resolve the target

Use a known application reference when one exists:

- For RVUVS, Product Surface, Vol Surface, Event Weights, or Surface Term Structure, read [references/rvuvs.md](references/rvuvs.md).

For any other application:

1. Use an explicit `labels.widget` value or URL supplied by the user.
2. If only a friendly name is supplied, run a small discovery query over `labels.app=app-launcher` to identify candidate widget labels and URLs. Show ambiguous candidates instead of guessing.
3. Define the application instance from a stable URL path segment. Strip query parameters because they can contain transient widget state.

Use the last 30 days by default. Honor an explicit time window through the Splunk MCP `earliest_time` and `latest_time` parameters.

## Query Splunk

Use the Splunk MCP query tool against `ficc-web-prod`. Filter out only `Oscar Zhang`; retain `unauthenticated` as a visible user.

Start from this discovery query when the widget label or URL shape is unknown:

```spl
index=ficc-web-prod labels.app=app-launcher NOT user.name="Oscar Zhang"
| spath log
| where isnotnull(url)
| rex field=url "^(?<base_url>[^?]+)"
| stats count by labels.widget, base_url
| sort - count
```

Narrow discovery with user-provided label fragments, URL suffixes, or application names. Do not run an unbounded broad search when a narrower clue is available.

Use `stream connecting` events as the raw usage signal. Do not count raw connections as visits because App Launcher widgets can reconnect automatically. Count a new session only when the same user, widget, and application instance has had no connection for more than 30 minutes.

Adapt the target filter and instance extraction to the resolved application:

```spl
index=ficc-web-prod labels.app=app-launcher labels.widget IN (<widget labels>) NOT user.name="Oscar Zhang"
| spath log
| where log="stream connecting" AND isnotnull(url)
| rex field=url "^(?<base_url>[^?]+)"
| eval instance=base_url
| sort 0 user.name labels.widget instance _time
| streamstats current=f last(_time) AS previous_time by user.name labels.widget instance
| eval is_session_start=if(isnull(previous_time) OR _time-previous_time>1800, 1, 0)
| stats sum(is_session_start) AS sessions by instance, labels.widget, user.name
| sort 0 instance, labels.widget, - sessions
```

Replace `eval instance=base_url` with an application-specific `rex` or `eval` once discovery identifies a stable instance segment. Exclude unrelated URLs that happen to carry the same widget label.

If the query returns no rows, show the effective time window and filters, then say that no matching production sessions were found. Do not silently broaden the query.

## Present the result

State the effective time window and define a session as a connection following more than 30 minutes of inactivity.

Create one horizontal bar chart per instance and widget. Sort users by descending sessions within each chart, show every returned user including `unauthenticated`, and print the exact session count beside each bar. Scale bars within each chart so low-volume widgets remain readable. Prefer friendly application and widget names in headings.

Follow the charts with a compact table when exact values are not already easy to copy. Call out that sessions estimate usage occasions rather than distinct human page opens because the source signal is stream telemetry.
