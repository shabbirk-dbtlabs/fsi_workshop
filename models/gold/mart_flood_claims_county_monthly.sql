{{ config(materialized='table') }}

select
    claims.flood_claims_county_month_key,
    claims.county_geo_id,
    geography.geo_name as county_name,
    claims.claim_month,
    claims.flood_claim_count,
    claims.distinct_flood_event_count,
    claims.total_property_damage_usd,
    claims.total_net_claim_payment_usd,
    claims.total_net_claim_payment_usd / nullif(claims.flood_claim_count, 0) as average_net_claim_payment_usd
from {{ ref('fct_flood_claims_county_monthly') }} as claims
left join {{ ref('dim_geography') }} as geography
    on claims.county_geo_id = geography.geo_id
