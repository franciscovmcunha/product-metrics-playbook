-- Types and renames seed_customers. No joins, no business logic — see
-- docs/data_model.md, "Staging".

select
    customer_id,
    signup_date::date as signup_date,
    upper(country) as country
from {{ ref('seed_customers') }}
