{{ config(materialized='view') }}

select
    national_flood_insurance_program_policy_id as flood_policy_id,
    county_geo_id,
    state_geo_id,
    policy_effective_date,
    policy_termination_date,
    policy_cancellation_date,
    endorsement_effective_date,
    cast(policy_count as number(18, 0)) as policy_count,
    cast(total_building_insurance_coverage as number(18, 2)) as building_coverage_usd,
    cast(total_contents_insurance_coverage as number(18, 2)) as contents_coverage_usd,
    cast(total_insurance_premium_of_the_policy as number(18, 2)) as policy_premium_usd,
    cast(policy_cost as number(18, 2)) as policy_cost_usd,
    cast(building_replacement_cost as number(18, 2)) as building_replacement_cost_usd,
    insurance_to_value_ratio
from {{ source('public_risk', 'fema_nfip_policy_index') }}
