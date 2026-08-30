-- Types and renames seed_product_events. No joins, no business logic — see
-- docs/data_model.md, "Staging".

select
    event_id,
    customer_id,
    event_ts::timestamp as event_ts,
    event_type
from {{ ref('seed_product_events') }}
