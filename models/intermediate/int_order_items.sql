-- Flattens stg_orders.items — a pipe-delimited "product_id:quantity:unit_price"
-- string, e.g. "SKU-104:2:39.90|SKU-101:1:9.99" — to one row per line item.
-- This is the one place in the project that knows about that encoding; every
-- model above this one only ever sees proper columns.

with orders as (
    select
        order_id,
        customer_id,
        order_ts,
        amount as order_amount,
        items
    from {{ ref('stg_orders') }}

),

exploded as (
    select
        order_id,
        customer_id,
        order_ts,
        order_amount,
        unnest(string_to_array(items, '|')) as item_string
    from orders

)

select
    order_id,
    customer_id,
    order_ts,
    order_amount,
    trim(split_part(item_string, ':', 1)) as product_id,
    split_part(item_string, ':', 2)::int as quantity,
    split_part(item_string, ':', 3)::numeric(10, 2) as unit_price,
    (split_part(item_string, ':', 2)::int * split_part(item_string, ':', 3)::numeric(10, 2))
        as item_revenue
from exploded
