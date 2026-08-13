{{ config(materialized='view') }}

-- Workshop incident: DEPSUMBR is a branch-level measure. This model rolls it up with
-- institution-level measures while retaining only the institution-year grain.
with observations as (

    select *
    from {{ ref('brz_fdic_deposit_observations') }}
    where metric_code in ('ASSET', 'DEPDOM', 'DEPSUM', 'DEPSUMBR')

)

select
    fdic_institution_id,
    observation_date,
    metric_code,
    sum(reported_value) as reported_value_usd
from observations
group by 1, 2, 3
