# Workshop exercises: debugging a broken dbt project

This project ships with a set of deliberate and naturally-occurring defects. Participants fix them
by hand in the dbt VS Code extension, using column-level lineage, CTE previews, and compiled SQL
rather than by reading the answers here.

## How to run the lab

```bash
dbt build                       # build everything, then
dbt test --no-manage-state      # honest results: no reused state
```

`--no-manage-state` matters. With dbt State enabled, unchanged tests report as `Reused` and their
pass/fail status is carried over instead of re-evaluated, which hides progress during the lab.

Optional setup so participants can click into failing rows:

```yaml
# dbt_project.yml
tests:
  fsi_workshop:
    +store_failures: true
```

## Current state of the project

Five tests fail. More importantly, **twenty-two tests pass without evaluating a single row**, which
is the most valuable lesson in the lab.

| # | Symptom | Test | Rows | Type |
| --- | --- | --- | --- | --- |
| 1 | 22 tests green on empty tables | (various) | 0 | Silent |
| 2 | Deposit-to-asset ratio above 1.5 | `dbt_utils.accepted_range` on `mart_fdic_institution_deposit_health_exercise` | 110,948 | Fails |
| 3 | Null total deposits | `not_null` on `mart_fdic_institution_deposit_health_exercise` | 1,156 | Fails |
| 4 | Portfolio ratio above 1.5 | `dbt_utils.accepted_range` on `mart_fdic_deposit_portfolio_exercise` | 4 | Fails |
| 5 | Null state geo id | `not_null` on `mart_fdic_branch_footprint_geography` | 1 | Fails |
| 6 | Negative claim payments | `dbt_utils.accepted_range` on `mart_flood_claims_county_monthly` | 2 | Fails |
| 7 | Reconciliation test never fires | `equals_healthy_financials` | 0 | Silent |
| 8 | Range test never fires | `dbt_utils.expression_is_true` | 0 | Silent |

Exercises 1, 7, and 8 are **silent failures** — tests that report green while proving nothing. Run
them first, because exercise 1 is the root cause of exercise 7 and it changes what the other
numbers look like.

---

## Exercise 1 — the test suite that proves nothing

**Difficulty:** hard · **Skills:** lineage, CTE preview, row counts

### Brief

Your FDIC deposit models are all green. Every `not_null`, every `unique`, every `accepted_values`
test on `int_fdic_institution_annual_measures`, `fct_fdic_institution_annual_financials`, and
`mart_fdic_institution_deposit_health` passes.

A stakeholder says the institution deposit health dashboard has been blank for weeks.

> Twenty-two tests pass against these three models. Explain how that is possible, find the single
> line of SQL responsible, and fix it.

### What to try

1. Open `mart_fdic_institution_deposit_health` and preview the model. How many rows come back?
2. Walk the lineage upstream one model at a time — mart, then fact, then intermediate, then bronze.
   Preview each. Identify the exact model where the row count becomes zero.
3. In that model, preview each CTE separately. Which CTE empties out?
4. Preview the bronze model and count how many rows satisfy each predicate in the `where` clause
   independently.

### Questions to answer

- Which generic tests give a false sense of safety on an empty table, and why?
- What test would you add so this can never pass silently again?

<details>
<summary>Solution (facilitator)</summary>

`models/silver/int_fdic_institution_annual_measures.sql` line 8 filters
`and fdic_branch_id is null`. In this source `fdic_branch_id` is **never** null — not on a single
one of the 2,134,288 bronze rows — so the CTE returns nothing and the whole FDIC chain is empty.

The institution/branch distinction is carried by `metric_code`, not by a null branch id:

| metric_code | rows | rows per institution-year | grain |
| --- | --- | --- | --- |
| `ASSET` | 128,815 | 1 | institution |
| `DEPDOM` | 128,798 | 1 | institution |
| `DEPSUM` | 128,795 | 1 | institution |
| `DEPSUMBR` | 1,743,317 | up to 4,893 | branch |

