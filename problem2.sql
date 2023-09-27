-- Solution:
with ntiles as (
    select
        e.emp_no,
        e.first_name,
        e.last_name,
        s.salary,
        s.from_date,
        d.dept_name,
        ntile(100) over (partition by d.dept_no order by s.salary) n_tile
    from
        salaries s
        join employees e on s.emp_no = e.emp_no
        join dept_emp de on de.emp_no = e.emp_no
        join departments d on d.dept_no = de.dept_no
    where
        s.to_date = '9999-01-01'
)
select emp_no as "Employee Number",
    first_name as "First Name",
    last_name as "Last Name",
    salary as "Current Salary",
    dept_name as "Department Name"
from ntiles
where n_tile = 100
order by dept_name, salary desc;
