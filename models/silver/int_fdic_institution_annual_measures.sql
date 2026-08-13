{{ config(materialized='view') }}

with institution_observations as (

    select *
    from {{ ref('brz_fdic_deposit_observations') }}
    where metric_code in ('ASSET', 'DEPDOM', 'DEPSUM')
      and fdic_branch_id is null

), metric_catalogue as (

    select *
    from {{ ref('brz_fdic_deposit_metric_catalogue') }}

)

select
    observation.fdic_deposit_observation_key,
    observation.fdic_institution_id,
    observation.metric_code,
    catalogue.metric_name,
    observation.observation_date,
    cast(observation.reported_value as number(38, 2)) as reported_value_usd,
    observation.unit
from institution_observations as observation
inner join metric_catalogue as catalogue
    on observation.metric_code = catalogue.metric_code
where catalogue.unit = 'USD'
