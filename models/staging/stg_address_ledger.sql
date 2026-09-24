{{ config(
    materialized='table',
    hours_to_expiration=168,
    labels={'application': 'bch-analytics', 'layer': 'staging'},
    cluster_by=['address']
) }}

-- Unnest each address element independently. A multisig output therefore
-- produces one attributable row per distinct normalized address; addresses
-- are never concatenated into a synthetic string.
with input_movements as (
    select distinct
        t.transaction_hash as transaction_hash,
        t.block_timestamp,
        t.block_timestamp_month,
        'input' as movement_type,
        input_item.index as entry_index,
        nullif(trim(input_address), '') as address,
        -coalesce(input_item.value, 0) as amount_satoshis,
        t.is_coinbase,
        t.fee as transaction_fee_satoshis
    from {{ ref('stg_transactions') }} as t
    cross join unnest(t.inputs) as input_item
    cross join unnest(input_item.addresses) as input_address
    where input_address is not null
      and trim(input_address) <> ''
      and lower(trim(input_address)) not in ('null', 'none', 'undefined')
),
output_movements as (
    select distinct
        t.transaction_hash as transaction_hash,
        t.block_timestamp,
        t.block_timestamp_month,
        'output' as movement_type,
        output_item.index as entry_index,
        nullif(trim(output_address), '') as address,
        coalesce(output_item.value, 0) as amount_satoshis,
        t.is_coinbase,
        t.fee as transaction_fee_satoshis
    from {{ ref('stg_transactions') }} as t
    cross join unnest(t.outputs) as output_item
    cross join unnest(output_item.addresses) as output_address
    where output_address is not null
      and trim(output_address) <> ''
      and lower(trim(output_address)) not in ('null', 'none', 'undefined')
),
movements as (
    select * from input_movements
    union all
    select * from output_movements
)
select
    movement.transaction_hash,
    movement.block_timestamp,
    movement.block_timestamp_month,
    movement.movement_type,
    movement.entry_index,
    movement.address,
    movement.amount_satoshis,
    movement.is_coinbase,
    movement.transaction_fee_satoshis,
    analysis_window.window_start_timestamp,
    analysis_window.window_end_timestamp,
    analysis_window.window_months,
    analysis_window.window_captured_at_timestamp
from movements as movement
cross join {{ ref('stg_analysis_window') }} as analysis_window
left join {{ ref('stg_protocol_coinbase_addresses') }} as protocol_coinbase
    on protocol_coinbase.address = movement.address
where protocol_coinbase.address is null
