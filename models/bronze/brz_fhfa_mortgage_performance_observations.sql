{{ config(materialized='view') }}

select
    geo_id,
    variable as metric_code,
    variable_name as metric_name,
    date as observation_date,
    cast(value as number(18, 6)) as reported_value,
    unit
from {{ source('public_risk', 'fhfa_mortgage_performance_timeseries') }}
where variable in (
    'Percent_30_or_60_Days_Past_Due_Date_All Mortgages',
    'Percent_90_or_More,_Days_Past_Due_Date_All Mortgages',
    'PFORB_-_Percent_in_Forbearance_All Mortgages',
    'Percent_in_the_Process_of_Foreclosure,_Bankruptcy,_or_Deed_in_Lieu_All Mortgages'
)
