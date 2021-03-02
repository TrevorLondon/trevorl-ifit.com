WITH users AS (
SELECT * 
       FROM (
               SELECT * 
               FROM (
                       SELECT uah.users_id,
                              uah.user_type,
                              uah.subscription_set_to,
                              uah.payment_set_to,
                              CASE WHEN u.is_secondary = 1 THEN 1 ELSE 0 END AS secondary,
                              tl.parent_sub_type,
                              ROW_NUMBER() OVER (PARTITION BY uah.users_id ORDER BY start_date DESC) as ord_events
                      FROM users__account_history uah
                      JOIN prodmongo.users u on uah.users_id = u._id 
                      LEFT JOIN tl_primary_secondary_user_map tl on uah.users_id = tl.secondary_user_id
                      )
                WHERE ord_events = 1
              )
WHERE (secondary = 0 AND user_type IN ('Paid', 'Trial'))
OR (secondary = 1 AND parent_sub_type <> 'free')
),
jan_users AS (
SELECT *
FROM (
        SELECT u.users_id,
               CASE WHEN al.duration > 0 AND ws.target_value IS NULL THEN 1
                    WHEN ul.workout_id IS NULL OR ws.title LIKE ('%manual%') THEN 1
                    ELSE 0 
               END AS manual_wkout,
               count(*) as jan_wkout_count
        FROM users u 
        JOIN unique_logs ul on u.users_id = ul.user_id
        JOIN prodmongo.activitylogs al on ul._id = al._id
        LEFT JOIN workout_store.workouts ws on ul.workout_id = ws._id 
        WHERE CONVERT_TIMEZONE('AMERICA/DENVER',ul."start") BETWEEN '2021-01-01' AND '2021-01-31'
        AND manual_wkout = 0
        GROUP BY 1,2
)
WHERE jan_wkout_count >= 12
)
SELECT users_id,
       personal__firstname,
       personal__lastname,
       login__ifit__email
FROM (
        SELECT ju.users_id,
               u.personal__firstname,
               u.personal__lastname,
               u.login__ifit__email,
               CASE WHEN al.duration > 0 AND ws.target_value IS NULL THEN 1
                    WHEN ul.workout_id IS NULL OR ws.title LIKE ('%manual%') THEN 1
                    ELSE 0 
               END AS manual_wkout,
               count(*) as feb_wkout_count
        FROM jan_users ju 
        JOIN prodmongo.users u on ju.users_id = u._id
        JOIN unique_logs ul on ju.users_id = ul.user_id
        JOIN prodmongo.activitylogs al on ul._id = al._id
        LEFT JOIN workout_store.workouts ws on ul.workout_id = ws._id 
        WHERE CONVERT_TIMEZONE('AMERICA/DENVER',ul."start") BETWEEN '2021-02-01' AND '2021-02-28'
        AND manual_wkout = 0
        GROUP BY 1,2,3,4,5
)
WHERE feb_wkout_count >= 12
