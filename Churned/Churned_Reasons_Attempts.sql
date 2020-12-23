--Built this for a count of Vindicia attempts on churned Users. 
--Can use this as a blueprint to further refine the ua.readable searching functionality, etc. for a possible table

WITH churned_users AS (
    SELECT *,
           CASE
               WHEN prev_memb_type = 'coach-plus' AND prev_payment_type IN ('yearly', 'two-year') then 'FAMILY YEARLY'
               WHEN prev_memb_type = 'coach-plus' AND prev_payment_type = 'monthly' THEN 'FAMILY MONTHLY'
               WHEN prev_memb_type = 'premium' AND prev_payment_type IN ('yearly', 'two-year') THEN 'INDIVIDUAL YEARLY'
               WHEN prev_memb_type = 'premium' AND prev_payment_type = 'monthly' THEN 'INDIVIDUAL MONTHLY'
               WHEN prev_memb_type = 'premium-non-equipment' AND prev_payment_type IN ('yearly', 'two-year')
                   THEN 'NON-EQ YEARLY'
               WHEN prev_memb_type = 'premium-non-equipment' AND prev_payment_type = 'monthly' THEN 'NON-EQ MONTHLY'
               END AS membership_type
    FROM (
             select *,
                    LAG(subscription_set_to, 1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_memb_type,
                    LAG(payment_set_to, 1) OVER (PARTITION BY users_id ORDER BY start_date)      as prev_payment_type,
                    LAG(user_type, 1) OVER (PARTITION BY users_id ORDER BY start_date)           as prev_user_type
             from users__account_history
         )
    WHERE CONVERT_TIMEZONE('America/Denver', start_date)::date >= '2020-11-20'
      AND end_date IS NULL
      AND user_type = 'Free'
      and prev_user_type = 'Paid'
      AND prev_payment_type <> 'none'
      AND is_secondary = 0
)
SELECT distinct users_id,
                churned_date,
                prior_memb_type,
                "type",
                attempts,
                reason,
                CASE WHEN u.app_billing_token IS NOT NULL AND account__source IN ('ios', 'android') THEN 'phone'
                     WHEN u.account__source = 'amazon' THEN 'amazon'
                     ELSE 'other'
                END AS app_pay,
                CASE WHEN u.billing__stripe_customer_id IS NOT NULL OR order_number IN (
                        SELECT o.order_number
                        FROM prodmongo.orders o
                        JOIN stripe.charges sc on o.order_number = sc.metadata_po_number
                    ) THEN 1
                    ELSE 0
                END AS stripe_user
FROM (
         SELECT *,
                CASE
                    WHEN "type" IN ('yearlyFailedAutoRenewal', 'monthlyFailedAutoRenewal')
                        THEN substring(readable, 21, 1)
                    ELSE NULL
                    END AS attempts,
                CASE
                    WHEN "type" = 'autoDowngrade' THEN substring(readable, 57, 25)
                    ELSE 'OTHER'
                    END AS reason
         FROM (
                  SELECT cu.users_Id,
                         cu.start_date      as churned_date,
                         cu.membership_type as prior_memb_type,
                         o.order_date,
                         o.item_total,
                         o.order_complete,
                         o.settled,
                         o.order_number,
                         i.name,
                         i.auto_renewal_id,
                         ua.type,
                         ua.readable
                  FROM churned_users cu
                           LEFT JOIN prodmongo.orders o on cu.users_id = o.user_id
                      AND cu.start_date >= (o.order_date - 15) --AND o.order_date + INTERVAL '5 days'
                           JOIN prodmongo.orders__items oi on o._id = oi.orders_id
                           JOIN prodmongo.items i on oi.item = i._id
                           LEFT JOIN prodmongo.useractivities ua on cu.users_id = ua.user_id
                      AND cu.start_date BETWEEN ua.created - INTERVAL '15 days' AND ua.created + INTERVAL '5 days'
                  WHERE "type" IN ('yearlyFailedAutoRenewal', 'monthlyFailedAutoRenewal', 'autoDowngrade')
                  AND auto_renewal_id IS NOT NULL
              )
     ) pre_final_users
JOIN prodmongo.users u on pre_final_users.users_id = u._id
WHERE app_pay = 'other'
AND stripe_user = 0
AND attempts IS NOT NULL
ORDER BY RANDOM()
LIMIT 250
