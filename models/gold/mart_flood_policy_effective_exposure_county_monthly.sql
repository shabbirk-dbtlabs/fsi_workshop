{{ config(materialized='table') }}

select
    exposure.flood_policy_effective_exposure_county_month_key,
    exposure.county_geo_id,
    geography.geo_name as county_name,
    exposure.policy_effective_month,
    exposure.policy_record_count,
    exposure.total_policy_count,
    exposure.total_building_coverage_usd,
    exposure.total_contents_coverage_usd,
    exposure.total_coverage_usd,
    exposure.total_policy_premium_usd,
    exposure.total_policy_cost_usd,
    exposure.total_building_replacement_cost_usd
from {{ ref('fct_flood_policy_effective_exposure_county_monthly') }} as exposure
left join {{ ref('dim_geography') }} as geography
    on exposure.county_geo_id = geography.geo_id
