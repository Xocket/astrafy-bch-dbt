-- Source transaction accounting includes the fee relationship. This is a
-- per-transaction check, not a global fee/balance reconciliation: protocol
-- exclusions and multisig attribution make the latter inappropriate. The
-- source schema permits nullable NUMERIC fields, so only complete source
-- accounting rows are compared rather than silently coercing unknowns.
select
    transaction_hash
from {{ ref('stg_transactions') }}
where input_value is not null
  and output_value is not null
  and fee is not null
  and coalesce(is_coinbase, false) = false
  and input_value != output_value + fee
