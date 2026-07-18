<img width="1620" height="860" alt="image" src="https://github.com/user-attachments/assets/72647aef-8af9-4e78-825b-ddfac9036f14" />

# Loan Company Database
A PostgreSQL database project built from a lending company's loan dataset, focused on data cleaning, normalization, and SQL analysis. The project has also been updated as of 18.07.2026 to include the creation of an OLAP ELT pipeline using Python for scripting and Tableau for visualization.

## Overview
The database starts from a single source file: `loan_data.csv`. Data cleaning was performed on a dedicated `datacleaning` branch before being merged into main.

# Stacks Used
* `PostgreSQL`: For database management and creating views.
* `Python`: For scripting and creating a pipeline to insert `PostgreSQL Views` into `Google Sheets`.
* `Tableau`: For reading the tables from `Google Sheets` for visualization.
* `Windows Task Scheduler`: For creating automated tasks so that each `PostgreSQL` update will be reflected in `Google Sheets`.
* `Git/Github`: For storage of the project.
* `Claude AI`: For learning and debugging.

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

29/06/2026 - Queries to show all the loan statuses. This revealed that the higher the total number of customers a region has, the higher they rank in all the loan statuses. However, there may 
be other reasons why these regions with a high number of customers may be performing badly (with a high number of blocked customers and unfinished payments) or very well (high number of customers with
finished status) Therefore, descriptive analysis alone cannot be used to measure performance. 

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

## ELT Pipeline: PostgreSQL → Google Sheets → Tableau
 
18/07/2026 — Extended the project beyond the database itself into a full automated analytics pipeline. The goal: keep a Tableau Public dashboard continuously fed with fresh data from the PostgreSQL database, with no manual export/import steps.
 
**Pipeline architecture:**
 
```
PostgreSQL (4 views) → Python script (psycopg2 + gspread) → Google Sheets (4 tabs) → Windows Task Scheduler (daily trigger) → Tableau Public (auto-refresh, ~24hr cycle)
```
 
**The four source views**, each representing a different grain of analysis rather than one flat table:
- `finished_payment_customers` — row-level detail of customers with completed loans
- `loan_status_counts` — aggregate counts by loan status
- `finished_payment_by_region` — completed loans broken down by region
- `region_status_counts` — full status breakdown by region
Each view is loaded into its own pandas DataFrame and pushed to a dedicated tab in a single Google Sheet, rather than merged into one table — merging aggregates with row-level detail at different grains risks double-counting in downstream tools.
 
**Building the Python script:**
- Authenticated to Google Sheets via a Google Cloud service account (Sheets API + Drive API), using `gspread` and `google-auth`.
- Connected to PostgreSQL with `psycopg2`, pulling each view with `pd.read_sql()`.
- Wrote each DataFrame to its own worksheet tab using `gspread-dataframe`, clearing and rewriting on each run so repeated executions don't stack duplicate data.
- Iterated from a Jupyter-style workflow (`# %%` cell blocks in VS Code) into a single automation-ready `.py` script once every stage was verified working.
## Credential Exposure & Remediation
 
17/07/2026 — Partway through setup, the `.env` file (containing the PostgreSQL password, Sheet ID, and credentials file path) was accidentally committed and pushed to this public repository. Treated this as a real incident rather than a cosmetic oversight:
 
1. Rotated the PostgreSQL password immediately.
2. Removed `.env` from Git tracking (`git rm --cached`) and added a proper `.gitignore`.
3. Scrubbed `.env` entirely from Git history using `git-filter-repo`, then force-pushed the cleaned history to GitHub.
4. Verified via `git log --all --full-history -- .env` that no trace remained in any past commit.
**Lesson:** `.gitignore` needs to exist *before* the first commit of a project involving credentials, not after. Recovering from an already-pushed secret is possible but requires a full history rewrite, not just a delete-and-commit.
 
## Automation
 
18/07/2026 — Set up a Windows Task Scheduler job to run the pipeline script daily without manual intervention.
- Configured "Run only when user is logged on" (simpler than "run whether logged on or not," and appropriate here since the local PostgreSQL instance only exists while the machine is running anyway).
- Debugged an initial `0x80070002` ("file cannot be found") failure — resolved by re-selecting the Python executable via the "Browse..." dialog rather than typing the path manually, and using the full absolute path (rather than relying solely on the "Start in" working directory) in the arguments field.
- Confirmed successful automated runs via Task Scheduler's History tab (`Last Run Result: 0x0`) and by verifying fresh data appeared in Google Sheets after each scheduled run.
**Note on GitHub Actions:** considered as an alternative automation platform, but ruled out — GitHub Actions runs on remote servers with no access to `localhost`, and this project's PostgreSQL instance is local-only. Task Scheduler was the correct fit given that constraint.
 
## Tableau Dashboard
 
18/07/2026 — Connected Tableau Public to the Google Sheet (via Tableau's Google Sheets connector, which Tableau internally treats as a Microsoft Excel/Google Drive connection) and built a dashboard covering:
 
- **Loan status breakdown** — pie chart of Active / Finished / Blocked / Unknown loans
- **Loan statuses by region** — a small-multiples (trellis) view comparing all four statuses across regions side by side
- **Regional customer distribution** — total loan volume per region, revealing a heavily skewed distribution (a handful of regions, notably Region 6, account for a disproportionate share of total volume)
Design decisions made along the way:
- Kept color coding consistent for each loan status across every chart in the dashboard (e.g. "Finished" is the same color everywhere) — inconsistent color mapping between charts undermines a dashboard's trustworthiness even when the underlying data is correct.
- Sorted both the trellis and the standalone regional distribution chart by volume (descending) rather than alphabetically, so the two views can be cross-referenced at a glance.
- Used a neutral gray for the "all statuses combined" regional distribution chart, reserving the status-specific palette (blue/orange/red/teal) for status-specific views only.
**Tableau Public refresh behavior:** unlike most Tableau Public connectors, Google Sheets-sourced data refreshes automatically on a roughly 24-hour cycle — there is no manual "refresh schedule" toggle to configure. As long as the Task Scheduler job keeps the Sheet current, Tableau's own daily pull keeps the published dashboard current with no further action required.
 
## Key Learnings (Pipeline & Automation)
 
- Raw counts alone are misleading for regional comparison — a region with more total loans will naturally show higher counts across every status. A region-level completion *rate* (finished ÷ total) is the more honest metric, and is a natural next addition to the dashboard.
- `.gitignore` must be in place before the first commit involving secrets — cleaning up after the fact means rewriting Git history, not just deleting a file.
- Windows PATH inconsistencies (multiple `python.exe` stubs, `pip` not resolving) are common enough on Windows 11 with the newer Python install-manager system that `py -m pip` / `py -m <module>` is a more reliable invocation pattern than bare `python`/`pip` commands.
- pandas' `pd.read_sql()` expects a SQLAlchemy-style connection; a raw `psycopg2` connection object works but triggers a `UserWarning` — harmless for this project's scale, but worth switching to a SQLAlchemy engine for anything more production-grade.
- Jupyter notebooks are well suited to iterative development and debugging, but scheduled automation (Task Scheduler, GitHub Actions) requires a plain `.py` script — VS Code's `# %%` cell syntax offers a middle ground, giving notebook-style interactive testing inside a file that's automation-ready from the start.

 




