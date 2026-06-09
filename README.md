# 🏏 IPL Data Analysis — SQL

Analysed IPL cricket data using MySQL. Wrote queries from scratch to uncover performance insights across players, teams, and matches.

## 📂 Files

| File | Description |
|---|---|
| `ipl_dataset.sql` | Database schema + sample data for all 5 tables |
| `query's_on_ipl_dataset.sql` | All analysis queries organised by topic |
| `query's2_on_ipl_dataset.sql` | All analysis queries organised by topic |
| `query's3_on_ipl_dataset.sql` | All analysis queries organised by topic |
## 🗃️ Database Structure

5 tables — `teams`, `players`, `matches`, `batting_scorecard`, `bowling_scorecard`

## 📊 What I Analysed

**Batting** — top run scorers, strike rates, century counts, best innings per player

**Bowling** — wicket takers, economy rates, performance by team

**Window Functions** — used `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `FIRST_VALUE()`, `LAST_VALUE()`, `NTH_VALUE()`, `NTILE()`, `CUME_DIST()`, `LAG()`, `LEAD()`

**CTEs** — chained `WITH` clauses to break complex queries into readable steps

**CASE WHEN** — player performance grading, innings classification, form tracking

## 🛠️ Tech

- MySQL 8.0
- MySQL Workbench

## 🚀 How to Run

1. Run `ipl_dataset.sql` to create the database and insert data
2. Run any query from `query's_on_ipl_dataset`,`query's2_on_ipl_dataset`,`query's3_on_ipl_dataset`

---

*Part of my data analytics learning journey.*
