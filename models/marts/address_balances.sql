{{ config(
    materialized='table',
    hours_to_expiration=168,
    labels={'application': 'bch-analytics', 'layer': 'marts'},
    cluster_by=['address']
) }}

with balances as (
    select
        address,
        sum(
            case
                when movement_type = 'input' then -amount_satoshis
                else 0
            end
        ) as input_satoshis,
        sum(
            case
                when movement_type = 'output' then amount_satoshis
                else 0
            end
        ) as output_satoshis,
        sum(amount_satoshis) as balance_satoshis,
        count(distinct transaction_hash) as transaction_count,
        min(block_timestamp) as first_activity_timestamp,
        max(block_timestamp) as last_activity_timestamp
    from {{ ref('stg_address_ledger') }}
    group by address
)
select
    balances.address,
    balances.input_satoshis,
    balances.output_satoshis,
    balances.balance_satoshis,
    cast(balances.balance_satoshis / cast(100000000 as numeric) as numeric) as balance_bch,
    balances.transaction_count,
    balances.first_activity_timestamp,
    balances.last_activity_timestamp,
    analysis_window.window_start_timestamp,
    analysis_window.window_end_timestamp,
    analysis_window.window_months,
    analysis_window.window_captured_at_timestamp
from balances
cross join {{ ref('stg_analysis_window') }} as analysis_window
