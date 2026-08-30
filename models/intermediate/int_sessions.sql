-- Groups stg_product_events by customer into sessions, using a
-- {{ var('session_gap_minutes') }}-minute inactivity gap as the session
-- boundary — see models/intermediate/intermediate.yml.
--
-- Output is event-grain (one row per event_id, same grain as
-- stg_product_events) with the session it belongs to attached. Marts that
-- need session-grain (e.g. metric_conversion) aggregate this themselves —
-- see docs/decisions/0002-staging-intermediate-marts-layering.md for why
-- this stays event-grain rather than pre-aggregating here.

with events as (
    select
        event_id,
        customer_id,
        event_ts,
        event_type,
        lag(event_ts) over (
            partition by customer_id order by event_ts, event_id
        ) as prev_event_ts
    from {{ ref('stg_product_events') }}

),

flagged as (
    select
        *,
        case
            when prev_event_ts is null then 1
            when event_ts - prev_event_ts > interval '{{ var("session_gap_minutes") }} minutes'
                then 1
            else 0
        end as starts_new_session
    from events

),

sessioned as (
    select
        *,
        sum(starts_new_session) over (
            partition by customer_id
            order by event_ts, event_id
            rows between unbounded preceding and current row
        ) as session_seq
    from flagged

)

select
    event_id,
    customer_id,
    event_ts,
    event_type,
    customer_id || '-' || session_seq as session_id,
    min(event_ts) over (partition by customer_id, session_seq) as session_start_ts,
    max(event_ts) over (partition by customer_id, session_seq) as session_end_ts
from sessioned
