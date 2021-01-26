--Ran this mid-month to get Mike counts as of the 25th. Filtered out free users per Mike. Live workouts verified and used logic originally 
-- provided by Garrett and is also what Jeremiah uses. 

WITH live_wkout_users AS (
SELECT user_id, count(*) as wkout_count
from (
SELECT ul.*,
       CASE WHEN al.workout_context IN ('scheduledPre', 'scheduledLive') OR live_workout_schedule_id IS NOT NULL THEN 1 ELSE 0 END AS live_wkout
FROM unique_logs ul
JOIN prodmongo.activitylogs al on ul.user_id = al.user_id
        AND ul._id = al._id
WHERE ul."start"::DATE >= '2021-01-01'
)
where live_wkout = 1
group by 1
)
SELECT CASE WHEN parent_id IS NULL THEN 'primary'
            WHEN parent_id IS NOT NULL THEN 'secondary'
       END AS primary_or_sec,
       user_type,
       count(*)
FROM (
SELECT lwu.*,
       (u.account__subscription_type || ' ' || u.account__payment_type) as memb_type,
       uah.user_type,
       CASE WHEN is_secondary = 1 THEN pcm.parent_id ELSE NULL END AS parent_id,
       CASE WHEN is_secondary = 1 THEN (pcm.parent_sub || ' ' || pcm.parent_pay) ELSE NULL END AS parent_memb
FROM live_wkout_users lwu
JOIN prodmongo.users u on lwu.user_id = u._id
LEFT JOIN (
      SELECT users_id as parent_id,
       u.account__subscription_type as parent_sub,
       u.account__payment_type as parent_pay,
       "user" as child_user,
       map.account__subscription_type as child_sub,
       map.account__payment_type as child_pay,
       status as child_status
    FROM prodmongo.users u
    JOIN (
        select u._id,
        u.account__subscription_type,
        u.account__payment_type,
        ucu.*
    FROM prodmongo.users u
    JOIN prodmongo.users__co_users ucu on u._id = ucu."user"
    WHERE u.is_secondary = 1
        ) map
    on u._id = map.users_id
   ) pcm
ON lwu.user_id = pcm.child_user
LEFT JOIN (
      SELECT * 
      FROM (
      SELECT users_id,
             user_type,
             ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
      FROM users__account_history uah
      )
      WHERE ord_events = 1
   ) uah
on lwu.user_id = uah.users_id
WHERE wkout_count >= 8
)
WHERE (parent_id IS NULl AND memb_type NOT LIKE ('%free%') AND memb_type NOT LIKE ('%none%'))
OR (parent_id IS NOT NULL AND parent_memb NOT LIKE ('%free%') AND parent_memb NOT LIKE ('%none%'))
OR (user_type = 'Trial')
GROUP BY 1,2
