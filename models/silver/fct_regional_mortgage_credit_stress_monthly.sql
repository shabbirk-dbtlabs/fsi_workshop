{{ config(materialized='table') }}

select
    {{ dbt_utils.generate_surrogate_key(['geo_id', 'observation_date']) }}
        as regional_mortgage_credit_stress_key,
    geo_id,
    observation_date as month_end_date,
    max(case
        when metric_code = 'Percent_30_or_60_Days_Past_Due_Date_All Mortgages'
            then reported_value
    end) as delinquent_30_to_60_day_rate_pct,
    max(case
        when metric_code = 'Percent_90_or_More,_Days_Past_Due_Date_All Mortgages'
            then reported_value
    end) as delinquent_90_plus_day_rate_pct,
    max(case
        when metric_code = 'PFORB_-_Percent_in_Forbearance_All Mortgages'
            then reported_value
    end) as forbearance_rate_pct,
    max(case
        when metric_code = 'Percent_in_the_Process_of_Foreclosure,_Bankruptcy,_or_Deed_in_Lieu_All Mortgages'
            then reported_value
    end) as foreclosure_or_bankruptcy_rate_pct
from {{ ref('brz_fhfa_mortgage_performance_observations') }}
group by 1, 2, 3
