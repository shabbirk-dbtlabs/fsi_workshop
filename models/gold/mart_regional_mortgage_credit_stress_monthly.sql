{{ config(materialized='table') }}

select
    stress.regional_mortgage_credit_stress_key,
    stress.geo_id,
    geography.geo_name,
    geography.geography_level,
    stress.month_end_date,
    stress.delinquent_30_to_60_day_rate_pct,
    stress.delinquent_90_plus_day_rate_pct,
    stress.forbearance_rate_pct,
    stress.foreclosure_or_bankruptcy_rate_pct
from {{ ref('fct_regional_mortgage_credit_stress_monthly') }} as stress
left join {{ ref('dim_geography') }} as geography
    on stress.geo_id = geography.geo_id
