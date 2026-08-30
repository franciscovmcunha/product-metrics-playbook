-- 1 − metric_retention, same period definition. Built directly on top of
-- metric_retention rather than recomputing the same period logic a second
-- time against fct_orders — churn is definitionally retention's complement,
-- not an independent metric, so re-deriving it from marts/core would just
-- be the same "two places that can drift" problem
-- docs/decisions/0001-metrics-as-dbt-models-not-docs.md exists to avoid,
-- one layer up. See docs/data_model.md for why this is the one place a
-- metrics-layer model reads from another metrics-layer model.

select
    period_index,
    period_start_date,
    active_customers,
    retained_customers,
    active_customers - retained_customers as churned_customers,
    round(1 - retention_rate, 4) as churn_rate
from {{ ref('metric_retention') }}
