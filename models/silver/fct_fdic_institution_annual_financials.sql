{{ config(
    materialized='table',
    cluster_by=['observation_date'],
    state={
        'lag_tolerance': '7d',
        'require_fresh_data_from': 'any',
        'pre_clone': 'if_missing'
    }
) }}

with annual_measures as (

    select *
    from {{ ref('int_fdic_institution_annual_measures') }}
), pivoted as (

    select
        fdic_institution_id,
        observation_date,
        max(case when metric_code = 'ASSET' then reported_value_usd end) as assets_usd,
        max(case when metric_code = 'DEPDOM' then reported_value_usd end) as domestic_deposits_usd,
        max(case when metric_code = 'DEPSUM' then reported_value_usd end) as total_deposits_usd
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
    total_deposits_usd,
    total_deposits_usd / nullif(assets_usd, 0) as deposit_to_asset_ratio,
    greatest(total_deposits_usd - domestic_deposits_usd, 0) as non_domestic_deposits_usd
from pivoted
where assets_usd is not null
  and domestic_deposits_usd is not null
  and total_deposits_usd is not null
