{{ config(materialized='view') }}

with source_data as (

    select *
    from {{ source('fdic', 'fdic_summary_of_deposits_timeseries') }}

)

select
    {{ dbt_utils.generate_surrogate_key([
        'fdic_institution_id',
        'fdic_branch_id',
        'variable',
        'date'
    ]) }} as fdic_deposit_observation_key,
    fdic_institution_id,
    fdic_branch_id,
    variable as metric_code,

    variable_name,
    date as observation_date,
    value as reported_value,
    unit
from source_data
