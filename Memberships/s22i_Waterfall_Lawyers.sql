--First block is the code that created the table to use for the bottom block final output
create table public.tl_s22i_users AS (
SELECT * FROM 
(
WITH users AS (
select distinct(ul.user_id), software_number, MIN(ul."start") as first_workout
        --row_number() over (partition by ul.user_id order by "start") as ord_events
from unique_logs ul
where ul.software_number IN ('392570', '425738', '426458')
group by 1,2
)
select users.user_id, 
       users.first_workout,
       nu.mst_membership_start_date as first_paid_date, 
       oum.software_number as oldest_machine, 
       users.software_number as ul_software_number,
       u.is_secondary as user_is_secondary,
       CASE WHEN oldest_machine <> ul_software_number THEN 'New_Bike'
        WHEN oldest_machine = ul_software_number THEN 'Old_Bike'
        ELSE 'Other'
        END AS equip_factor
from users
JOIN prodmongo.users u on users.user_id = u._id
left JOIN new_users nu on users.user_id = nu.users_id
left JOIN oldest_user_machines oum on users.user_id = oum.users_id
WHERE u.is_secondary = 0
AND oldest_machine <> ul_software_number 
) user_set
LEFT JOIN users__account_history uah on user_set.user_id = uah.users_id
        AND user_set.first_workout >= uah.start_date
        AND user_set.first_workout < coalesce(uah.end_date,getdate())
         --523 Users Ole Machine from Memorial Day Promo,etc.
)

--Once that table is built/updated, you can then run this 

SELECT cohort,
       calendar_month_start,
       cohort_memb_type,
       count(*) as cohort_qty,
       sum(is_retained) as qty_retained
FROM (
SELECT user_id,
       DATE_TRUNC('month',pre_waterfall_set.cohort)::date as cohort,
       CASE WHEN cohort = first_paid_date THEN pre_waterfall_set.subscription_set_to || ' ' || pre_waterfall_set.payment_set_to
       WHEN cohort = next_start THEN pre_waterfall_set.next_sub || ' ' || pre_waterfall_set.next_pay
       WHEN cohort = first_workout THEN pre_waterfall_set.subscription_set_to || ' ' || pre_waterfall_set.payment_set_to
       WHEN cohort = pre_waterfall_set.start_date THEN pre_waterfall_set.subscription_set_to || ' ' || pre_waterfall_set.payment_set_to
       END AS cohort_memb_type,
       fc.calendar_month_start,
       uah.subscription_set_to,
       uah.payment_set_to,
       uah.user_type,
       CASE WHEN uah.user_type <> 'Free' THEN 1 ELSE 0 END as is_retained
FROM (
WITH users_next AS (
SELECT tl.*, nu.subscription_set_to, nu.payment_set_to
from tl_s22i_users tl
join new_users nu on tl.user_id = nu.users_id
WHERE tl.user_type = 'Free'
AND end_date <> first_paid_date
),
users_next_full AS (
SELECT * FROM (
SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY next_start ASC) as row_num
FROM (
select un.*, 
        LAG(uah.start_date,1) OVER (partition by uah.users_id order by uah.start_date) as next_start,
        LAG(uah.subscription_set_to,1) OVER (partition by uah.users_id order by uah.start_date) as next_sub,
        LAG(uah.payment_set_to,1) OVER (PARTITION BY uah.users_id order by uah.start_date) as next_pay
FROM users_next un
JOIN users__account_history uah on un.user_id = uah.users_id
        AND uah.start_date >= un.end_date
)
)
WHERE row_num = 1
)
SELECT tl.*, unf.next_start, unf.next_sub, unf.next_pay,
        CASE WHEN tl.user_type = 'Free' AND tl.end_date::date = tl.first_paid_date::date THEN tl.first_paid_date
        WHEN tl.user_type = 'Free' AND tl.end_date::date <> tl.first_paid_date::date AND tl.end_date IS NOT NULL THEN COALESCE(unf.next_start,GREATEST(tl.first_paid_date,tl.first_workout))
        WHEN tl.user_type = 'Free' AND tl.end_date IS NULL THEN tl.first_workout
        WHEN tl.user_type <> 'Free' THEN tl.start_date
        ELSE tl.first_workout
        END as cohort
FROM tl_s22i_users tl
LEFT JOIN users_next_full unf on tl.user_id = unf.user_id
) pre_waterfall_set
LEFT JOIN fiscal_calendar fc on pre_waterfall_set.cohort::date <= fc.calendar_month_end
        AND fc.calendar_month_start < CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE())::DATE
LEFT JOIN users__account_history uah on pre_waterfall_set.user_id = uah.users_id
        AND GREATEST(CONVERT_TIMEZONE('America/Denver',pre_waterfall_set.start_date),fc.calendar_month_start) 
	>= CONVERT_TIMEZONE('America/Denver',uah.start_date) 
	and GREATEST(CONVERT_TIMEZONE('America/Denver',pre_waterfall_set.start_date),fc.calendar_month_start) 
	< COALESCE(CONVERT_TIMEZONE('America/Denver',uah.end_date),CONVERT_TIMEZONE('America/Denver',GETDATE()))
)
GROUP BY 1,2,3
ORDER BY 1,2
