--3000 USERS FROM EACH SEGMENT BELOW --
/* Current Free Trial - No Workout Logged */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM ( 
SELECT login__ifit__email, personal__firstname, personal__lastname, uah.*
FROM users__account_history uah
JOIN prodmongo.users on uah.users_id = users._id
WHERE end_date IS NULL
AND user_type = 'Trial'
AND shipping__country = 'US'
AND users_id NOT IN (
        select user_id from unique_logs
        )
)
limit 3000

/*Current Free Trial - Workout Logged */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM ( 
SELECT login__ifit__email, personal__firstname, personal__lastname, uah.*
FROM users__account_history uah
JOIN prodmongo.users on uah.users_id = users._id
WHERE end_date IS NULL
AND user_type = 'Trial'
AND shipping__country = 'US'
AND users_id IN (
        select user_id from unique_logs
        )
)
limit 3000

/*Paid User in last 90 Days with no Workout */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM ( 
SELECT login__ifit__email, personal__firstname, personal__lastname, uah.*
FROM users__account_history uah
JOIN prodmongo.users on uah.users_id = users._id
WHERE end_date IS NULL
AND user_type = 'Paid'
AND payment_set_to <> 'none'
AND start_date >= GETDATE()::date - 90
AND uah.is_secondary = '0'
AND shipping__country = 'US'
AND users_id NOT IN (
        select user_id from unique_logs
        )
)
limit 3000

/*Recently churned User in last 90 days with previous payment and never done a workout */
SELECT login__ifit__email, personal__firstname, personal__lastname, u1 as user_id
FROM ( 
SELECT c30.*, login__ifit__email, personal__firstname, personal__lastname
from churned_30d c30
JOIN prodmongo.users on c30.u1 = users._id
WHERE old_pay_type IN ('yearly', 'monthly')
AND shipping__country = 'US'
AND u1 NOT IN (
        select user_id from unique_logs
        )
)
LIMIT 3000

/* Paid Users with 20+ Workouts in last 90 Days */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM prodmongo.users
JOIN (
SELECT users_id, user_type, wkouts
FROM (
SELECT * 
FROM (
        SELECT *
        FROM users__account_history
        WHERE end_date IS NULL
        AND user_type = 'Paid'
        AND payment_set_to <> 'none'
        ) paid_users
JOIN (
        SELECT user_id, wkouts 
        FROM (
        select user_id,
                SUM(CASE WHEN start_minute IS NOT NULL THEN 1
                 WHEN start_minute IS NULL THEN 0
                 END) as Wkouts
        FROM unique_logs ul
        WHERE start_minute::date >= '2020-04-28'
        GROUP BY user_id
        )
        GROUP BY user_id, wkouts
        ) ul_wkouts
on paid_users.users_id = ul_wkouts.user_id
)
WHERE wkouts >= 20
) users_wkouts_subset
on users._id = users_wkouts_subset.users_id
ORDER BY random()
LIMIT 3000


/*Paid Users with 5 -10 Workouts in last 90 Days */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM prodmongo.users
JOIN (
SELECT users_id, user_type, wkouts
FROM (
SELECT * 
FROM (
        SELECT *
        FROM users__account_history
        WHERE end_date IS NULL
        AND user_type = 'Paid'
        AND payment_set_to <> 'none'
        ) paid_users
JOIN (
        SELECT user_id, wkouts 
        FROM (
        select user_id,
                SUM(CASE WHEN start_minute IS NOT NULL THEN 1
                 WHEN start_minute IS NULL THEN 0
                 END) as Wkouts
        FROM unique_logs ul
        WHERE start_minute::date >= '2020-04-28'
        GROUP BY user_id
        )
        GROUP BY user_id, wkouts
        ) ul_wkouts
on paid_users.users_id = ul_wkouts.user_id
)
WHERE wkouts BETWEEN 6 AND 10
) users_wkouts_subset
on users._id = users_wkouts_subset.users_id
ORDER BY random()
LIMIT 3000

/*Paid Users with 1-5 Workouts in Last 90 Days */
SELECT login__ifit__email, personal__firstname, personal__lastname, users_id
FROM prodmongo.users
JOIN (
SELECT users_id, user_type, wkouts
FROM (
SELECT * 
FROM (
        SELECT *
        FROM users__account_history
        WHERE end_date IS NULL
        AND user_type = 'Paid'
        AND payment_set_to <> 'none'
        ) paid_users
JOIN (
        SELECT user_id, wkouts 
        FROM (
        select user_id,
                SUM(CASE WHEN start_minute IS NOT NULL THEN 1
                 WHEN start_minute IS NULL THEN 0
                 END) as Wkouts
        FROM unique_logs ul
        WHERE start_minute::date >= '2020-04-28'
        GROUP BY user_id
        )
        GROUP BY user_id, wkouts
        ) ul_wkouts
on paid_users.users_id = ul_wkouts.user_id
)
WHERE wkouts BETWEEN 1 AND 5
) users_wkouts_subset
on users._id = users_wkouts_subset.users_id
ORDER BY random()
LIMIT 3000
