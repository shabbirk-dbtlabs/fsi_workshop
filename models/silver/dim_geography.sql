{{ config(materialized='table') }}

select
    geo_id,
    geo_name,
    geography_level,
    iso_name,
    iso_alpha2,
    iso_alpha3,
    iso_numeric_code,
    iso_3166_2_code
from {{ ref('brz_geography') }}
