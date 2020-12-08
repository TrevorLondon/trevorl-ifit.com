-- This was generated for Mike, Kelsey, Emily, and Tracy to provide to a 3rd party UX design firm. Needed Users that avg a set amount of workouts per week for the 
-- last 6 months. Per Mike, this was only paid members with Live, Video, or Map workouts. 

WITH user_set AS (
    SELECT *
    FROM (
             SELECT user_id,
                    memb_type,
                    AVG(wkout_count) as wkout_avg
             FROM (
                      SELECT user_id,
                             DATE_TRUNC('week', "start") as wkout_week,
                             memb_type,
                             COUNT(*)                    as wkout_count
                      FROM (
                               SELECT ul.user_id,
                                      (u.account__subscription_type || '-' || u.account__payment_type) as memb_type,
                                      CASE
                                          WHEN al.workout_context IN ('scheduledPre', 'scheduledLive') THEN 'LIVE'
                                          WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
                                          WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
                                          WHEN al.duration > 0 AND ws.target_value IS NULl THEN 'MANUAL'
                                          ELSE 'OTHER'
                                          END                                                          AS workout_type,
                                      ul."start"
                               FROM unique_logs ul

                                        JOIN prodmongo.users u on ul.user_id = u._id
                                        JOIN prodmongo.activitylogs al on ul._id = al._id
                                        JOIN workout_store.workouts ws on ul.workout_id = ws._id
                               WHERE DATEDIFF(month, ul."start", GETDATE()) <= 6
                           )
                      WHERE memb_type <> 'free-none'
                        AND workout_type <> 'MANUAL'
                      GROUP BY 1, 2, 3
                  )
             GROUP BY 1, 2
         )
    WHERE wkout_avg >= 5  --Change this desired avg wkouts/week
)
SELECT user_id,
       personal__firstname,
       personal__lastname,
       login__ifit__email
FROM (
         SELECT us.*,
                (uah.subscription_set_to || '-' || uah.payment_set_to) as memb_check,
                uah.user_type,
                u.personal__firstname,
                u.personal__lastname,
                u.login__ifit__email
         FROM user_set us
         JOIN prodmongo.users u on us.user_id = u._id
              AND COALESCE(u.personal__country,u.shipping__country,u.billing__country) IN ('US','USA')
         JOIN users__account_history uah on us.user_id = uah.users_id
             AND uah.end_date IS NULL
     )
ORDER BY RANDOM()
LIMIT 300
