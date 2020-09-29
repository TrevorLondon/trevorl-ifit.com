-- Ran this first dataset to pull Trial Users that never converted to paid with their TRials ending on or after 01/01/2020. 
-- Building an automation script on this same general logic of people that have downgraded to free in the last 2 weeks from a Trial

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
AND CONVERT_TIMEZONE('America/Denver',end_date) >= '2020-01-01'
AND is_secondary = 0
) never_paid_users
on users._id = never_paid_users.users_id
