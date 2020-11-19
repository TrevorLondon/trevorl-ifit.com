-- CHURN DEFINED AS NON-REQUESTED DOWNGRADE AND CANCELLED IS THE INVERSE. THIS BUILDS OUT THOSE SEGMENTS BY UPDATING:
-- 1- LINE 34: DOMESTIC VS INT'L
-- 2 - LINE 64: "CHURN BUCKET" (SEE LINES 11-14)
-- 3 - LINE 67: "DOWNGRADE REQUESTED". IF = 1 THEN THIS IS THE "CANCELLED" GROUP, ELSE 0 = CHURNED. 


WITH churned_users_events AS (
SELECT users_id,
       personal__firstname,
       personal__lastname,
       login__ifit__email,
       start_date,
       days_since_churned,
       CASE WHEN days_since_churned BETWEEN 0 AND 90 THEN 'group_1'
            WHEN days_since_churned BETWEEN 91 AND 180 THEN 'group_2'
            WHEN days_since_churned BETWEEN 181 AND 360 THEN 'group_3'
            END AS churn_buckets
FROM (
SELECT users_id, personal__firstname, personal__lastname, login__ifit__email, start_date, end_date, mst_start,
       DATEDIFF('day',mst_start,GETDATE()) as days_since_churned
FROM (
select uah.*, LAG(subscription_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_memb_type,
        LAG(payment_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_payment_type,
        LAG(user_type,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_user_type,
        CONVERT_TIMEZONE('AMERICA/DENVER',uah.start_date) as mst_start,
        CASE WHEN (COALESCE(u.personal__country, u.shipping__country, u.billing__country) IN ('US', 'USA') 
                OR COALESCE(u.personal__country, u.shipping__country, u.billing__country) IS NULL) THEN 1 ELSE 0 END as domestic_user,
        u.personal__firstname,
        u.personal__lastname,
        u.login__ifit__email
from users__account_history uah
JOIN prodmongo.users u on uah.users_id = u._id
)
WHERE CONVERT_TIMEZONE('America/Denver',start_date)::date >= CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE()) - 361
AND user_type = 'Free' and prev_user_type = 'Paid'
AND prev_payment_type <> 'none'
AND is_secondary = 0
AND domestic_user = 0 --CHANGE THIS TO 1 OR 0, DEPENDING ON IF YOU WANT DOMESTIC OR INT'L USERS
AND end_date IS NULL
)
),
downgrade_requested_users AS (
SELECT cue.*,
       ua."type",
       ua.readable
from churned_users_events cue
LEFT JOIN prodmongo.useractivities ua on cue.users_id = ua.user_id
        AND ua.created BETWEEN cue.start_date - INTERVAL '5 minute' AND cue.start_date + INTERVAL '5 minute'
WHERE ua."type" IN ('downgradeFromRequest', 'downgradeRequested')
OR (ua."type" = 'autoDowngrade' AND ua.readable LIKE ('%request%'))
)
SELECT login__ifit__email, personal__firstname, personal__lastname

FROM (
SELECT cue.users_id,
       cue.start_date,
       cue.days_since_churned,
       cue.churn_buckets,
       CASE WHEN cue.users_id IN (SELECT DISTINCT(users_id) FROM downgrade_requested_users) THEN 1 ELSE 0 END AS downgrade_requested,
       u.login__ifit__email,
       u.personal__firstname,
       u.personal__lastname
FROM churned_users_events cue
LEFT OUTER JOIN downgrade_requested_users dru on cue.users_id = dru.users_id
        AND cue.start_date = dru.start_date
JOIN prodmongo.users u on cue.users_id = u._id
WHERE cue.churn_buckets = 'group_3' --UPDATE THIS TO PULL WHICH CHURN BUCKET YOU WANT TO PULL 
)
WHERE downgrade_requested = 1



