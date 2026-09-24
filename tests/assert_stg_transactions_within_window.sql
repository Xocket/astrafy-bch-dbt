-- Every staged transaction must satisfy both the exact timestamp bounds and
-- the partition-date bounds used to prune the source.
select
    staged.transaction_hash
from {{ ref('stg_transactions') }} as staged
cross join {{ ref('stg_analysis_window') }} as analysis_window
where staged.block_timestamp < analysis_window.window_start_timestamp
   or staged.block_timestamp > analysis_window.window_end_timestamp
   or staged.block_timestamp_month < analysis_window.window_start_partition_date
   or staged.block_timestamp_month > analysis_window.window_end_partition_date
   or staged.window_start_timestamp is distinct from analysis_window.window_start_timestamp
   or staged.window_end_timestamp is distinct from analysis_window.window_end_timestamp
   or staged.window_months is distinct from analysis_window.window_months
