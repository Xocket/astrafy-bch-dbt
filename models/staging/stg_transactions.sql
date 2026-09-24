{{ config(
    materialized='table',
    hours_to_expiration=168,
    labels={'application': 'bch-analytics', 'layer': 'staging'},
    partition_by={'field': 'block_timestamp_month', 'data_type': 'date'},
    cluster_by=['transaction_hash']
) }}

-- The source relation is the Terraform-managed view over the required public
-- transactions table. The partition predicate is intentionally separate from
-- the exact timestamp predicate. The former enables source partition pruning;
-- the latter removes rows at the edges of the first and last touched partitions.
with analysis_window as (
    select
        window_start_timestamp,
        window_end_timestamp,
        window_start_partition_date,
        window_end_partition_date,
        window_months,
        window_captured_at_timestamp
    from {{ ref('stg_analysis_window') }}
),
ranked_transactions as (
    select
        t.transaction_hash,
        t.size,
        t.virtual_size,
        t.version,
        t.lock_time,
        t.block_hash,
        t.block_number,
        t.block_timestamp,
        t.block_timestamp_month,
        t.input_count,
        t.output_count,
        t.input_value,
        t.output_value,
        t.is_coinbase,
        t.fee,
        t.inputs,
        t.outputs,
        analysis_window.window_start_timestamp,
        analysis_window.window_end_timestamp,
        analysis_window.window_months,
        analysis_window.window_captured_at_timestamp,
        -- The hash is the transaction identity; scalar source fields provide
        -- a stable tie-breaker if an ingest duplicate has the same hash.
        row_number() over (
            partition by t.transaction_hash
            order by
                t.block_timestamp desc,
                t.block_number desc,
                t.block_hash desc,
                t.size desc,
                t.virtual_size desc,
                t.version desc,
                t.lock_time desc,
                t.input_count desc,
                t.output_count desc,
                t.input_value desc,
                t.output_value desc,
                t.fee desc,
                t.is_coinbase desc,
                array_length(t.inputs) desc,
                array_length(t.outputs) desc,
                to_json_string(t.inputs) desc,
                to_json_string(t.outputs) desc
        ) as source_row_number
    from {{ source('bch_analytics', 'transactions') }} as t
    cross join analysis_window
    where t.transaction_hash is not null
      and trim(t.transaction_hash) <> ''
      and t.block_timestamp_month >= analysis_window.window_start_partition_date
      and t.block_timestamp_month <= analysis_window.window_end_partition_date
      and t.block_timestamp >= analysis_window.window_start_timestamp
      and t.block_timestamp <= analysis_window.window_end_timestamp
)
select
    transaction_hash,
    size,
    virtual_size,
    version,
    lock_time,
    block_hash,
    block_number,
    block_timestamp,
    block_timestamp_month,
    input_count,
    output_count,
    input_value,
    output_value,
    is_coinbase,
    fee,
    array(
        select as struct
            input_item.index as index,
            input_item.addresses as addresses,
            input_item.value as value
        from unnest(ranked_transactions.inputs) as input_item
    ) as inputs,
    array(
        select as struct
            output_item.index as index,
            output_item.addresses as addresses,
            output_item.value as value
        from unnest(ranked_transactions.outputs) as output_item
    ) as outputs,
    window_start_timestamp,
    window_end_timestamp,
    window_months,
    window_captured_at_timestamp
from ranked_transactions
where source_row_number = 1
