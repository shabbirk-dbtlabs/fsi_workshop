{{ config(materialized='table') }}

select
    fdic_branch_id,
    fdic_institution_id,
    institution_name,
    branch_name,
    main_office_flag,
    established_date,
    acquired_date,
    institution_primary_regulatory_agency,
    institution_category,
    latitude,
    longitude,
    state_geo_id,
    county_geo_id,
    cbsa_geo_id
from {{ ref('brz_fdic_branch_locations') }}
