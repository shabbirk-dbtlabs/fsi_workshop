{{ config(materialized='table') }}

{#
    Dynamic model #1. The pivot below has one column per institution-level USD
    metric found in the metric catalogue at compile time. Adding a metric to the
    FDIC attributes source widens this model with no code change.
#}

-- depends_on: {{ ref('brz_fdic_deposit_metric_catalogue') }}
{% set metric_codes = institution_metric_codes() %}

with institution_observations as (

    select *
    from {{ ref('brz_fdic_deposit_observations') }}
    {% if metric_codes | length > 0 %}
    where metric_code in (
        {%- for metric_code in metric_codes %}
        '{{ metric_code }}'{{ ',' if not loop.last }}
        {%- endfor %}
    )
    {% endif %}

)

select
    {{ dbt_utils.generate_surrogate_key([
        'fdic_institution_id',
        'observation_date'
    ]) }} as institution_annual_metric_key,
    fdic_institution_id,
    observation_date,
    {% for metric_code in metric_codes %}
    max(case
        when metric_code = '{{ metric_code }}'
            then cast(reported_value as number(38, 2))
    end) as {{ metric_column_name(metric_code) }},
    {% endfor %}
    {{ metric_codes | length }} as metric_column_count,
    {{ compile_fingerprint() }} as compiled_by_invocation_id
from institution_observations
group by
    fdic_institution_id,
    observation_date