**Fix:** delete the `and fdic_branch_id is null` line. The existing
`where metric_code in ('ASSET', 'DEPDOM', 'DEPSUM')` already isolates institution-level measures.
The intermediate model goes to 386,408 rows and the fact to 128,816 institution-years.

`not_null`, `unique`, `accepted_values`, `relationships`, and `accepted_range` all pass on zero
rows — they are written as "return the offending rows", and an empty table has none. Guard with
`dbt_utils.at_least_one` on the primary key, or a `dbt_utils.fewer_rows_than` against the
upstream model.

**Expect a new failure after this fix.** 21 institution-years genuinely have no `DEPSUM` value in
the source, so `not_null` on `total_deposits_usd` starts failing. That is exercise 3's residue and
is a real decision, not a bug — see exercise 3.

</details>

---

## Exercise 2 — deposits worth more than the bank

**Difficulty:** medium · **Skills:** column-level lineage, grain reasoning

### Brief

`dbt_utils.accepted_range` on `deposit_to_asset_ratio` fails for **110,948 of 129,951 rows** in
`mart_fdic_institution_deposit_health_exercise`. Banks appear to hold roughly twice as much in
deposits as they hold in total assets.

> Find where the inflation is introduced. Fix it at the source rather than by widening the test.

### What to try

1. Use **column-level lineage** on `deposit_to_asset_ratio`. It resolves to `total_deposits_usd`
   and `assets_usd` — follow `total_deposits_usd` upstream specifically.
2. In `fct_fdic_institution_financials_exercise`, read the expression that builds
   `total_deposits_usd`. What is being added to what?
3. Preview the upstream `int_fdic_deposits_exercise` filtered to one `fdic_institution_id`. Compare
   the number of rows for each `metric_code`.
4. Ask the decisive question: **is every metric in that model reported at the same grain?**

### Questions to answer

- Which metric is reported per branch rather than per institution?
- The intermediate model has a `group by` that produces one row per institution-year-metric. Why
  does that not make the branch metric safe to use?

<details>
<summary>Solution (facilitator)</summary>

`DEPSUMBR` is a **branch-level** measure — total deposits of a single branch. `DEPSUM` is the
institution total. Summing `DEPSUMBR` across an institution's branches reproduces roughly the same
value as `DEPSUM`, so adding them double-counts.

The `group by` in the intermediate model is the trap: it collapses thousands of branch rows into
one row per institution-year-metric, so the output *looks* like it is at institution grain. The
grain of the **value** was destroyed by the `sum()`, but the grain of the **key** looks correct.

Two edits:

1. `models/silver/int_fdic_deposits_exercise.sql` — drop `'DEPSUMBR'` from the `metric_code` list.
2. `models/silver/fct_fdic_institution_financials_exercise.sql` — remove the
   `+ coalesce(max(case when metric_code = 'DEPSUMBR' ...), 0)` term so `total_deposits_usd` is
   just the `DEPSUM` pivot.

After this the model matches `fct_fdic_institution_annual_financials` and the ratio test passes:
zero rows exceed 1.5 in the corrected data.

</details>

---

## Exercise 3 — 1,156 institutions with no deposits

**Difficulty:** medium · **Skills:** set reasoning, preview

### Brief

`not_null` on `total_deposits_usd` fails for 1,156 rows.

> Work out what those 1,156 institution-years have in common. Decide whether this is a modelling
> bug or a genuine gap in the source, and handle it accordingly.

### What to try

1. Preview the mart filtered to `total_deposits_usd is null`. What do the other columns look like?
2. For a handful of those `fdic_institution_id` values, preview the bronze observations. Which
   `metric_code` values exist for them, and which are missing?
3. Count distinct institution-years for `DEPSUM` versus for `DEPSUMBR`. Subtract.

### Questions to answer

- Does this failure share a root cause with exercise 2?
- After you fix exercise 2, how many of these 1,156 rows remain? What should happen to the rest?

<details>
<summary>Solution (facilitator)</summary>

Mostly the same root cause as exercise 2. Because `DEPSUMBR` was in the metric filter, institutions
that reported *only* branch data were pulled into the model. They have no `DEPSUM`, so the pivot
yields null:

