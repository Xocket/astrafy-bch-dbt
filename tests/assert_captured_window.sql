-- The staged maximum must be the captured source maximum, and the captured
-- bounds must describe the configured exact three-month interval.
with observed as (
    select max(block_timestamp) as max_staged_timestamp
    from {{ ref('stg_transactions') }}
),
analysis_window as (
    select *
    from {{ ref('stg_analysis_window') }}
)
select
    analysis_window.window_start_timestamp,
    analysis_window.window_end_timestamp,
    observed.max_staged_timestamp
from analysis_window
cross join observed
where analysis_window.window_months <> 3
   or analysis_window.window_start_timestamp >= analysis_window.window_end_timestamp
   or date_diff(
       date(analysis_window.window_end_timestamp),
       date(analysis_window.window_start_timestamp),
       month
   ) <> 3
   or analysis_window.window_start_timestamp != timestamp(
       date_sub(
           date(analysis_window.window_end_timestamp),
           interval 3 month
       )
   )
   or analysis_window.window_start_partition_date != date_trunc(
       date_sub(
           date(analysis_window.window_end_timestamp),
           interval 3 month
       ),
       month
   )
   or analysis_window.window_end_partition_date != date(
       analysis_window.window_end_timestamp
   )
   or observed.max_staged_timestamp is distinct from analysis_window.window_end_timestamp
