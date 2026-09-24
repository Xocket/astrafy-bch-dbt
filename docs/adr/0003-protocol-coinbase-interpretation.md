# ADR 0003: Protocol coinbase interpretation

- **Status:** Accepted
- **Date:** 2026-09-24

## Context

“Coinbase” can refer to the centralized exchange or to the protocol's
coinbase transaction. The public source exposes a deterministic
`is_coinbase` flag, but no authoritative exchange-address seed is available
for this implementation. The selected interpretation must therefore be
explicit and reproducible.

## Decision

Treat Coinbase as **protocol coinbase**. Within the same captured
source-relative analysis window used by `stg_transactions`:

1. unnest each transaction's `outputs` array;
2. unnest each output's `addresses` array;
3. keep non-empty normalized addresses from transactions where
   `is_coinbase = true`; and
4. exclude those addresses from `stg_address_ledger` and `address_balances`.

`stg_protocol_coinbase_addresses` materializes the resulting set so the rule
is visible and testable. No exchange-address seed, hard-coded address list, or
wall-clock history is used.

## Consequences

- The exclusion is deterministic and scoped to the same window as movement.
- Coinbase recipients are removed from the balance mart, but their source
  transactions remain available for audit in `stg_transactions`.
- The mart is not a complete census of protocol-mined addresses outside the
  captured window.
- This decision must not be described as an exchange-Coinbase filter; the
  meaning of the flag and the limitation are part of the data contract.
