-- fct_orders revenue ÷ number of orders, per period.
-- Uses the same {{ var('retention_period_days') }}-day period definition as
-- metric_retention and metric_arpu (macros/periods.sql).

with bounds as (
    {{ reference_date_cte() }}

),

orders_with_period as (
    select
        o.order_id,
        o.amount,
        {{ period_index('o.order_ts', 'b.reference_date') }} as period_index
    from {{ ref('fct_orders') }} o
    cross join bounds b

)

select
    period_index,
    {{ period_start_date('b.reference_date', 'period_index') }} as period_start_date,
    sum(amount) as total_revenue,
    count(order_id) as order_count,
    round(sum(amount) / nullif(count(order_id), 0), 2) as aov
from orders_with_period
cross join bounds b
group by 1, b.reference_date
order by 1
