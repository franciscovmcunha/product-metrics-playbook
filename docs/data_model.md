# Data model

## Seeds

Three synthetic seed tables stand in for what would normally be raw application
tables: `seed_orders`, `seed_product_events`, `seed_customers`. They exist to give
every downstream model something real to run against, not to represent any actual
product's schema.

## Staging

One model per seed (`stg_orders`, `stg_product_events`, `stg_customers`) — typed,
renamed, and nothing else. Staging models never join across sources; that's what
intermediate is for.

## Intermediate

`int_sessions` groups raw product events into sessions (a session boundary is a
documented, named constant — see `models/intermediate/intermediate.yml` — not a
number repeated across every query that needs one). `int_order_items` flattens order
line items for the marts that need item-level granularity.

## Marts — core

`dim_customers`, `fct_orders`, `fct_product_events` — the fact/dimension pair every
metric model reads from. Nothing above this layer touches staging or intermediate
directly.

## Marts — metrics

One model per metric in [`metrics_glossary.md`](metrics_glossary.md), each reading
only from `marts/core`. Adding a metric never means touching an existing metric
model — that isolation is the point of the layering.
