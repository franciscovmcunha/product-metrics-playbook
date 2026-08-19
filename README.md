# Product Metrics Playbook

An analytics engineering project that models core product metrics — DAU/WAU/MAU,
conversion, retention, churn, ARPU, and average order value — as tested, documented
dbt models, not as a written playbook.

## Why this isn't just a document

A metric definition that lives in a wiki page and a metric definition that lives in a
dbt model answer different questions. The wiki page can say "retention is the share of
customers who order again within 30 days" — it can't tell you whether that's actually
what today's number reflects, whether the underlying event data has gaps, or whether
someone quietly changed the window to 45 days six months ago without updating the
page. Modeling metrics in dbt means the definition and the number are the same
artifact, version-controlled and tested together.

## Layering

```
seeds (synthetic orders, product events, customers)
  → staging      (typed, one model per source)
  → intermediate (sessions, order line items)
  → marts/core   (dim_customers, fct_orders, fct_product_events)
  → marts/metrics (dau_wau_mau, conversion, retention, churn, arpu, aov)
```

Each layer only depends on the layer directly below it — a metric model never reads
from staging directly, and a core mart never reads from a metric model. That
constraint is what keeps `dbt docs generate`'s lineage graph readable as more metrics
get added.

## What's in this repo

| Doc | Covers |
|---|---|
| [`metrics_glossary.md`](docs/metrics_glossary.md) | Exact definition of every metric this project computes |
| [`data_model.md`](docs/data_model.md) | The staging → intermediate → marts layering, and why |
| [`architecture.md`](docs/architecture.md) | How this differs from a metrics wiki, in practice |
| [`decisions/`](docs/decisions/) | Short ADRs for the trade-offs that mattered most |

## Stack

SQL, PostgreSQL, dbt (staging → intermediate → marts), Git.

## Status

Structure, documentation, and model interfaces (schema.yml, tests, descriptions) are
in place; the SQL inside each model is being implemented incrementally — see each
model file for what it's responsible for.

---

Seed data under `seeds/` is entirely synthetic — generated to exercise the model
layering above, not sourced from any real product or company.
