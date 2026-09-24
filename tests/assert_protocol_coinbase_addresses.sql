-- The exclusion set must be exactly the non-empty normalized outputs of
-- protocol coinbase transactions in the staged analysis window.
with expected as (
    select distinct
        nullif(trim(output_address), '') as address
    from {{ ref('stg_transactions') }} as t
    cross join unnest(t.outputs) as output_item
    cross join unnest(output_item.addresses) as output_address
    where t.is_coinbase = true
      and output_address is not null
      and trim(output_address) <> ''
      and lower(trim(output_address)) not in ('null', 'none', 'undefined')
),
actual as (
    select address
    from {{ ref('stg_protocol_coinbase_addresses') }}
)
select expected.address
from expected
left join actual using (address)
where actual.address is null
union all
select actual.address
from actual
left join expected using (address)
where expected.address is null
