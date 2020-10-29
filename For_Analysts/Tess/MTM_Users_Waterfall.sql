-- Tess decided not to have me try to mitigate the issues of the actual event timestamp when the account changed so this goes off of assigned cohort date 
-- Just change the user_group to either be = or <> 'test'

WITH cohort_memb_type AS (
        SELECT tl.*,
               uah.start_date,
               uah.end_date, 
               uah.subscription_set_to,
               uah.payment_set_to,
               uah.user_type
        from tl_mtm_users tl
        LEFT JOIN users__account_history uah on tl.user_id = uah.users_id
                AND tl.orig_2020_renew_date >= uah.start_date::DATE
                AND tl.orig_2020_renew_date < COALESCE(uah.end_date::date,GETDATE())
        WHERE user_group <> 'test'
),
datemapping AS (
        SELECT "date", LAG("date",1) OVER (ORDER BY "date" DESC) as next_day
        FROM datemap
        WHERE "date" BETWEEN '2020-06-18' AND '2020-10-21'
)
SELECT cohort_date,
       "date" as calendar_day_start,
       --cohort_memb_type,
       count(*) as cohort_qty,
       sum(is_retained) as qty_retained
FROM (
SELECT cmt.user_id,
       cmt.orig_2020_renew_date as cohort_date,
       (cmt.subscription_set_to || ' ' || cmt.payment_set_to) as cohort_memb_type,
       d."date",
       d.next_day,
       CASE WHEN uah.user_type <> 'Free' THEN 1 ELSE 0 END AS is_retained
FROM cohort_memb_type cmt
LEFT JOIN datemapping d on cmt.orig_2020_renew_date <= d.next_day
LEFT JOIN users__account_history uah on cmt.user_id = uah.users_id
        AND GREATEST(cmt.start_date,d."date") >= uah.start_date::date
        AND GREATEST(cmt.start_date,d."date") < COALESCE(uah.end_date::date,'2020-10-21')
)
GROUP BY 1,2
ORDER BY 1,2
