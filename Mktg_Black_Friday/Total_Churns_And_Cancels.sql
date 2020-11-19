--USED THIS AS A CHECK TO ASSURE THE TOTAL CANCELS + CHURNS (FROM THE OTHER SCRIPT) EQUALS THIS AGG COUNT
-- DOMESTIC = US, USA, AND NULL VALUES 
-- WOULD ONLY NEED TO CHANGE LINE 35 TO SWITCH BETWEEN DOMESTIC VS INT'L

SELECT churn_buckets, count(*)
FROM (
SELECT personal__firstname,
       personal__lastname,
       login__ifit__email,
       days_since_churned,
       CASE WHEN days_since_churned BETWEEN 0 AND 90 THEN 'group_1'
            WHEN days_since_churned BETWEEN 91 AND 180 THEN 'group_2'
            WHEN days_since_churned BETWEEN 181 AND 360 THEN 'group_3'
            END AS churn_buckets
FROM (
SELECT personal__firstname, personal__lastname, login__ifit__email, start_date, end_date, mst_start,
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
AND domestic_user = 1
AND end_date IS NULL
)
)
GROUP BY 1
