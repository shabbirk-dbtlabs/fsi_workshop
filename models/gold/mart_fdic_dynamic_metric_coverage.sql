{{ config(materialized='table') }}

{#
    Dynamic model #2, built on dynamic model #1. One union-all branch is
    generated per metric column, so both the number of scanned columns and the
    number of output rows are decided by catalogue data at compile time.
#}

-- depends_on: {{ ref('brz_fdic_deposit_metric_catalogue') }}
{% set metric_codes = institution_metric_codes() %}

with institution_metrics as (

    select *
    from {{ ref('int_fdic_dynamic_metric_pivot') }}

)

{% if metric_codes | length == 0 %}

{#- Parse-time fallback so the model always has a valid, correctly typed shape. -#}
select
    cast(null as varchar) as metric_code,
    cast(null as varchar) as metric_column,
    cast(null as number(38, 0)) as institution_year_rows,
    cast(null as number(38, 0)) as populated_rows,
    cast(null as number(38, 4)) as populated_pct,
    cast(null as number(38, 2)) as total_reported_usd,
    cast(null as varchar) as compiled_by_invocation_id
where false

{% else %}

{% for metric_code in metric_codes %}
{%- set metric_column = metric_column_name(metric_code) %}
select
    '{{ metric_code }}' as metric_code,
    '{{ metric_column }}' as metric_column,
    count(*) as institution_year_rows,
    count({{ metric_column }}) as populated_rows,
    round(count({{ metric_column }}) / nullif(count(*), 0), 4) as populated_pct,
    sum({{ metric_column }}) as total_reported_usd,
    {{ compile_fingerprint() }} as compiled_by_invocation_id
from institution_metrics
{% if not loop.last %}union all{% endif %}
{% endfor %}

{% endif %}
