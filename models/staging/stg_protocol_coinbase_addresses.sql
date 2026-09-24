{{ config(
    materialized='table',
    hours_to_expiration=168,
    labels={'application': 'bch-analytics', 'layer': 'staging'},
    cluster_by=['address']
) }}

-- Only non-empty outputs of protocol coinbase transactions in the captured
-- analysis window seed the exclusion set. No exchange-address seed is used.
with normalized_outputs as (
    select distinct
        nullif(trim(output_address), '') as address
    from {{ ref('stg_transactions') }} as t
    cross join unnest(t.outputs) as output_item
    cross join unnest(output_item.addresses) as output_address
    where t.is_coinbase = true
      and output_address is not null
      and trim(output_address) <> ''
      and lower(trim(output_address)) not in ('null', 'none', 'undefined')
)
select address
from normalized_outputs
where address is not null
