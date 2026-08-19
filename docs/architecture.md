# Architecture — why dbt instead of a wiki

This project started as a written playbook (frameworks, definitions, templates in
markdown) and was rebuilt as an executable dbt project. The reasoning that drove that
change:

- **A definition that isn't tested drifts.** A dbt test on `fct_orders` (no negative
  amounts, no orphaned customer keys) catches a broken upstream assumption the moment
  it happens — a markdown page never notices.
- **Lineage should be queryable, not remembered.** `dbt docs generate` produces the
  actual dependency graph from `stg_orders` through to `metric_conversion` — nobody
  has to keep a diagram in a wiki up to date by hand.
- **One definition, one place.** Before, "how do we define retention" could be
  answered differently by a slide deck and a dashboard. After, there's exactly one
  model that computes it, and everything else references that model's output.

## What stayed the same

The actual metric definitions ([`metrics_glossary.md`](metrics_glossary.md)) are
unchanged from the original playbook — this was a change in how they're implemented
and enforced, not in what they mean.
