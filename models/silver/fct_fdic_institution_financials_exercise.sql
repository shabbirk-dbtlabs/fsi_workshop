{{ config(materialized='table') }}

with annual_measures as (

    select *
    from {{ ref('int_fdic_deposits_exercise') }}

),

pivoted as (

    select
        fdic_institution_id,
        observation_date,
        max(case when metric_code = 'ASSET' then reported_value_usd end) as assets_usd,
        max(case when metric_code = 'DEPDOM' then reported_value_usd end) as domestic_deposits_usd,
        max(case when metric_code = 'DEPSUM' then reported_value_usd end)
            as total_deposits_usd
    from annual_measures
    group by 1, 2

)

select
    {{ dbt_utils.generate_surrogate_key(['fdic_institution_id', 'observation_date']) }}
        as institution_annual_financial_key,
    fdic_institution_id,
    observation_date,
    assets_usd,
    domestic_deposits_usd,
    total_deposits_usd
from pivoted
where
    assets_usd is not null
    and domestic_deposits_usd is not null
    and total_deposits_usd is not null
