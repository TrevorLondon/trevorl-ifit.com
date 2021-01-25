--Ran this mid-month to get Mike counts as of the 25th. Filtered out free users per Mike. Live workouts verified and used logic originally 
-- provided by Garrett and is also what Jeremiah uses. 

SELECT user_type, count(*)
FROM (
SELECT user_id,
       memb_type,
       subscription_set_to,
       payment_set_to,
       user_type,
       count(*) as wkout_count
from (
SELECT ul.*,
       (u.account__subscription_type || ' ' || u.account__payment_type) as memb_type,
       account_status.subscription_set_to,
       account_status.payment_set_to,
       account_status.user_type,
       CASE WHEN al.workout_context IN ('scheduledPre', 'scheduledLive') OR al.live_workout_schedule_id IS NOT NULL THEN 1 
            ELSE 0 
            END AS live_wkout
FROM unique_logs ul
JOIN prodmongo.activitylogs al on ul.user_id = al.user_id
        AND ul._id = al._id
JOIN prodmongo.users u on ul.user_id = u._id
JOIN (
       SELECT users_id, subscription_set_to, payment_set_to, user_type
       FROM (
                select *, 
                       ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
                from users__account_history 
            )
       WHERE ord_events = 1
     ) account_status
ON ul.user_id = account_status.users_id
AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE >= '2021-01-01'
AND user_type IN ('Paid', 'Trial')
)
where live_wkout = 1
GROUP BY 1,2,3,4,5
)
WHERE wkout_count >= 6
group by 1
