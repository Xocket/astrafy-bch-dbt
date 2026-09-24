-- Repeated address occurrences in one source entry are collapsed before the
-- ledger is materialized. Distinct entries and movement directions remain
-- independently auditable.
select
    transaction_hash,
    movement_type,
    entry_index,
    address,
    amount_satoshis,
    count(*) as duplicate_count
from {{ ref('stg_address_ledger') }}
group by
    transaction_hash,
    movement_type,
    entry_index,
    address,
    amount_satoshis
having count(*) > 1
