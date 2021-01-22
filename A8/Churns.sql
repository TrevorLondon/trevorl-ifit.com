
WITH user_set AS (
SELECT *
FROM (
SELECT *,
        CASE
            WHEN primary_or_sec = 'secondary' THEN 'Free'
            WHEN employee = 1 THEN 'Employee'
            WHEN trial_membership = 1 AND membership_type <> 'FREE NONE' THEN 'Trial'
            WHEN promo_code = '1MEMBED' AND membership_type <> 'FREE NONE' THEN 'Trial'
            WHEN promo_code = '1MEMBED' AND membership_type = 'FREE NONE' THEN 'Free'
            WHEN ord_event_types LIKE ('%freemotionOnRegistration%') THEN 'Trial'
            WHEN ord_event_types LIKE ('%oneHundredWorkouts%') AND (prev_trial_flag = 'false' OR prev_trial_flag IS NULL)
                AND prev_sub <> 'free' AND prev_pay <> 'none' THEN 'Paid'
            WHEN ord_event_types LIKE ('%oneHundredWorkouts%') AND (prev_trial_flag = 'false' OR prev_trial_flag IS NULL)
                AND prev_sub <> 'free' AND prev_pay = 'none' THEN 'Free'
            WHEN ord_event_types LIKE ('%oneHundredWorkouts%') AND prev_trial_flag = 'true'
                 AND prev_sub <> 'free' THEN 'Trial'
            WHEN membership_type <> 'FREE NONE' THEN 'Paid'
            WHEN membership_type = 'FREE NONE' THEN 'Free'
            ELSE NULL
            END as user_type      
FROM (
         SELECT *,
               ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY "date" DESC) as ord_events,
                --ROW_NUMBER() OVER (PARTITION BY users_id, "date" ORDER BY abs(extract(epoch from (events_timestamp - "date")))) as row_id,
                CASE
                    WHEN primary_or_sec = 'secondary' THEN 'FREE NONE'
                    WHEN subscription_set_to = 'coach-plus' THEN
                        CASE
                            WHEN payment_set_to = 'none' AND employee = 0 AND ord_event_types LIKE ('%freemotionOnRegistration%')
                                 THEN 'FAMILY YEARLY' 
                            WHEN payment_set_to = 'none' AND employee = 0 AND ord_event_types NOT LIKE ('%freemotionOnRegistration%')
                                THEN 'FREE NONE' 
                            WHEN payment_set_to = 'none' AND employee = 1 AND primary_or_sec = 'primary' THEN 'FAMILY YEARLY' 
                            WHEN payment_set_to IN ('yearly', 'two-year') THEN 'FAMILY YEARLY'
                            WHEN payment_set_to = 'monthly' THEN 'FAMILY MONTHLY'
                            ELSE 'FAMILY UNKNOWN'
                        END
                    WHEN subscription_set_to = 'premium' THEN
                        CASE
                            WHEN payment_set_to = 'none' AND employee = 0 THEN 'FREE NONE' 
                            WHEN payment_set_to = 'none' AND employee = 1 THEN 'FAMILY YEARLY' 
                            WHEN payment_set_to IN ('yearly', 'two-year') THEN 'INDIVIDUAL YEARLY'
                            WHEN payment_set_to = 'monthly' THEN 'INDIVIDUAL MONTHLY'
                            ELSE 'INDIVIDUAL UNKNOWN'
                        END
                    WHEN subscription_set_to = 'premium-non-equipment' THEN
                        CASE
                            WHEN payment_set_to = 'none' AND employee = 0 THEN 'FREE NONE'
                            WHEN payment_set_to = 'none' AND employee = 1 THEN 'FAMILY YEARLY'
                            WHEN payment_set_to IN ('yearly', 'two-year') THEN 'INDIVIDUAL YEARLY'
                            WHEN payment_set_to = 'monthly' THEN 'INDIVIDUAL MONTHLY'
                            ELSE 'PREMIUM NON-EQ UNKNOWN'
                        END
                    WHEN subscription_set_to = 'free' THEN 'FREE NONE'
                    ELSE 'OTHER'
                END AS membership_type
         FROM (
                  SELECT uah.*,
                         u.is_secondary,
                         u.login__ifit__email,
                          CASE WHEN is_secondary = 1 THEN 'secondary'
                               WHEN (is_secondary = 0 OR is_secondary IS NULL) THEN 'primary'
                         END AS primary_or_sec,
                         orders.sku,
                         orders.promo_code,
                         orders.trial_membership,
                         orders.item_total,
                         ord_events as ord_event_types,
                         events_date,
                         events_timestamp,
                         --LISTAGG(ua.type, ',') WITHIN GROUP (ORDER BY ua.created ASC) OVER (PARTITION BY ua.user_id, ua.created::date) as ord_event_types,
                         LAG(uah.subscription_set_to, 1) OVER (PARTITION BY uah.users_id ORDER BY uah."date") as prev_sub,
                         LAG(uah.payment_set_to, 1) OVER (PARTITION BY uah.users_id ORDER BY uah."date")      as prev_pay,
                         LAG(orders.trial_membership, 1) OVER (PARTITION BY uah.users_id ORDER BY uah."date")  as prev_trial_flag,
                         CASE
                                WHEN login__ifit__email LIKE ('%@ifit.com') OR login__ifit__email LIKE ('%@iconfitness%')
                                    OR login__ifit__email LIKE ('%@freemotion%')
                                THEN 1
                                ELSE 0
                                END as employee
                  FROM prodmongo.users__account_history uah
                  JOIN prodmongo.users u on uah.users_id = u._id
                  LEFT JOIN (
                        SELECT user_id, created::DATE as events_date, created as events_timestamp, ord_events
                        FROM (
                                SELECT *,
                                       LISTAGG("type",',') WITHIN GROUP (ORDER BY created ASC) OVER (PARTITION BY user_id, created::DATE) as ord_events
                                FROM prodmongo.useractivities
                              )
                        GROUP BY 1,2,3,4
                        ) ord_events
                  ON uah.users_id = ord_events.user_id 
                        AND uah.date::DATE = ord_events.events_date
                  LEFT JOIN (
                      SELECT o._id as orders_id,
                             o.user_id,
                             o.promo_code,
                             o.order_date,
                             o.item_total,
                             i.sap_product_id as sku,
                             i.trial_membership
                      FROM prodmongo.orders o
                      JOIN prodmongo.orders__items oi on o._id = oi.orders_id
                      JOIN prodmongo.items i on oi.item = i._id
                      WHERE i.category = 'Account'
                  ) orders
                    ON uah.users_id = orders.user_id
                         AND uah.date BETWEEN orders.order_date - INTERVAL '30 second' AND orders.order_date + INTERVAL '30 second'
                  --WHERE CONVERT_TIMEZONE('AMERICA/DENVER', uah.date)::DATE <= '2021-01-13'
              ) ordered_acct_changes
     )
--WHERE ord_events = 1
) user_snapshot 
--WHERE "date" > '2020-01-01'
)
SELECT prev_sub, prev_pay, count(*)
FROM (
SELECT *,
       LAG(user_type,1) OVER (PARTITION BY users_id ORDER BY "date") as prev_type
FROM user_set
)
WHERE "date" >= '2021-01-01' --BETWEEN '2020-12-01' AND '2020-12-31'
AND prev_type = 'Paid'
AND user_type = 'Free'
group by 1,2

