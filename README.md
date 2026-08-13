# FSI Workshop

A dbt project that turns public financial-services and physical-risk data into analysis-ready marts.

## Model structure

- **Bronze** — source-aligned views with normalized names and types.
- **Silver** — conformed dimensions and facts at explicit analytical grains.
- **Gold** — reporting marts enriched with geography and business-ready measures.

## Data domains

| Domain | What it covers | Main Gold mart grain |
| --- | --- | --- |
| FDIC deposits | Institution financial health and branch footprint | Institution-year; state/CBSA footprint |
| Housing | FHFA house-price trends | Geography-quarter |
| Mortgage credit stress | FHFA delinquency, forbearance, and foreclosure rates | Geography-month |
| FEMA flood claims | Flood losses, damage, and net claim payments | County-month of loss |
| FEMA flood policies | New policy coverage, premiums, and policy costs | County-month of policy effective date |

## Key marts

- `mart_fdic_deposit_portfolio_annual` — annual FDIC deposit portfolio measures.
- `mart_fdic_institution_deposit_health` — institution-level annual deposit health indicators.
- `mart_fdic_branch_footprint_geography` — FDIC branch presence by state and CBSA.
- `mart_regional_housing_market_quarterly` — geography-enriched house-price index trends.
- `mart_regional_mortgage_credit_stress_monthly` — geography-enriched mortgage stress rates.
- `mart_flood_claims_county_monthly` — county-level FEMA claims and payments.
- `mart_flood_policy_effective_exposure_county_monthly` — county-level policy coverage and premiums for policies becoming effective that month.

> Flood policy exposure is **policy-effective exposure**, not active in-force exposure. It should not be interpreted as the count or value of all policies active in a given month.

Run a scoped model and its tests with:

```bash
dbt build --select +<model_name>+
```
