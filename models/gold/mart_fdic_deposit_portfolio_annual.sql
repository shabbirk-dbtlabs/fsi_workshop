{{ config(materialized='table') }}

with institution_health as (

    select *
    from {{ ref('mart_fdic_institution_deposit_health') }}

)

select
    observation_date,
    count(*) as reporting_institution_count,
    sum(assets_usd) as portfolio_assets_usd,
    sum(total_deposits_usd) as portfolio_total_deposits_usd,
    sum(domestic_deposits_usd) as portfolio_domestic_deposits_usd,
    sum(non_domestic_deposits_usd) as portfolio_non_domestic_deposits_usd,
    sum(total_deposits_usd) / nullif(sum(assets_usd), 0) as portfolio_deposit_to_asset_ratio,
    avg(year_over_year_deposit_growth_rate) as average_deposit_growth_rate
from institution_health
group by 1