- 129,951 institution-years in the model
- 128,795 have a `DEPSUM` value
- difference: **exactly 1,156**

Fixing exercise 2 removes 1,135 of them, because those institution-years disappear from the model
entirely once `DEPSUMBR` is no longer selected.

**21 rows survive** — institution-years that report `ASSET` but genuinely have no `DEPSUM` in the
source. That is a real gap and needs a deliberate decision, which is the point of the exercise:

- filter them out in the fact model and document why, or
- drop the test to `severity: warn` with an `error_if` threshold, or
- accept nulls and make the mart's downstream consumers null-safe.

There is no single right answer; make participants justify one. Note the same 21 rows appear in the
healthy chain once exercise 1 is fixed.

</details>

---

## Exercise 4 — the four-row aggregate

**Difficulty:** easy · **Skills:** downstream lineage

### Brief

`portfolio_deposit_to_asset_ratio` in `mart_fdic_deposit_portfolio_exercise` breaches its range for
4 rows — one per reporting year.

> Fix this without editing `mart_fdic_deposit_portfolio_exercise`.

### What to try

1. Open the model. It is a plain `group by` with no arithmetic of its own.
2. Use lineage to find its single parent.
3. Confirm your conclusion by re-running only this test after fixing exercise 2.

<details>
<summary>Solution (facilitator)</summary>

Pure downstream contamination — the model aggregates
`mart_fdic_institution_deposit_health_exercise` and inherits the inflated deposits. Fixing exercise
2 fixes this with no edit here.

The teaching point is triage order: fix upstream first, then re-test, rather than chasing every red
test independently. Use `dbt build --select +mart_fdic_deposit_portfolio_exercise` to see the whole
chain rebuild.

</details>

---

## Exercise 5 — the bank branches with no state

**Difficulty:** medium · **Skills:** column-level lineage, joins, business judgement

### Brief

`not_null` on `state_geo_id` fails with exactly 1 row in
`mart_fdic_branch_footprint_geography`. One row does not sound like much.

> Find out how many underlying branches that single row represents, work out what they have in
> common, and propose a fix.

### What to try

1. The mart has a `group by`. One null row in the output means how many null rows in the input?
   Preview `dim_fdic_branch` where `state_geo_id is null` and count.
2. Use column-level lineage on `state_geo_id` to trace it back through `dim_fdic_branch` and
   `brz_fdic_branch_locations` to the source column.
3. The branches have no state, but they do have coordinates. Preview `latitude` and `longitude` and
   look them up.

### Questions to answer

- Is the join to `dim_geography` responsible, or was the value already null before the join?
- Should these branches be excluded, bucketed, or should the geography dimension be extended?

<details>
<summary>Solution (facilitator)</summary>

**858 branches across 34 institutions**, collapsed by the `group by` into one null row. The
aggregation hides the scale of the problem — that is the main lesson.

The coordinates give it away. They are all **US territories**:

| Institution | Latitude | Longitude | Territory |
| --- | --- | --- | --- |
| Bank Of Guam | 13.49 | 144.78 | Guam |
| First Hawaiian Bank | 15.18 | 145.71 | Northern Mariana Islands |
| Banco Popular De Puerto Rico | 18.35 | −64.93 | Puerto Rico / USVI |

The `left join` to `dim_geography` is **not** the cause — `geo_id_state` is already null in the
source, because the census geography reference covers the 50 states and DC but not territories.

Valid fixes, in rough order of quality:

1. Extend `dim_geography` with territory geo ids and backfill `state_geo_id` — correct, most work.
2. Coalesce to an explicit sentinel such as `'geoId/US-TERRITORY'` so the rows stay countable.
3. Filter territory branches out of the mart and document the scope limitation.
4. Relax the test to `severity: warn` — acceptable only with a documented reason.

Reject "just delete the test".

</details>

---

## Exercise 6 — when the test is wrong, not the data

**Difficulty:** medium · **Skills:** domain reasoning, test design

### Brief

