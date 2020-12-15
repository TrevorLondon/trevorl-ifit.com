-- These were developed after working through the logic behind the Snowflake data validation (see that file: /Snowflake_validation
-- This one is building a table to encompass the "Get Started" Segments into one place.
-- Will need to check with Kevin on whether he wants to track if/when a User churns out or if one reactivates, etc. 

SELECT u._id as user_id,
       CONVERT_TIMEZONE('AMERICA/DENVER',u.created) as mst_created_date,
       DATEDIFF(day, CONVERT_TIMEZONE('AMERICA/DENVER',u.created), CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE())) AS days_ago,
       first_memb.memb_type as memb_at_creation,
       (u.account__subscription_type || '-' || u.account__payment_type) as current_memb_type,
       MAX(uah.start_date) as current_memb_start_date,
        CASE  WHEN days_ago BETWEEN 1 and 7 THEN 'OPTION 1'
              WHEN days_ago BETWEEN 8 and 14 THEN 'OPTION 2'
              WHEN days_ago BETWEEN 15 and 21 THEN 'OPTION 3'
              WHEN days_ago BETWEEN 22 and 28 THEN 'OPTION 4'
              WHEN days_ago BETWEEN 29 and 35 THEN 'OPTION 5'
              WHEN days_ago BETWEEN 36 and 42 THEN 'OPTION 6'
              WHEN days_ago BETWEEN 43 and 49 THEN 'OPTION 7'
              WHEN days_ago BETWEEN 50 AND 56 THEN 'OPTION 8'
              ELSE 'OTHER'
              END AS days_bucket,
       CASE WHEN (memb_at_creation NOT LIKE ('%free%') AND memb_at_creation NOT LIKE ('%none%'))
                AND (current_memb_type LIKE ('%free%') OR current_memb_type LIKE ('%none%')) THEN 'CHURNED'
            ELSE 'NON-CHURNED'
            END AS churn_check,
       CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE()) AS table_update_local_time
FROM prodmongo.users u
JOIN users__account_history uah on u._id = uah.users_id
JOIN (
    SELECT *,
           (subscription_set_to || '-' || payment_set_to) as memb_type
    FROM (
             SELECT uah.*,
                    ROW_NUMBER() over (PARTITION BY uah.users_id ORDER BY start_date ASC) as ord_events
             FROM users__account_history uah
                      JOIN prodmongo.users u on uah.users_id = u._id
                 AND DATEDIFF(day, CONVERT_TIMEZONE('AMERICA/DENVER', u.created),
                              CONVERT_TIMEZONE('AMERICA/DENVER', GETDATE())) <= 56
             WHERE DATEDIFF(minute, uah.start_date, uah.end_date) > 45
         )
    WHERE ord_events = 1
    ) first_memb
ON u._id = first_memb.users_id
WHERE memb_at_creation NOT LIKE '%free%'
AND memb_at_creation NOT LIKE '%none%'
GROUP BY 1,2,3,4,5,7
LIMIT 500
