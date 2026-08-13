{{ config(materialized='view') }}

select
    fdic_institution_id,
    fdic_branch_id,
    institution_name,
    branch_name,
    main_office_flag,
    established_date,
    acquired_date,
    institution_primary_regulatory_agency,
    institution_category,
    latitude,
    longitude,
    geo_id_state as state_geo_id,
    geo_id_county as county_geo_id,
    geo_id_cbsa as cbsa_geo_id
from {{ source('public_risk', 'fdic_branch_locations_index') }}
