{{ config(materialized='view') }}

select
    national_flood_insurance_program_claim_id as flood_claim_id,
    date_of_loss,
    county_geo_id,
    state_geo_id,
    flood_event,
    flood_type,
    cast(building_damage_amount as number(18, 2)) as building_damage_usd,
    cast(contents_damage_amount as number(18, 2)) as contents_damage_usd,
    cast(net_building_payment_amount as number(18, 2)) as net_building_payment_usd,
    cast(net_contents_payment_amount as number(18, 2)) as net_contents_payment_usd,
    cast(net_icc_payment_amount as number(18, 2)) as net_icc_payment_usd
from {{ source('public_risk', 'fema_nfip_claim_index') }}
