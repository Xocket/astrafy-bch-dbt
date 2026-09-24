# ADR 0001: Source-relative window and table materialization

- **Status:** Accepted
- **Date:** 2026-09-24

## Context

The public source is delayed: it ends on 2024-05-13. A wall-clock
`CURRENT_DATE()` window would be empty and would change meaning between
runs. The source is partitioned by `block_timestamp_month`, so the
implementation must keep partition pruning while enforcing exact
transaction-time bounds.

## Decision

`stg_analysis_window` captures `max(block_timestamp)` once and defines
inclusive bounds at both ends: the captured maximum, and
`timestamp(date_sub(date(window_end), interval 3 month))`. It also
derives daily partition dates for pruning. The capture timestamp is
audit metadata only; it does not define the window.

`stg_transactions` reads the Terraform-managed source view, filters both
the partition column and the exact timestamp range, and materializes a
partitioned table. Hash duplicates are resolved by a deterministic
ranking. Nested input/output arrays keep only `index`, `addresses`, and
`value`: the fields the ledger needs.

## Consequences

- A delayed source stays usable, and the window is reproducible from the
  data, not the machine clock. A later run moves both bounds when the
  source advances.
- Table replacement removes transactions that age out; a merge-only
  incremental model would leave stale rows behind.
- The Terraform view is the access boundary; dbt gets no IAM on the
  public dataset.
- Every generated table has a seven-day expiration and workload labels,
  so abandoned resources do not accrue storage.
- The window is a partial observation for any address with history
  outside it; it is not a lifetime balance.

## Rejected alternative

`CURRENT_DATE()` or a merge-only incremental model: the first breaks on
a stale source, the second cannot delete rows that leave the window.
