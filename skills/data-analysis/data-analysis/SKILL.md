---
name: data-analysis
description: Answer a data question from logs, CSVs, SQL, metrics, or analytics. Use when the task asks for a count, trend, cohort, funnel, anomaly, or comparison and the answer must come from real data.
---

# Data Analysis

Answer the question from the data, not from a plausible story.

## Process

1. State the question and the decision it informs.
2. Find the canonical source: table, file, API, or dashboard. Read its schema.
3. Sample 20 rows before writing a query. Check types, nulls, time zone, and
   duplicate keys.
4. Write the smallest query that answers the question. Prefer DuckDB, SQLite,
   or the project's existing query tool.
5. Validate the result: totals, row counts, and a second independent query where
   possible.
6. Report the result with the query, the data source, and the caveats.

## Gotchas

- Nulls that mean "missing", "zero", and "not applicable" in the same column.
- Time zones: the server's day is not the user's day.
- Duplicate events from retries or double writes.
- Survivorship and sampling bias.
- A metric that changed definition mid-period.
- Joins that multiply rows.

## Output

`analysis.md`:

```markdown
# <question>

## Answer
## Data
## Query
## Validation
## Caveats
```

## Report

```
QUESTION: <one line>
SOURCE: <table/file>
RESULT: <one line>
CONFIDENCE: <high|medium|low>
```
