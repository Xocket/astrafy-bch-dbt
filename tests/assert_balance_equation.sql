-- The mart balance is the signed difference between its normalized input and
-- output aggregates. No sign or lifetime-balance assumption is made.
select address
from {{ ref('address_balances') }}
where balance_satoshis is distinct from output_satoshis - input_satoshis
   or balance_bch is distinct from cast(
       balance_satoshis / cast(100000000 as numeric) as numeric
   )
