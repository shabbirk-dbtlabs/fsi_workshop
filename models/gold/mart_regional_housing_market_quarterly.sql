{{ config(materialized='table') }}

select
    housing.regional_housing_market_key,
    housing.geo_id,
    geography.geo_name,
    geography.geography_level,
    housing.quarter_end_date,
    housing.house_price_index,
    housing.year_over_year_house_price_growth_rate
from {{ ref('fct_regional_housing_market_quarterly') }} as housing
left join {{ ref('dim_geography') }} as geography
    on housing.geo_id = geography.geo_id
