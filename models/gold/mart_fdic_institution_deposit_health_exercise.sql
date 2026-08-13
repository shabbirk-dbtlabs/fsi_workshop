{{ config(materialized='table') }}

with financials as (

    select *
    from {{ ref('fct_fdic_institution_financials_exercise') }}

)

select
    institution_annual_financial_key,
    fdic_institution_id,
    observation_date,
    assets_usd,
    domestic_deposits_usd,
    total_deposits_usd,
    total_deposits_usd / nullif(assets_usd, 0) as deposit_to_asset_ratio,
    total_deposits_usd - domestic_deposits_usd as non_domestic_deposits_usd
from financials
