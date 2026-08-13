{% test equals_healthy_financials(model, compare_model, column_name) %}

select
    defective.institution_annual_financial_key,
    defective.{{ column_name }} as defective_value,
    healthy.{{ column_name }} as healthy_value
from {{ model }} as defective
inner join {{ compare_model }} as healthy
    on defective.institution_annual_financial_key = healthy.institution_annual_financial_key
where defective.{{ column_name }} <> healthy.{{ column_name }}

{% endtest %}