`dbt_utils.accepted_range` with `min_value: 0` on `total_net_claim_payment_usd` fails for 2 rows in
`mart_flood_claims_county_monthly`:

| county | month | claims | property damage | net payment |
| --- | --- | --- | --- | --- |
| geoId/31011 | 2022-05 | 1 | 11,113.00 | **−12,226.26** |
| geoId/22051 | 1989-09 | 4 | 3,470.00 | **−206.64** |

> Not every red test means the model is broken. Decide whether to change the model or change the
> test, and defend it.

### What to try

1. Trace `total_net_claim_payment_usd` upstream. It sums three components — preview them
   individually for the failing county-months.
2. Ask what "net" means in the NFIP source. Can a net payment legitimately be negative?
3. Consider the blast radius: 2 rows out of how many?

### Questions to answer

- If you clamp negatives to zero, what happens to the portfolio total?
- Which is worse here — a test that fails twice a year, or a model that quietly misstates payments?

<details>
<summary>Solution (facilitator)</summary>

These are genuine. NFIP payment figures are **net** of recoveries, subrogation, and clawbacks, so a
month in which recoveries exceed fresh payments is legitimately negative. The `min_value: 0`
assumption is simply wrong about the domain.

Preferred fix: correct the **test**, not the data.

- Remove `min_value` and keep an upper bound, or
- keep the bound at `severity: warn` as an anomaly tripwire, and document that net payments are
  signed.

Clamping with `greatest(x, 0)` would overstate portfolio payments and destroy reconciliation
against FEMA published totals. This is the one exercise where editing the test is the right answer,
which is exactly why it belongs next to exercise 5, where it is not.

</details>

---

## Exercise 7 — the reconciliation test that never ran

**Difficulty:** hard · **Skills:** test authoring, join semantics

### Brief

`macros/test_equals_healthy_financials.sql` compares the defective mart against the healthy fact
table and returns rows where `total_deposits_usd` disagrees. The whole point is to prove the
defective model is wrong.

It passes.

> Explain why, then make it impossible for this test to pass without actually comparing anything.

### What to try

1. Read the macro. What kind of join does it use?
2. Count the rows on each side of that join independently.
3. Now run the join itself and count the matches.

<details>
<summary>Solution (facilitator)</summary>

The macro uses an `inner join`. The healthy side — `fct_fdic_institution_annual_financials` — has
**0 rows** because of exercise 1, so the join produces 0 matched keys and the test trivially passes.

Fixing exercise 1 makes this test start working, and it will then correctly fail until exercise 2
is fixed too. Sequencing matters: **exercise 1 → 7 → 2**.

Hardening so it cannot pass vacuously again — add to the macro, or as a companion test:

- `dbt_utils.at_least_one` on the healthy model's primary key, or
- `dbt_utils.equal_rowcount` between the two models, which fails on an empty side, or
- a `having count(*) = 0` guard inside the macro that raises when nothing was compared.

General principle worth stating out loud: **any test built on an inner join can pass because the
join found nothing.** Absence of evidence, reported as evidence of absence.

</details>
---

## Suggested running order

```
1  empty chain          → unblocks 7, changes the numbers in 2 and 3
7  reconciliation       → now fires, and correctly fails
2  grain defect         → fixes the ratio, and most of 3
3  residual nulls       → 21 rows, a judgement call
4  portfolio rollup     → verify it went green on its own
5  territory geo ids    → fix the model
6  negative payments    → fix the test
```

Exercises 5, 6, and 8 are independent and work well as parallel breakout tracks. Exercises 1–4 and
7 are a single dependency chain and are best done in order, ideally as a group walkthrough since
exercise 1 gates everything else.

## Themes to land

- An empty model passes almost every generic test. Row counts before assertions.
- A `group by` can preserve the appearance of a grain while destroying the correctness of a value.
- Aggregation hides scale: 858 bad branch records surfaced as a single failing row.
- Some red tests mean the test is wrong. Some green tests mean nothing ran.
- Fix upstream first and re-test, rather than triaging every failure independently.
