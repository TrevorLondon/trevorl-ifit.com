with base as (
select du.website_user_id,
       du.user_created_date,
       du.user_has_secondary_users,
       convert_timezone('America/Denver', du.user_expiration_date)::DATE as expiration_date_to_date,
       convert_timezone('America/Denver', du.user_expiration_date) as expiration_date_to_seconds,
       (du.user_subscription_type || '/' || du.user_payment_type) as membership_type,
       du.payment_source,
       du.user_qualified_for_autorenewal,
       count(al.activity_log_sk) as workouts
from analytics_warehouse.dim_users du 
left join analytics_warehouse.fact_activity_log al on du.website_user_id = al.website_user_id
where convert_timezone('America/Denver', user_expiration_date)::DATE BETWEEN convert_timezone('America/Denver', GETDATE())
    and DATEADD('week', 1, convert_timezone('America/Denver', GETDATE()))
group by 1,2,3,4,5,6,7,8
)
select *
from base 
where workouts = 0
and membership_type LIKE ('%Yearly%')
and user_qualified_for_autorenewal = 1
order by 5
