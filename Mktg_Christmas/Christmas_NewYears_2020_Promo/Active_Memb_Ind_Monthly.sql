--This is ONLY for Ind Monthly - both for US and Foreign (change that part)

WITH user_base AS (
    SELECT user_id,
           email,
           personal__firstname,
           personal__lastname,
           (account__subscription_type || ' ' || account__payment_type) as memb_type
    FROM (
             SELECT u._id                                                                  AS user_id,
                    u.login__ifit__email                                                   as email,
                    u.personal__firstname,
                    u.personal__lastname,
                    u.account__subscription_type,
                    u.account__payment_type,
                    u.app_billing_token,
                    u.account__source,
                    COALESCE(u.personal__country, u.shipping__country, u.billing__country) as country,
                    u.is_secondary,
                    CASE
                        WHEN app_billing_token IS NOT NULL AND account__source = 'ios' THEN 'APPLE'
                        WHEN app_billing_token IS NOT NULl AND account__source = 'android' THEN 'GOOGLE'
                        WHEN account__source = 'amazon' THEN 'AMAZON'
                        ELSE 'OTHER'
                        END                                                                AS app_pay
             FROM prodmongo.users u
             WHERE account__subscription_type = 'premium'
               AND account__payment_type IN ('monthly')
               AND is_secondary = 0
               AND u._id NOT IN (
                 SELECT DISTINCT user_id
                 FROM tl_BF_CM_Early_Renewals
             )
         )
    WHERE app_pay = 'OTHER'
    --AND country NOT IN ('US', 'USA') AND country IS NOT NULL
    AND (country IN ('US', 'USA') OR country IS NULL)
)
         SELECT ub.*,
                ord_users.start_date,
                ord_users.subscription_set_to,
                ord_users.payment_set_to,
                ord_users.user_type
         FROM user_base ub
                  JOIN (
             SELECT users_id,
                    start_date,
                    subscription_set_to,
                    payment_set_to,
                    user_type
             FROM (
                      SELECT *,
                             ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
                      FROM users__account_history
                  )
             WHERE ord_events = 1
         ) ord_users
          ON ub.user_id = ord_users.users_id
WHERE subscription_set_to <> 'free'
AND payment_set_to <> 'none'
AND user_type <> 'Trial'
