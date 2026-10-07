# GLD snapshot capture and pandas identity

When filtering a combined Matrix dataframe to GLD, retain its original index
when assigning a generated Series, or map values from a structured column.
Creating a Series with a fresh range index and assigning it to filtered rows
aligns by label and can silently turn thousands of generated closes into nulls.
Freeze a combined commodity/GLD payload in regressions to exercise this boundary.

Matrix's combined metadata calculation timestamp and GLD's own `calc_ts` can
differ. Persist the GLD row calculation time together with `pricing_inputs_asof`
and `skew_timestamp`; a capture label must not replace source timing.
GLD's nullable `last_trade_time` is separate from a NYSA-calendar-derived
`option_close_time` (regular or early close plus 15 minutes).
