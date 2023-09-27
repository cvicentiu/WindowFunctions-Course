-- Solution:
with ranks as (
    select
        e.emp_no,
        e.first_name,
        e.last_name,
        s.salary,
        s.from_date,
        d.dept_name,
        rank() over (partition by d.dept_no order by s.salary desc) emp_rank
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
    dept_name as "Department Name",
    emp_rank as "Employee Rank"
from ranks
where emp_rank <= 5
order by dept_name, salary desc;
