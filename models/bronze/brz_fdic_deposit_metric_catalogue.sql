{{ config(materialized='view') }}

select
    variable as metric_code,
    variable_name as metric_name,
    measure as measure_name,
    unit,
    frequency,
    measurement_type
from {{ source('fdic', 'fdic_summary_of_deposits_attributes') }}
