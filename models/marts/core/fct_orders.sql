-- One row per order, from stg_orders + int_order_items, joined to
-- dim_customers. int_order_items is re-aggregated back up to order grain
-- here (item_count, computed_revenue) so this fact table stays one-row-per-
-- order — see core.yml. computed_revenue is kept alongside the order's own
-- `amount` deliberately: a dbt test on this model (amounts_match_items)
-- catches the two ever drifting apart, per docs/architecture.md's example
-- of what a dbt test on fct_orders is for.

with items_rollup as (
    select
        order_id,
        count(*) as item_count,
        sum(item_revenue) as computed_revenue
    from {{ ref('int_order_items') }}
    group by 1

),

orders as (
    select
        order_id,
        customer_id,
        order_ts,
        amount,
        currency
    from {{ ref('stg_orders') }}

)

select
    o.order_id,
    o.customer_id,
    o.order_ts,
    o.amount,
    o.currency,
    ir.item_count,
    ir.computed_revenue,
    c.country,
    c.signup_cohort_month
from orders o
left join items_rollup ir on ir.order_id = o.order_id
left join {{ ref('dim_customers') }} c on c.customer_id = o.customer_id
