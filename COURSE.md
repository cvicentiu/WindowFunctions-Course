# CTEs

## What is a Common Table Expression?
> A Common Table Expression (CTE) is a modern SQL feature used to define a
> temporary result set. Conceptually CTEs can also be considered query-level views or
> query-level temporary tables, allowing you to define a transient set of reesults that
> can be used within a larger query.
>
> CTEs primarily serve to simplify complex SQL queries. They can effectively replace nested subqueries, enhancing redability and often improving performance by enabling special CTE specific optimizations for the database's query optimizer.

## Understanding CTE basic syntax
A Common Table Expression starts with the keyword `WITH`, then followed by the CTE name, then `AS`. Following `AS` we have the CTE definition or **CTE Body**.

Here is the general syntax, as implemented in MariaDB.
```sql
WITH [ RECURSIVE ] table_reference [ (columns_list) ] AS (
  SELECT ...
)
[ CYCLE cycle_column_list RESTRICT ]
SELECT ...
```

We'll go into details about the optional keywords, but first let's have a look at the basic case.

### Basic example
Consider the following SQL statement:
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
In this example, we define a CTE called `engineers`, consisting of all employees from the "Engineering" department.
The main `SELECT` statement uses this CTE to filter and retrieve only the engineers earning over 1000.

The equivalent query using traditional SQL, namely subqueries, would be:
```sql
SELECT *
FROM (
  SELECT name, title, salary
  FROM employees
  WHERE dept = 'Engineering'
) AS engineers
WHERE engineers.salary > 1000
```

## Advantages of CTEs in Complex Queries
### Enhanced Readability
Complex SQL queries with multiple nested subqueries can be challenging to interpret as they often require starting from the innermost subqueries and working outwards. This becomes more convoluted with deeper nesting. CTEs, by contrast, offer a more linear and readable structure. Consider the following comparisons:

**Using subqueries**
```sql
SELECT *
FROM (SELECT *
      FROM (SELECT *
            FROM employees
            WHERE dept=”Engineering”) AS engineers                     # Subquery 1
      WHERE engineers.country IN (”NL”, "DE", "FR")) as eu_engineers   # Subquery 2
WHERE ...
```
**Using CTEs**
```sql
WITH engineers AS (                          # First CTE
     SELECT *
     FROM employees
     WHERE dept=”Engineering”
),
eu_engineers AS (                            # Second CTE referencing the first CTE "engineers"
     SELECT *
     FROM engineers
     WHERE country IN (”NL”,...)    
)
SELECT *
FROM eu_engineers
WHERE …
```

Imagine how much more complex this code becomes if those queries get nested a few more level deep.

### Avoiding Repetition
CTEs shine in scenarios where parts of a query need to be reused. Once defined, they are available anywhere within the follow up parts of the query. Consider the case when a query requires a join of the same table twice. If that table is part of a subquery, the subquery must be written twice, or factored out in a VIEW / TEMPORARY TABLE.

**Total sales per year**
Imagine a case where we have to compute the *total volume of sales per product per year". If we had a sales table of the form:
```sql
CREATE TABLE item_sales (product varchar(100), sale_date datetime, price decimal(10, 2));
```
The query would look something like:
```sql
SELECT
    product,
    year(sale_date) as sale_year,
    sum(price)
FROM
    item_sales
GROUP BY
    product, sale_year
```

Now imagine you want to get all the products whose total sales volume has increased since the previous year! With subqueries we'd have to copy paste our query twice and do a join like so:

```sql
SELECT                                    # Table header
    CUR.product,
    CUR.total_amount,
    CUR.sale_year,
    PREV.total_amount,
    PREV.sale_year
FROM
    ( # First subquery defining CUR table for the "current year's sales"
      SELECT                              
          product,
          year(sale_date) as sale_year,
          sum(price) as total_amount
      FROM
          item_sales
      GROUP BY
          product, sale_year) as CUR
      JOIN (  # Second subquery, defining PREV table for the "previous year's sales", same code
          SELECT                             
              product,
              year(sale_date) as sale_year,
              sum(price) as total_amount
          FROM
              item_sales
          GROUP BY
              product, sale_year) as PREV
          ON (  # The join condition between these two tables.
              CUR.product = PREVIOUS.product AND
              CUR.year = PREVIOUS.year + 1
          )
WHERE
    # The filtering condition on which products we are interested in.
    CURRENT.total_amount > PREVIOUS.total_amount
ORDER BY
    CURRENT.product, CURRENT.sale_year
```

Compare this with its CTE equivalent:
```sql
WITH sales_product_year (product, sale_year, total_amount) AS (
    # CTE Body, defined only once.
    SELECT
        product,
        year(sale_date) as sale_year,
        sum(price) as total_amount
    FROM
        item_sales
    GROUP BY
        product, sale_year
)
SELECT 
    CUR.product,
    CUR.total_amount,
    CUR.sale_year,
    PREV.total_amount,
    PREV.sale_year
FROM
    sales_product_year as CUR        # First CTE reference
    JOIN sales_product_year as PREV  # Second CTE reference
    ON (  # The join condition between these two tables.
        CUR.product = PREV.product AND
        CUR.year = PREV.year + 1
    )
WHERE
    # The filtering condition on which products we are interested in.
    CUR.total_amount > PREV.total_amount
ORDER BY
    CUR.product, CUR.sale_year
```

The query using a CTE only has to the define the sales_product_year table once. This also has other benefits, in that the Query Optimizer can now properly see the intent of the programmer: self-join two identical tables. This opens up optimization possibilities such as CTE reuse, which we'll cover in a follow-up chapter.
