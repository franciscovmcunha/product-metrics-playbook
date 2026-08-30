-- One row per customer, from stg_customers, enriched with signup cohort
-- (week/month of signup_date) for cohort-based retention analysis.

select
    customer_id,
    signup_date,
    country,
    date_trunc('week', signup_date)::date as signup_cohort_week,
    date_trunc('month', signup_date)::date as signup_cohort_month
from {{ ref('stg_customers') }}
