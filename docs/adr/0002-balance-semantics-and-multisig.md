# ADR 0002: Three-month balance semantics and multisig attribution

- **Status:** Accepted
- **Date:** 2026-09-24

## Context

The brief asks for address balances, but staging covers only a rolling
three-month window. Treating the result as a lifetime wallet balance
would be wrong. Source values are numeric satoshis, and a multisig
entry can list several addresses.

## Decision

`stg_address_ledger` turns every input and output address element into
its own row: trimmed, filtered for null/empty and textual sentinels,
case preserved, never concatenated. Inputs are negative movement,
outputs are positive. Duplicate addresses within one source entry
collapse; different entries stay distinct.

`address_balances` groups by address and exposes
`balance_satoshis = output_satoshis - input_satoshis` exactly, plus a
named `balance_bch = balance_satoshis / 100000000` conversion. Window
timestamps, lookback length, activity bounds, and transaction count ride
on each row.

Null element values contribute zero movement in the ledger; the raw
NUMERIC fields stay on `stg_transactions` for audit. Fees stay on the
transaction and are checked there; they are never assigned to an
address.

## Consequences

- A balance is a three-month net movement, not a lifetime balance.
  Negative values are valid; no non-negativity test applies.
- Case is preserved: Base58 and Bech32 representations are not safely
  interchangeable through lower-casing.
- A multisig output credits each listed address. This is attribution,
  not beneficial ownership, and the sum is not a conservation ledger.

## Rejected alternative

A lifetime balance or lower-cased addresses: the first needs history
outside the staged window, the second would merge distinct addresses.
