-- Share of sessions that include >=1 order, by calendar month.
--
-- Sessions come from fct_product_events (grouped back up to session grain
-- here), not from int_sessions directly — a metrics-layer model only reads
-- from marts/core, see docs/decisions/0002-staging-intermediate-marts-layering.md.
-- A session "includes an order" if fct_orders has an order for that
-- customer with order_ts falling inside the session's own time window.

with sessions as (
    select
        session_id,
        customer_id,
        min(session_start_ts) as session_start_ts,
        min(session_end_ts) as session_end_ts
    from {{ ref('fct_product_events') }}
    group by 1, 2

),

sessions_with_conversion as (
    select
        s.session_id,
        s.session_start_ts,
        exists (
            select 1
            from {{ ref('fct_orders') }} o
            where o.customer_id = s.customer_id
              and o.order_ts between s.session_start_ts and s.session_end_ts
        ) as converted
    from sessions s

)

select
    date_trunc('month', session_start_ts)::date as period_month,
    count(*) as session_count,
    sum(case when converted then 1 else 0 end) as converted_session_count,
    round(
        sum(case when converted then 1 else 0 end)::numeric / count(*),
        4
    ) as conversion_rate
from sessions_with_conversion
group by 1
order by 1
