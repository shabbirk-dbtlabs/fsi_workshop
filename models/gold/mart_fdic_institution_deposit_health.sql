{{ config(materialized='table') }}

with financials as (

    select *
    from {{ ref('fct_fdic_institution_annual_financials') }}

), prior_year as (

    select
        *,
        lag(total_deposits_usd) over (
            partition by fdic_institution_id
            order by observation_date
        ) as prior_year_total_deposits_usd
    from financials

)

select
    institution_annual_financial_key,
    fdic_institution_id,
    observation_date,
    assets_usd,
    domestic_deposits_usd,
    total_deposits_usd,
    non_domestic_deposits_usd,
    deposit_to_asset_ratio,
    total_deposits_usd - prior_year_total_deposits_usd as year_over_year_deposit_change_usd,
    (total_deposits_usd - prior_year_total_deposits_usd)
        / nullif(prior_year_total_deposits_usd, 0) as year_over_year_deposit_growth_rate,
    case
        when deposit_to_asset_ratio >= 0.90 then 'high_deposit_funding'
        when deposit_to_asset_ratio >= 0.50 then 'balanced_funding'
        else 'low_deposit_funding'
    end as deposit_funding_profile
from prior_year
