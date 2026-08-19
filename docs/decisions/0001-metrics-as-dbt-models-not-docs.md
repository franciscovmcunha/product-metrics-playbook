# 0001 — Model metrics as dbt models, not as documentation

## Context
The original version of this project was a set of markdown playbooks defining
product metrics and when to use them. The definitions were sound; nothing enforced
that a reported number actually matched the written definition.

## Decision
Every metric in [`metrics_glossary.md`](../metrics_glossary.md) is implemented as its
own dbt model in `models/marts/metrics/`, tested and documented through dbt rather
than through a separate written page.

## Why
A metric definition and a metric's SQL drifting apart is not a hypothetical risk —
it's the default outcome of keeping them in two different places maintained by two
different habits (updating code vs. updating docs). Making the model the definition
removes the second copy that could drift.

## Trade-off accepted
Reading the metric's precise definition now requires reading SQL (or the model's
`description:` in the generated dbt docs), not just a wiki page — a reasonable
trade for anyone expected to also verify or extend the metric.
