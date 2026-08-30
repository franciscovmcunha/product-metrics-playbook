-- Distinct active customers (fct_product_events) in trailing 1/7/30-day
-- windows from each calendar date. One row per calendar date covering the
-- full span of event data — dates with no activity at all still get a row
-- (with dau/wau/mau of 0), courtesy of dbt_utils.date_spine, so a chart
-- built on this model never has to fill gaps itself.

with events as (
    select
        customer_id,
        event_ts::date as event_date
    from {{ ref('fct_product_events') }}

),

date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="(select min(event_ts)::date from " ~ ref('fct_product_events') ~ ")",
        end_date="(select max(event_ts)::date + interval '1 day' from " ~ ref('fct_product_events') ~ ")"
    ) }}

),

calendar as (
    select date_day::date as activity_date
    from date_spine

)

select
    c.activity_date,
    count(distinct case
        when e.event_date = c.activity_date
        then e.customer_id
    end) as dau,
    count(distinct case
        when e.event_date between c.activity_date - interval '6 days' and c.activity_date
        then e.customer_id
    end) as wau,
    count(distinct case
        when e.event_date between c.activity_date - interval '29 days' and c.activity_date
        then e.customer_id
    end) as mau
from calendar c
left join events e
    on e.event_date between c.activity_date - interval '29 days' and c.activity_date
group by 1
order by 1
