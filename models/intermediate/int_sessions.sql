-- Groups stg_product_events by customer into sessions, using a
-- {{ var('session_gap_minutes') }}-minute inactivity gap as the session
-- boundary — see models/intermediate/intermediate.yml.
-- TODO: implement

select 1 as placeholder
