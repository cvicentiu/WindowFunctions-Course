# How to set up the environment:

1. Clone the following repository to get the dataset:

```
mkdir course
cd course
git clone https://github.com/datacharmer/test_db.git
```
2. Start a MariaDB instance in the `course` folder.

```
docker run -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=TRUE -v ./test_db:/test_db/ --rm --name mariadb_database -it mariadb:latest
```

3. In a separate terminal run the following command to load the data.

```
docker exec -i mariadb_database bash -c "cd /test_db && mariadb < /test_db/employees.sql"
```

4. Start an SQL session in the container with:

```
docker exec -it mariadb_database mariadb employees
```

# Problems to solve:

1. Given the employees dataset, identify the top 1% of earners that are
   currently employed. A currently employed employee has the `to_date` column
   corresponding to their salary set to `9999-01-01`.

   The result should have the following table header and it should be sorted by
   `salary` descending:

   `Employee Number, First Name, Last Name, Current Salary`

   Hint: [NTILE](https://mariadb.com/kb/en/ntile/)

2. Same task as problem #1, however group by departments and get the top 1% per
   each department.

   The result should have the following table header and it
   should be sorted by `salary` descending:

   `Employee Number, First Name, Last Name, Current Salary, Department Name`

   Hint: [PARTITION BY clause](https://mariadb.com/kb/en/window-functions-overview/#syntax)

3. Same task as problem #2, however only get the top 5 earners per each
   department.

   The result should have the following table header and it should be sorted by
   `salary` descending:

   `Employee Number, First Name, Last Name, Current Salary, Department Name`

   Hint: [RANK](https://mariadb.com/kb/en/rank/)

4. Identify the largest absolute raise in the company. A raise is defined as
   the difference between two salary entries such that:

   `entry1.emp_no = entry2.emp_no and entry1.to_date = entry2.from_date`.

   The result should have the following table header:

   `Employee Number, First Name, Last Name, Maximum Raise`

   Do this without the use of window functions.

   Hint: A table self-join is necessary.

5. Same as problem #4.

   Use the [LAG](https://mariadb.com/kb/en/lag/) window function to solve this
   problem.

   Compare the performance difference between #4 and #5. Which one is faster?
   Why?

## Solutions:
* [Problem 1](problem1.sql)
* [Problem 2](problem2.sql)
* [Problem 3](problem3.sql)
* [Problem 4](problem4.sql)
* [Problem 5](problem5.sql)
