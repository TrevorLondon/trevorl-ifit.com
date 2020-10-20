SELECT users_id as user_id, login__ifit__email, personal__firstname, personal__lastname
FROM prodmongo.users
JOIN (
SELECT * FROM (
SELECT *, LAG(user_type,1) OVER (partition by users_id order by start_date DESC) as new_type
from users__account_history uah
WHERE users_id NOT IN (
        select users_id from new_users
)
)
WHERE user_type = 'Trial' AND new_type = 'Free'
AND CONVERT_TIMEZONE('America/Denver',end_date) BETWEEN '2020-09-30' AND '2020-10-19'
AND is_secondary = 0
) never_paid_users
on users._id = never_paid_users.users_id



SELECT _id as user_id, login__ifit__email, personal__firstname, personal__lastname
FROM (
SELECT *, CASE WHEN days_since_started BETWEEN 82 AND 90 THEN 3
        WHEN days_since_started BETWEEN 52 AND 60 THEN 2
        WHEN days_since_started BETWEEN 22 AND 30 THEN 1
        END AS days_bucket
FROM (
SELECT u._id, login__ifit__email, personal__firstname, personal__lastname, created, DATEDIFF(day,created,GETDATE()) as days_since_started
fROM prodmongo.users u
WHERE created >= GETDATE() - 90
AND u._id NOT IN 
        (SELECT user_id FROM unique_logs) --unique_logs worked
)
)
WHERE days_bucket = 1 -- grab as needed.
