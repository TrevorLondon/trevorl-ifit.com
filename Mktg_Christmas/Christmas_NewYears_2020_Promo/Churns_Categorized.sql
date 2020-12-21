-- This attempts to categorize "churns" based off of UA types and readables and lumps them into "vol" (cancelled) vs "inv" (billing churn) vs other

WITH users_churn_groups AS (
    SELECT *
    FROM (
             SELECT *,
                    CASE
                        WHEN "type" = 'autoDowngrade' THEN
                            CASE
                                WHEN readable LIKE ('%request%') THEN 'VOL'
                                WHEN readable LIKE ('%expire%') THEN 'INV'
                                WHEN readable LIKE ('%2017 Memorial Day%') THEN '2017 Mem Day'
                                WHEN readable LIKE ('%fraud%') THEN 'Fraud'
                                ELSE 'OTHER'
                                END
                        WHEN "type" IN ('downgradeFromRequest', 'adminMembershipChange', 'downgradeRequested',
                                        'adminMembershipChangeRequest',
                                        'adminMembershipCancel', 'pauseMembership') THEN 'VOL'
                        ELSE 'INV'
                        END AS churn_type,
                    CASE
                        WHEN DATEDIFF(day, start_date, GETDATE()) < 30 THEN '1'
                        WHEN DATEDIFF(day, start_date, GETDATE()) BETWEEN 30 AND 180 THEN '2'
                        WHEN DATEDIFF(day, start_date, GETDATE()) >= 180 THEN '3'
                        ELSE 'OTHER'
                        END AS churn_bucket
             FROM (
                      SELECT *,
                             ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY created DESC) as ord_ua
                      from (
                               WITH churned_users AS (
                                   SELECT users_id,
                                          country,
                                          start_date,
                                          end_date,
                                          (subscription_set_to || ' ' || payment_set_to) as memb_type,
                                          user_type,
                                          (prev_sub_type || ' ' || prev_pay_type)        as prev_memb_type,
                                          prev_user_type
                                   FROM (
                                            SELECT *
                                            FROM (
                                                     SELECT *,
                                                            ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
                                                     FROM (
                                                              SELECT uah.*,
                                                                     LAG(subscription_set_to, 1)
                                                                     OVER (PARTITION BY users_id ORDER BY start_date)                        as prev_sub_type,
                                                                     LAG(payment_set_to, 1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_pay_type,
                                                                     LAG(user_type, 1) OVER (PARTITION BY users_id ORDER BY start_date)      as prev_user_type,
                                                                     COALESCE(u.personal__country, u.billing__country,
                                                                              u.shipping__country)                                           as country
                                                              FROM users__account_history uah
                                                                       JOIN prodmongo.users u on uah.users_id = u._id
                                                              WHERE u.is_secondary = 0
                                                                AND uah.is_secondary = 0
                                                                AND (DATEDIFF(minute, start_date, end_date) > 20 OR end_date IS NULL)
                                                          )
                                                 )
                                            WHERE ord_events = 1
                                        )
                                   WHERE user_type = 'Free'
                                     AND end_date IS NULL
                                     AND prev_user_type IN ('Paid', 'Trial')
                                     AND (country IN ('US', 'USA') OR country IS NULL)
                                     --AND country NOT IN ('US', 'USA')
                                     --AND country IS NOT NULL
                               )
                               SELECT cu.*,
                                      ua.created,
                                      ua.type,
                                      ua.readable
                               FROM churned_users cu
                                        LEFT JOIN prodmongo.useractivities ua on cu.users_id = ua.user_id
                                   AND
                                                                                 ua.created BETWEEN cu.start_date - INTERVAL '13 days' AND cu.start_date + INTERVAL '1 day'
                               WHERE ua.type <> 'billingCleared'
                           )
                      WHERE "type" IN ('downgradeRequested',
                                       'amazonDeactivation',
                                       'adminMembershipChange',
                                       'canceledMembershipChangeRequest',
                                       'yearlyFailedAutoRenewal',
                                       'autoDowngrade',
                                       'pauseMembership',
                                       'downgradeFromRequest',
                                       'monthlyFailedAutoRenewal',
                                       'failedOrder',
                                       'yearlySkippedAutoRenewal',
                                       'adminMembershipCancel')
                  )
             WHERE ord_ua = 1
         )
    WHERE churn_bucket = 3
      AND churn_type = 'INV'
)
SELECT ucg.users_id,
       u.login__ifit__email as email,
       u.personal__firstname,
       u.personal__lastname
FROM users_churn_groups ucg
JOIN prodmongo.users u on ucg.users_id = u._id
