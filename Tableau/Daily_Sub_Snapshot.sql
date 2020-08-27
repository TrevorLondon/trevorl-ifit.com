select
        fiscal_calendar.fiscal_year,
        fiscal_calendar.month_start,
        ty_ly_comparison.*
from
(
        select 
            coalesce(ty.date, dateadd(w,52,ly.date))::date as date,
        	CASE WHEN coalesce(ty.user_type,ly.user_type) IN ('Paid','Trial') THEN 'Paid/Trial' ELSE 'Free' END AS user_type1,
            coalesce(ty.user_type,ly.user_type) as user_type2,
            coalesce(ty.membership_type,ly.membership_type) as membership_type,
            coalesce(ty.user_qty,0) as ty_user_qty,
            coalesce(ly.user_qty,0) as ly_user_qty
        from 
            membership_snapshot ty
        full outer join
            membership_snapshot ly ON ly.date = dateadd(w,-52,ty.date) AND ty.membership_type = ly.membership_type and ty.user_type = ly.user_type
) ty_ly_comparison
left join fiscal_calendar on ty_ly_comparison.date between fiscal_calendar.month_start and fiscal_calendar.month_end
