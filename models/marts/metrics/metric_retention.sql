-- Share of customers active in period n who are also active in period n+1,
-- using {{ var('retention_period_days') }}-day periods over fct_orders.
-- Period 0 starts on the date of the dataset's first order — see
-- macros/periods.sql for the shared period definition every period-based
-- metric in this project reuses.
--
-- The most recent period is excluded: it hasn't had a full period n+1 yet
-- to measure retention into, so a 0% rate there would just mean "not over
-- yet," not "nobody came back."

with bounds as (
    {{ reference_date_cte() }}

),

customer_periods as (
    select distinct
        o.customer_id,
        {{ period_index('o.order_ts', 'b.reference_date') }} as period_index
    from {{ ref('fct_orders') }} o
    cross join bounds b

),

period_totals as (
    select
        period_index,
        count(distinct customer_id) as active_customers
    from customer_periods
    group by 1

),

retained as (
    select
        cp.period_index,
        count(distinct cp.customer_id) as retained_customers
    from customer_periods cp
    inner join customer_periods cp_next
        on cp_next.customer_id = cp.customer_id
        and cp_next.period_index = cp.period_index + 1
    group by 1

)

select
    pt.period_index,
    {{ period_start_date('b.reference_date', 'pt.period_index') }} as period_start_date,
    pt.active_customers,
    coalesce(r.retained_customers, 0) as retained_customers,
    round(
        coalesce(r.retained_customers, 0)::numeric / nullif(pt.active_customers, 0),
        4
    ) as retention_rate
from period_totals pt
cross join bounds b
left join retained r on r.period_index = pt.period_index
where pt.period_index < (select max(period_index) from period_totals)
order by pt.period_index
