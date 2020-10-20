SELECT month_start as cohort, calendar_month_start, origin, 
        first_sub as cohort_sub,
        first_pay as cohort_pay,
        count(*) as cohort_qty,
        sum(is_retained) as qty_retained,
        sum(workouts_started) as workouts_started
FROM (
SELECT tl.*, nu.fiscal_year, nu.month_start, nu.subscription_set_to as first_sub, nu.payment_set_to as first_pay, nu.origin, 
        u.created::date as ifit_creation, fc.calendar_month_start, uah.subscription_set_to, uah.payment_set_to, uah.user_type,
        CASE WHEN user_type <> 'Free' THEN 1 ELSE 0 END as is_retained,
        SUM(CASE WHEN ul._id IS NOT NULL THEN 1 ELSE 0 END) as workouts_started
from tl_mtm_users tl
join prodmongo.users u on tl.user_id = u._id
left join new_users nu on tl.user_id = nu.users_id
left join fiscal_calendar fc on nu.mst_membership_start_date::date <= fc.calendar_month_end
        AND fc.calendar_month_start < CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE())::DATE
left join users__account_history uah on nu.users_id = uah.users_id
        AND GREATEST(CONVERT_TIMEZONE('AMERICA/DENVER',nu.utc_membership_start_date),fc.calendar_month_start)
                >= CONVERT_TIMEZONE('AMERICA/DENVER',uah.start_date)
        AND GREATEST(CONVERT_TIMEZONE('AMERICA/DENVER',nu.utc_membership_start_date),fc.calendar_month_start)
                < COALESCE(CONVERT_TIMEZONE('AMERICA/DENVER',uah.end_date),CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE()))
left join unique_logs ul on nu.users_id = ul.user_id
        AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE BETWEEN fc.calendar_month_start AND fc.calendar_month_end
WHERE tl.user_group = 'test'
AND nu.fiscal_year >= 19
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
)
GROUP BY 1,2,3,4,5
