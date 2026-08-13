{{ config(materialized='table') }}

-- Workshop incident: branch deposits are incorrectly treated as institutional deposits.
with annual_measures as (

    select *
    from {{ ref('int_fdic_deposits_with_grain_defect') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['fdic_institution_id', 'observation_date']) }}
        as institution_annual_financial_key,
    fdic_institution_id,
    observation_date,
    max(case when metric_code = 'ASSET' then reported_value_usd end) as assets_usd,
    max(case when metric_code = 'DEPDOM' then reported_value_usd end) as domestic_deposits_usd,
    max(case when metric_code = 'DEPSUM' then reported_value_usd end)
        + coalesce(max(case when metric_code = 'DEPSUMBR' then reported_value_usd end), 0)
        as total_deposits_usd
from annual_measures
group by 1, 2, 3

