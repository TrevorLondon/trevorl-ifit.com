-- First Block is Users grouped into days since creation buckets, that are <= 56 days since creation, and NOT FREE (Paid and Trial)
SELECT days_bucket,
       COUNT(*)
FROM (
        SELECT _id AS user_id,
               account__subscription_type,
               account__payment_type,
               DATEDIFF(day, created, GETDATE()) as days_ago,
               CASE  WHEN days_ago BETWEEN 1 and 7 THEN 'OPTION 1'
                      WHEN days_ago BETWEEN 8 and 14 THEN 'OPTION 2'
                      WHEN days_ago BETWEEN 15 and 21 THEN 'OPTION 3'
                      WHEN days_ago BETWEEN 22 and 28 THEN 'OPTION 4'
                      WHEN days_ago BETWEEN 29 and 35 THEN 'OPTION 5'
                      WHEN days_ago BETWEEN 36 and 42 THEN 'OPTION 6'
                      WHEN days_ago BETWEEN 43 and 49 THEN 'OPTION 7'
                      WHEN days_ago BETWEEN 50 AND 56 THEN 'OPTION 8'
                      ELSE 'OTHER'
                      END AS days_bucket
        FROM prodmongo.users
        where DATEDIFF(day,created,GETDATE()) <= 56
        AND (account__subscription_type <> 'free' 
        OR account__payment_type <> 'none')
)
GROUP BY 1

-- This second block is COACH-PLUS YEARLY AND MONTHLY USERS THAT ARE <= 90 DAYS SINCE CREATION, AND HAVE NO SECONDARY USERS
SELECT COUNT(*)
FROM (
         SELECT u._id                    as user_id,
                account__subscription_type,
                account__payment_type,
                COUNT(DISTINCT ucu.user) as secondary_users
         FROM prodmongo.users u
                  LEFT JOIN prodmongo.users__co_users ucu on u._id = ucu.users_id
         WHERE DATEDIFF(day, created, GETDATE()) <= 90
           AND account__subscription_type = 'coach-plus'
           AND account__payment_type <> 'none'
         GROUP BY 1, 2, 3
     )
WHERE secondary_users = 0

-- This third block is non-FREE Users that were created <= 90 days ago, and have never done a live workout
SELECT count(distinct user_id)
         FROM (
                  SELECT u._id as                                                            user_id,
                         (u.account__subscription_type || '-' || u.account__payment_type) as memb_type,
                         SUM(CASE
                                 WHEN al.workout_context IN ('scheduledPre', 'scheduledLive') THEN 1
                                 ELSE 0 END) as                                              live_workout
                  FROM prodmongo.users u
                           JOIN prodmongo.activitylogs al on u._id = al.user_id
                  WHERE DATEDIFF(day, u.created, GETDATE()) <= 90
                  group by 1, 2
              )
WHERE live_workout = 0
AND memb_type NOT LIKE ('%free%')
AND memb_type NOT LIKE ('%none%')

--Fourth block here is Paid, FT, or Secondary Users that have logged a workout under one of the equipment types
-- Can be in multiple equipment segments
WITH user_set AS (
    SELECT _id as user_id,
           created,
           account__subscription_type,
           account__payment_type
    FROM prodmongo.users
    WHERE DATEDIFF(day,created,GETDATE()) <= 90
    AND (account__subscription_type <> 'free' AND account__payment_type <> 'none')
)
SELECT equipment_type, count(DISTINCT user_id)
FROM (
SELECT us.*,
       sc.equipment_type
FROM user_set us
JOIN unique_logs ul on us.user_id = ul.user_id
LEFT JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
WHERE equipment_type IN ('Treadmill', 'Bike', 'Elliptical', 'Strider', 'Rower')
)
GROUP BY 1
