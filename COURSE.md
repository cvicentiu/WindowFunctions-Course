# CTEs

## What is a Common Table Expression?
> A Common Table Expression (CTE) is a modern SQL feature used to define a
> temporary result set. CTEs can also be considered query-level views or
> query-level temporary tables.
>
> The main purpose of using CTEs is to simplify complex queries. This is generally done
> by using CTEs instead of nested subqueries. This generally makes queries more
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
FROM engineers                        # Here we are referencing the "engineers" CTE
WHERE engineers.salary > 1000
```
This query first creates a CTE called `engineers`. The contents of engineers is "all employees from the 'Engineering' department".
Afterwards, the main `SELECT` statement filters engineers by their salary, only returning those with a salary greater than 1000.

In "traditional SQL", to obtain the same result one would have to use a subquery:

```sql
SELECT *
FROM (
  SELECT name, title, salary
  FROM employees
  WHERE dept = 'Engineering'
) AS engineers
WHERE engineers.salary > 1000
```

## Complex queries become more readable with CTEs

Understanding a complex query involving subqueries is difficult because semantically one has to start considering the subqueries first. The problem is that subqueries are nested somewhere in the middle of the query, which makes for an unusual reading exercise. This gets harder the deeper the hierarchy goes. Compare the following equivalent selects and judge for yourself which one is easier to understand.

### Using subqueries
```sql
SELECT *
FROM (SELECT *
      FROM (SELECT *
            FROM employees
            WHERE dept=”Engineering”) AS engineers 
      WHERE engineers.country IN (”NL”, "DE", "FR")) as eu_engineers
WHERE ...
```
### Using CTEs
```sql
WITH engineers AS (                          # Linear View
     SELECT *
     FROM employees
     WHERE dept=”Engineering”
),
eu_engineers AS (
     SELECT *
     FROM engineers
     WHERE country IN (”NL”,...)    
)
SELECT *
FROM eu_engineers
WHERE …
```
