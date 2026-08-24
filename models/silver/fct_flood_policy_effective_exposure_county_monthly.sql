{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='flood_policy_effective_exposure_county_month_key',
        cluster_by=['policy_effective_month'],
        on_schema_change='fail'
    )
}}

with eligible_policies as (

    select
        flood_policy_id,
        county_geo_id,
        date_trunc('month', policy_effective_date)::date as policy_effective_month,
        policy_count,
        building_coverage_usd,
        contents_coverage_usd,
        policy_premium_usd,
        policy_cost_usd,
        building_replacement_cost_usd
    from {{ ref('brz_fema_flood_policies') }}
    where
        county_geo_id is not null
        and policy_effective_date is not null
        and policy_effective_date <= current_date

        {% if is_incremental() %}
            and policy_effective_date >= (
                select dateadd(month, -24, max(policy_effective_month))
                from {{ this }}
            )
        {% endif %}

)

select
    {{ dbt_utils.generate_surrogate_key([
        'county_geo_id',
        'policy_effective_month'
    ]) }} as flood_policy_effective_exposure_county_month_key,
    county_geo_id,
    policy_effective_month,
    count(*) as policy_record_count,
    sum(policy_count) as total_policy_count,
    sum(coalesce(building_coverage_usd, 0)) as total_building_coverage_usd,
    sum(coalesce(contents_coverage_usd, 0)) as total_contents_coverage_usd,
    sum(coalesce(building_coverage_usd, 0) + coalesce(contents_coverage_usd, 0))
        as total_coverage_usd,
    sum(coalesce(policy_premium_usd, 0)) as total_policy_premium_usd,
    sum(coalesce(policy_cost_usd, 0)) as total_policy_cost_usd,
    sum(coalesce(building_replacement_cost_usd, 0)) as total_building_replacement_cost_usd
from eligible_policies
group by 1, 2, 3
