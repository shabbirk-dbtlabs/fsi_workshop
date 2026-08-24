{{ config(materialized='table') }}

select
    {{ dbt_utils.generate_surrogate_key([
        'county_geo_id',
        "date_trunc('month', date_of_loss)"
    ]) }} as flood_claims_county_month_key,
    county_geo_id,
    date_trunc('month', date_of_loss)::date as claim_month,
    count(*) as flood_claim_count,
    count(distinct flood_event) as distinct_flood_event_count,
    sum(coalesce(building_damage_usd, 0) + coalesce(contents_damage_usd, 0))
        as total_property_damage_usd,
    sum(
        greatest(
            coalesce(net_building_payment_usd, 0)
            + coalesce(net_contents_payment_usd, 0)
            + coalesce(net_icc_payment_usd, 0),
            0
        )
    ) as total_net_claim_payment_usd
from {{ ref('brz_fema_flood_claims') }}
where
    county_geo_id is not null
    and date_of_loss is not null
group by 1, 2, 3
