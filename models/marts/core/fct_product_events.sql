-- One row per product event, from stg_product_events + int_sessions,
-- joined to dim_customers. Carries session boundaries so metrics-layer
-- models can derive session-grain facts (e.g. metric_conversion) without
-- reading int_sessions directly — see
-- docs/decisions/0002-staging-intermediate-marts-layering.md.

select
    s.event_id,
    s.customer_id,
    s.event_ts,
    s.event_type,
    s.session_id,
    s.session_start_ts,
    s.session_end_ts,
    c.country,
    c.signup_cohort_month
from {{ ref('int_sessions') }} s
left join {{ ref('dim_customers') }} c on c.customer_id = s.customer_id
