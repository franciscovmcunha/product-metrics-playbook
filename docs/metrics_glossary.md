# Metrics glossary

Every metric here has exactly one model that computes it (`models/marts/metrics/`) —
this glossary documents intent; the model is the source of truth for the exact SQL.

| Metric | Definition | Model |
|---|---|---|
| DAU / WAU / MAU | Distinct customers with ≥1 product event in the trailing 1 / 7 / 30 days | `metric_dau_wau_mau` |
| Conversion rate | Share of sessions (aggregated from `fct_product_events`) that include at least one order, by month | `metric_conversion` |
| Retention | Share of customers with an order in period *n* who also order in period *n+1* | `metric_retention` |
| Churn | 1 − retention, for the same period definition | `metric_churn` |
| ARPU | Total revenue in a period ÷ distinct active customers in that period | `metric_arpu` |
| Average order value (AOV) | Total revenue in a period ÷ number of orders in that period | `metric_aov` |

## Why period definitions matter more than formulas

Every metric above is trivial algebra once "period" is fixed — the actual design
decision is what counts as a period boundary and what counts as "active." Those
choices are made once, in `models/marts/metrics/metrics.yml`, and every metric model
references the same definition rather than each redefining its own notion of a week
or a month.
