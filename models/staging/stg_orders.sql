-- Types and renames seed_orders. No joins, no business logic — see
-- docs/data_model.md, "Staging".
--
-- `items` stays an opaque pipe-delimited string here on purpose — unpacking
-- it into one row per line item is intermediate's job (int_order_items),
-- not staging's. See docs/data_model.md, "Intermediate".

select
    order_id,
    customer_id,
    order_ts::timestamp as order_ts,
    amount::numeric(10, 2) as amount,
    upper(currency) as currency,
    items
from {{ ref('seed_orders') }}
