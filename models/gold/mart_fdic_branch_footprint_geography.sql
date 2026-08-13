{{ config(materialized='table') }}

select
    branch.state_geo_id,
    geography.geo_name as state_name,
    branch.cbsa_geo_id,
    count(*) as branch_count,
    count_if(branch.main_office_flag = 1) as main_office_count,
    count(distinct branch.fdic_institution_id) as institution_count,
    min(branch.established_date) as earliest_branch_established_date,
    avg(datediff('year', branch.established_date, current_date())) as average_branch_age_years
from {{ ref('dim_fdic_branch') }} as branch
left join {{ ref('dim_geography') }} as geography
    on branch.state_geo_id = geography.geo_id
group by 1, 2, 3
