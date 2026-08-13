{{ config(materialized='view') }}

select
    geo_id,
    variable as metric_code,
    variable_name as metric_name,
    date as observation_date,
    cast(value as number(18, 6)) as reported_value,
    unit
from {{ source('public_risk', 'fhfa_house_price_timeseries') }}
where variable = 'FHFA_HPI_traditional_all-transactions_quarterly_NSA'
