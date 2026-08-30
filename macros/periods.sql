{#
    Single source of truth for what a "period" is, shared by every metric
    model that buckets activity into periods (retention, churn, arpu, aov) —
    see dbt_project.yml's `retention_period_days` var and
    docs/metrics_glossary.md, "Why period definitions matter more than
    formulas". A period is `var('retention_period_days')` days wide, with
    period 0 starting on the date of the very first order in the whole
    dataset — so periods are stable across reruns and don't depend on
    "today", only on the data itself.
#}

{% macro reference_date_cte() %}
    select min(order_ts)::date as reference_date
    from {{ ref('fct_orders') }}
{% endmacro %}


{% macro period_index(timestamp_column, reference_date_column) %}
    {#- date - date in Postgres already returns an integer number of days,
        so no epoch/interval math is needed here. #}
    floor(
        ({{ timestamp_column }}::date - {{ reference_date_column }})::numeric
        / {{ var('retention_period_days') }}
    )::int
{% endmacro %}


{% macro period_start_date(reference_date_column, period_index_column) %}
    {{ reference_date_column }} + ({{ period_index_column }} * interval '{{ var("retention_period_days") }} days')
{% endmacro %}
