{#
    Macros that let a model's *shape* be discovered at compile time instead of
    being hand-written. The metric catalogue is queried while the project is
    being parsed, so the column list of any model built on top of these macros
    is decided by warehouse data, not by the .sql file.
#}

{% macro institution_metric_codes() %}

    {#- During parsing (execute == false) no query can run, so return an empty
        list and let the second, executing pass fill in the real shape. -#}
    {% if not execute %}
        {{ return([]) }}
    {% endif %}

    {% set catalogue_query %}
        select metric_code
        from {{ ref('brz_fdic_deposit_metric_catalogue') }}
        where unit = 'USD'
          and measurement_type = 'Institution'
        order by metric_code
    {% endset %}

    {% set results = run_query(catalogue_query) %}
    {{ return(results.columns[0].values() | list) }}

{% endmacro %}


{% macro metric_column_name(metric_code) %}
    {#- ASSET -> asset_usd, INSBRDD -> insbrdd_usd -#}
    {{ return(metric_code | lower ~ '_usd') }}
{% endmacro %}


{% macro compile_fingerprint() %}
    {#- Deliberately non-deterministic: the literal changes on every compile, so
        the compiled SQL of any model using it is never byte-identical twice. -#}
    {{ return("'" ~ invocation_id ~ "'") }}
{% endmacro %}
