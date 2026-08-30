-- Singular dbt test: fails (returns rows) if any order's recorded `amount`
-- doesn't match the sum of its own line items' revenue, beyond a one-cent
-- rounding tolerance. This is the concrete example
-- docs/architecture.md gives for why fct_orders has a dbt test at all — a
-- broken upstream assumption (e.g. a line item silently dropped) shows up
-- here immediately instead of quietly skewing every revenue metric
-- downstream.

select
    order_id,
    amount,
    computed_revenue,
    abs(amount - computed_revenue) as discrepancy
from {{ ref('fct_orders') }}
where abs(amount - computed_revenue) > 0.01
