{{ config(
    materialized='table',
    hours_to_expiration=168,
    labels={'application': 'bch-analytics', 'layer': 'staging'}
) }}

-- Capture the source maximum once. The bounds are source-relative so a delayed
-- public dataset remains queryable instead of being compared with wall-clock time.
with source_max as (
    select
        max(t.block_timestamp) as max_block_timestamp
    from {{ source('bch_analytics', 'transactions') }} as t
),
bounds as (
    select
        max_block_timestamp as window_end_timestamp,
        date_trunc(
            date_sub(
                date(max_block_timestamp),
                interval {{ var('lookback_months', 3) }} month
            ),
            month
        ) as window_start_partition_date,
        timestamp(
            date_sub(
                date(max_block_timestamp),
                interval {{ var('lookback_months', 3) }} month
            )
        ) as window_start_timestamp,
        date(max_block_timestamp) as window_end_partition_date
    from source_max
)
select
    window_start_timestamp,
    window_end_timestamp,
    window_start_partition_date,
    window_end_partition_date,
    {{ var('lookback_months', 3) }} as window_months,
    current_timestamp() as window_captured_at_timestamp
from bounds
