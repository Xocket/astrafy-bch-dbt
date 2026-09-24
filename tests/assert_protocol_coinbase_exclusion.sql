-- Excluded protocol-coinbase recipients must not reach either the address
-- ledger or the balance mart.
select ledger.address
from {{ ref('stg_address_ledger') }} as ledger
join {{ ref('stg_protocol_coinbase_addresses') }} as protocol_coinbase
    on protocol_coinbase.address = ledger.address
union all
select balance.address
from {{ ref('address_balances') }} as balance
join {{ ref('stg_protocol_coinbase_addresses') }} as protocol_coinbase
    on protocol_coinbase.address = balance.address
