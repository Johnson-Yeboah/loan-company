# Loan Company Database
A PostgreSQL database project built from a lending company's loan dataset, focused on data cleaning, normalization, and SQL analysis.

## Overview
The database starts from a single source file: `loan_data.csv`. Data cleaning was performed on a dedicated `datacleaning` branch before being merged into main.

## Data Cleaning
* Checked the dataset for null values. The query used to check for nulls is visible in `datacleaning.jpg` (PostgreSQL source, line 187), and the corresponding results tab (`loan_data`) confirms the query returned no null values.
* Reviewed the `psql` terminal output in `datacleaning.jpg`, which showed that loanid was the only column with a `NOT NULL` constraint at that stage.
* Added `NOT NULL` constraints to the remaining columns to strengthen data integrity ahead of normalization.


## Normalization Journey
Getting to a properly normalized schema took a few iterations — documented here because the process (and the wrong turns) is as useful as the end result.

23/06/2026 — All columns set to `NOT NULL`, completing 1NF and 2NF.

23/06/2026 — First attempt at 3NF: 
Split `location` and customer-related columns out of `loan_data` into a separate customer table, using `stringid` as the intended link. However, `loanid` and `stringid` turned out to be numerically identical, which made a `stringid`-keyed `customer` table redundant; the same customer ID didn't actually correspond to a unique `loanid` relationship the way a proper foreign key should. Also tried isolating `location` into its own table keyed on `location` itself. Neither approach held up, and it looked at the time like the dataset might not be usable as a standard relational database.

27/06/2026 — Realized the earlier attempts were solving the wrong problem: 3NF isn't about row-level uniqueness or matching row counts between tables — it's about eliminating transitive dependencies. With that reframing:
* Dropped the separate `locations` table from the earlier attempt.
* Restored `loan_data` to include the `region` column again.
* Created a proper `customer` table containing `customergender`, `location`, and `region`, linked back to loan_data via stringid as a foreign key.

This structure removes the transitive dependency of customer attributes on `loan_data` and brings the schema to 3NF.

## Current Schema
* `loan_data` — core loan records, linked to `customer` via `stringid`
* `customer` — `customergender`, `location`, `region`, keyed for lookup via `stringid`

## SQL Work Covered

* `INNER JOIN`s between loan_data and customer
* String similarity matching using `pg_trgm` and `ILIKE`
* Aggregate functions, e.g. `ROUND(AVG(...)::NUMERIC, 2)`
* `CASE WHEN` logic for column consolidation
* Correct numeric sorting of string-formatted region values (e.g. "Region 10") using `SUBSTRING(region FROM 8)::INT` in `ORDER BY`, since default string sorting orders these incorrectly

## Key Learnings

* 3NF is about eliminating transitive dependencies, not about matching row counts or forcing 1-to-1 correspondences between tables.
* Filtering on the nullable side of an outer join in a `WHERE` clause silently turns it into an inner join.
* `GROUP BY` without an aggregate function behaves like `DISTINCT`.
* Raw counts alone aren't sufficient for regional performance analysis; proportional metrics are needed for a fair comparison across regions.




