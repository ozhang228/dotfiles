---
name: applauncher-use
description: Query and chart production App Launcher widget usage through the Splunk MCP, grouped by application instance and user
---

# DRW App Launcher Usage

Query production App Launcher telemetry and report sessionized usage by application instance, widget, and user.

## Resolve the target

Use a known application reference when one exists:

- For RVUVS, Product Surface, Vol Surface, Event Weights, or Surface Term Structure, read [references/rvuvs.md](references/rvuvs.md).

Use the last 30 days by default. Honor an explicit time window through the Splunk MCP `earliest_time` and `latest_time` parameters.

## Query Splunk

Use the Splunk MCP query tool against `ficc-web-prod`. Filter out only `Oscar Zhang`; retain `unauthenticated` as a visible user.

Start from this discovery query when the widget label or URL shape is unknown:

```spl
index=ficc-web-prod labels.app=app-launcher NOT user.name="Oscar Zhang"
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
| where log="stream connecting" AND isnotnull(url)
| rex field=url "^(?<base_url>[^?]+)"
| eval application="<resolved application>", instance=base_url
| sort 0 user.name labels.widget application instance _time
| streamstats current=f last(_time) AS previous_time by user.name labels.widget application instance
| eval is_session_start=if(isnull(previous_time) OR _time-previous_time>1800, 1, 0)
| stats sum(is_session_start) AS sessions by application, instance, labels.widget, user.name
| sort 0 application, instance, labels.widget, - sessions
```

Replace the placeholder application and `instance=base_url` with application-specific `rex`, `case`, or `eval` expressions once discovery identifies stable path segments. Exclude unrelated URLs that happen to carry the same widget label.

App Launcher fields (`log`, `url`, `labels.widget`, and `user.name`) are already extracted. Do not run `spath` or `spath log`: `log` is a plain message, while bare `spath` duplicates the extracted scalar fields into multivalue fields and can multiply session counts. Quote dotted field names inside expressions, for example:

```spl
| eval application=case('labels.widget'="surfaceGridByProductAndExpiration", "Product Surface")
```

If the query unexpectedly returns no rows, validate the stages before reporting zero usage:

1. `| stats count by labels.widget` after the base search.
2. Add the `log="stream connecting"` filter and `| stats count by labels.widget, url`.
3. Add instance extraction and `| stats count by labels.widget, instance, user.name`.
4. Add sessionization last. For a sanity check, include `count(eval(isnull(previous_time))) AS first_rows`; it should be `1` for each user/widget/instance group.

Fix the first empty or malformed stage. Do not broaden the target labels, URL family, time window, or usage signal. If all stages are valid and the final query still has no rows, show the effective time window and filters, then report that no matching production sessions were found.

## Present the result

State the effective time window and define a session as a connection following more than 30 minutes of inactivity.

Group the report hierarchically. Create one top-level section per user-facing application, then sections for that application's instances. A widget label that identifies the requested user-facing app belongs at the application level, not beneath an infrastructure or server-family heading.

Add one prominent solid horizontal divider between application sections. Render each application name as an uppercase H1 heading immediately below the divider. Use normal H2 headings for instances without additional divider lines.

Sort users by descending sessions within each chart, show every returned user including `unauthenticated`, and print the exact session count beside each bar. Scale bars within each chart so low-volume widgets remain readable. Prefer friendly application, instance, and widget names in headings.

Follow the charts with a compact table when exact values are not already easy to copy. Call out that sessions estimate usage occasions rather than distinct human page opens because the source signal is stream telemetry.
