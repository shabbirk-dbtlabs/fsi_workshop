{{ config(materialized='table') }}

with house_prices as (

    select *
    from {{ ref('brz_fhfa_house_price_observations') }}

), with_growth as (

    select
        geo_id,
        observation_date as quarter_end_date,
        metric_code,
        metric_name,
        reported_value as house_price_index,
        unit,
        lag(reported_value, 4) over (
            partition by geo_id, metric_code
            order by observation_date
        ) as prior_year_house_price_index
    from house_prices

)

select
    {{ dbt_utils.generate_surrogate_key(['geo_id', 'quarter_end_date', 'metric_code']) }}
        as regional_housing_market_key,
    geo_id,
    quarter_end_date,
    metric_code,
    metric_name,
    house_price_index,
    prior_year_house_price_index,
    (house_price_index / nullif(prior_year_house_price_index, 0)) - 1
        as year_over_year_house_price_growth_rate,
    unit
from with_growth
