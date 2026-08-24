{{ config(materialized='view') }}

select
    fdic_deposit_observation_key,
    fdic_institution_id,
    metric_code,
    metric_name,
    observation_date,
    reported_value_usd,
    unit
from {{ ref('int_fdic_institution_annual_measures') }}
