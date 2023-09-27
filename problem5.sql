with raises as (
    select
        e.emp_no,
        e.first_name,
        e.last_name,
        s.salary -
        lag(s.salary, 1) over (partition by e.emp_no order by s.from_date) as raise
    from
        salaries s
        join employees e on e.emp_no = s.emp_no
    order by 4 desc
)
select
    r.emp_no as "Employee Number",
    r.first_name as "First Name",
    r.last_name as "Last Name",
    r.raise as "Maximum Raise"
from raises as r
limit 1; -- no need to order by raise again as raises is already sorted.

-- Runtime for this solution should be ~half of runtime for problem4 solution.
