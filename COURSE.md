# CTEs

## What is a Common Table Expression?
> A Common Table Expression (CTE) is a modern SQL feature used to define a
> temporary result set. Conceptually CTEs can also be considered query-level views or
> query-level temporary tables, allowing you to define a transient set of results that
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

The query using a CTE only has to define the sales_product_year table once. This also has other benefits, in that the Query Optimizer can now properly see the intent of the programmer: self-join two identical tables. This opens up optimization possibilities such as CTE reuse, which we'll cover in a follow-up chapter.

## CTE Execution
Now that we understand what a CTE is and what it's useful for, it's time to look at how the database computes queries that use CTEs. While the next chapter is not essential for making use of CTEs, understanding what optimizations the database engine can do will help you write better performing queries.  

Without considering any query optimizations, conceptually, the database creates a temporary table for each CTE reference. When the query starts, the database goes through the following steps:
1. Identifies all CTE declarations.
2. Identifies all references of CTEs within the query.
3. For each CTE referenced within the query, the database computes the results of its CTE body select. Note that this works when CTEs reference other CTEs. The database starts with the CTEs that have no other CTEs references first.

When writing queries, you can rely on this computation model as it is generally valid. However, an astute reader may observe the potential for plenty of optimizations. There are different strategies the query optimizer can employ, which is what we'll cover next:

## CTE Optimizations

### CTE reuse

The computation model presented above means that if a CTE is referenced multiple times, it has to be computed multiple times. This is obviously inneficient if we can reuse the data.

The following figure shows the "naive" execution compared to reusing CTEs.

![CTE Reuse](./img/CTE-Reuse.png)
With the naive execution plan, the green (cte1 a) and yellow (cte1 b) are identical and get computed twice. The alternative execution plan only computes cte1 once, then the two references use the same storage to execute the query.

**Advantages**
* Easy to implement within the database engine
* Computation work is not duplicated.
* Can speed up query execution

**Disadvantages**
* Chosing CTE reuse as an optimization prevents other optimizations.
* Often there are better strategies to reduce the amount of rows that need to be computed.

### CTE merging
CTEs are very similar to subqueries behind the scenes. A subquery is used to define a query level temporary table, also called a DERIVED TABLE. For certain queries, the optimizer is able to rewrite them by *merging* where clauses together to allow for more filtering conditions to apply sooner. The same rules apply to CTEs as well.

The following figure shows the transformation that the optimizer will do:

![CTE Merging](./img/CTE-Merging.png)

This optimization is called CTE Merging

The optimizer knows to optimize derived tables by rewriting the query whenever possible. By doing merging, the following optimization steps have a more straightforward view of the query. This allows the JOIN optimizer (the optimization step deciding on the JOIN order of tables) to make a better cost-based decision. In almost all cases, CTE merging provides a performance speedup, hence the optimizer in MariaDB will always attempt to do merging before any other optimization steps. 

### CTE condition pushdown
There are cases when CTE merging is not possible, because it would change the end outcome of the query. Here is an example:
```sql
WITH sales_per_year AS (
  SELECT
    year(order.date) AS year
    sum(order.amount) AS sales
  FROM
    order
  GROUP BY  -- !!! Group by is present in the CTE !!!
    year
)
SELECT * 
FROM sales_per_year 
WHERE 
  year in ('2015','2016')
```

In the general case, any GROUP BY clause in a CTE prevents direct merging. However there is still a way to optimize the query by identifying any filtering clauses refering to the GROUP BY expression. The key here is the filtering condition:
```sql
WHERE
  year in ('2015', '2016')
```
Instead of computing all groups in the CTE, storing them in a temporary table and only then identifying the groups `2015` and `2016`, one can begin filtering the `order` table directly.
The resulting query, as executed by the optimizer is:
```sql
WITH sales_per_year AS (
  SELECT
    year(order.date) AS year
    sum(order.amount) AS sales
  FROM
    order
  WHERE  -- Where clause is now added to the CTE
    order.year in ('2015', '2016')
  GROUP BY  
    year
)
SELECT * 
FROM sales_per_year 
```

## Recursive CTEs
The previous chapters dealt with the execution of regular CTEs. Now it is time to introduce a more advanced concept for CTEs, *recursion*. With recursive CTEs, one can define complex semantics to compute almost anything. The most common use case however is graph traversal. Let's start with the basic syntax:

```sql
WITH RECURSIVE <cte-name> as (
  <base-select>
  union
  <recursive-select>
)
```

You will notice the extra `RECURSIVE` keyword. A recursive CTE is split into a union of two clauses, a "base" case, defining the initial dataset, then a recursive generator. The recursive generator will execute for as long as new rows can be generated based on the results of the previous iteration. This is harder to explain in plain text, so the following animation will show how a CTE is constructed. 

TODO: video

This covers all the topics related to Common Table Expressions. Next we will dive into another advanced SQL feature, that works well in conjuction with what we've learned so far.

## Window Functions
Window functions are a special kind of SQL function. Window functions can be used in regular SELECT queries and they have the following two particularities:
1. They behave as regular SQL functions, they return one result per row.
2. They behave also like aggregate functions such as `MIN`, `MAX`, `AVG`. The result of window functions is computed over multiple rows. In fact, most aggregate functions can be used as window functions too!

### Syntax

```yaml
<function-name>(<expression>) OVER (
  [PARTITION BY <expression_list>]
  [ORDER BY <order_list> [frame_clause]])

expression_list:
  {expression | column_name} [, expression_list]

order_list:
  {expression | column_name} [ASC | DESC] [, order_list]

frame_clause:
  { ROWS | RANGE } {frame_border | BETWEEN frame_border AND frame_border}

frame_border:
    UNBOUNDED PRECEDING
  | UNBOUNDED FOLLOWING
  | CURRENT ROW
  | expression PRECEDING
  | expression PRECEDING
```

Let's go through the syntax, one step at a time:
1. The `OVER ()` clause is the bare minimum required to define a window function. This tells the SQL engine that this function will produce one result per row, but that its values will be computed over potentially many different rows. If the used function was traditionally a regular aggregate function, such as `SUM` or `COUNT`, it will now behave as a window function. It will not collapse group rows into a single result.
2. Inside the `OVER` clause one can add modifiers that impact what rows will be used to compute the window function's result. The rows used to compute a window function result are part of the "window frame". The modifiers affect the rows that are part of the "window frame". They are: `PARTITION BY` and `ORDER BY`. We'll go into more concrete examples for each.
3. Finally, one can specify how big the window frame is, in relation to the current row we are computing the window function result for. This is done via the `frame_clause` part of the grammar.

### Dedicated window function use case row_number()

### Aggregate functions as window functions

### Different frame clauses

#### ROWS vs RANGE

### Where can window functions be used

#### How to combine window functions with CTEs
