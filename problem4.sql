with raises as (
    select
        e.emp_no,
        e.first_name,
        e.last_name,
        max(s_curr.salary - s_prev.salary) as raise
    from
        salaries s_prev
        join salaries s_curr on s_curr.emp_no = s_prev.emp_no and s_prev.to_date = s_curr.from_date
        join employees e on e.emp_no = s_curr.emp_no
    group by
        e.emp_no, e.first_name, e.last_name
    order by raise desc
)
select
    r.emp_no as "Employee Number",
    r.first_name as "First Name",
    r.last_name as "Last Name",
    r.raise as "Maximum Raise"
from raises as r
limit 1; -- no need to order by raise again as raises is already sorted.

