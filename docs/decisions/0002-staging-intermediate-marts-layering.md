# 0002 — Enforce staging → intermediate → marts, no layer-skipping

## Context
With multiple metric models eventually reading from the same underlying events and
orders data, it would be easy for a new metric model to just join directly against
staging "to save a step."

## Decision
Each layer may only reference the layer directly beneath it. A metrics-layer model
never references staging or a seed directly; it reads from `marts/core` only.

## Why
Layer-skipping is how a small project turns into an unreadable dependency graph —
the first shortcut is harmless, the tenth one means nobody can tell what depends on
what without reading every model's SQL. Enforcing the layering while the project is
still small keeps `dbt docs generate`'s lineage graph meaning something as more
metrics are added.

## Trade-off accepted
A metric that only needs one raw field still has to go through intermediate and core
to get it — a small amount of ceremony for a guarantee that pays off as the number of
models grows.
