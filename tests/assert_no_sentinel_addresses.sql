-- Empty, null, and textual null sentinels must not be treated as addresses.
select address
from {{ ref('stg_protocol_coinbase_addresses') }}
where address is null
   or trim(address) = ''
   or lower(address) in ('null', 'none', 'undefined')
union all
select address
from {{ ref('stg_address_ledger') }}
where address is null
   or trim(address) = ''
   or lower(address) in ('null', 'none', 'undefined')
