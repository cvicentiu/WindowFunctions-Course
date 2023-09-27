-- Solution:
with ntiles as (
    select
        e.emp_no,
        e.first_name,
        e.last_name,
        s.salary,
        s.from_date,
        ntile(100) over (order by salary) n_tile
    from
        salaries s
    join employees e on s.emp_no = e.emp_no
    where
        s.to_date = '9999-01-01'
)
select
    emp_no as "Employee Number",
    first_name as "First Name",
    last_name as "Last Name",
    salary as "Current Salary"
from ntiles
where n_tile = 100
order by salary desc;
