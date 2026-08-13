{{ config(materialized='table') }}

select
    observation_date,
    count(*) as reporting_institution_count,
    sum(assets_usd) as portfolio_assets_usd,
    sum(total_deposits_usd) as portfolio_total_deposits_usd,
    sum(total_deposits_usd) / nullif(sum(assets_usd), 0) as portfolio_deposit_to_asset_ratio
from {{ ref('mart_fdic_institution_deposit_health_exercise') }}
group by 1
