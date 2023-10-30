# CTEs

## What is a Common Table Expression?
> A Common Table Expression (CTE) is a modern SQL feature used to define a
> temporary result set. CTEs can also be considered query-level views or
> query-level temporary tables.
>
> The main purpose of using CTEs is to simplify complex queries. This is generally done
> by using CTEs instead of nested subqueries. This usually makes queries more
> readable for developers and often allow the database query optimizer to improve
> query execution times.

## Basic Syntax
A Common Table Expression starts with the keyword `WITH`, then followed by the CTE name, then `AS`. Following `AS` we have the CTE definition or **CTE Body**.

This is the generic syntax, as supported in MariaDB.
```sql
WITH [ RECURSIVE ] table_reference [ (columns_list) ] AS (
  SELECT ...
)
[ CYCLE cycle_column_list RESTRICT ]
SELECT ...
```

We'll go into details about the optional keywords, but for starters let's have a look at the basic case.

```sql
WITH engineers AS (                   # This line defines a CTE named "engineers"
  SELECT name, title, salary          ###########
  FROM employees                      ## CTE Body
  WHERE dept = 'Engineering'          ###########
)
SELECT *
FROM engineers
```

This query can be written as a basic subquery like so:

```sql
SELECT *
FROM (
  SELECT name, title
  FROM employees
  WHERE dept = 'Engineering'
) AS engineers
```
