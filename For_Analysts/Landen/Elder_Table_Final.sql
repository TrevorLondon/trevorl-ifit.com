WITH user_base AS (
                             SELECT user_id,
                                    CASE WHEN is_secondary = 1 THEN 'secondary' ELSE 'primary' END AS primary_or_sec,
                                    dependents,
                                    age,
                                    senior,
                                    country,
                                    pay_method,
                                    account__source,
                                    billing__stripe_customer_id,
                                    billing__tokenizer,
                                    mst_membership_start_date,
                                    cohort_sub,
                                    cohort_pay,
                                    tenure
                             FROM (
                                      SELECT _id                                                              as user_id,
                                             is_secondary,
                                             CASE
                                                 WHEN is_secondary = 0 THEN COALESCE(sec_users_on_parent_id, 0)
                                                 ELSE 0 END                                                   AS dependents,
                                             DATEDIFF('year', personal__birthday, GETDATE())                  as age,
                                             CASE WHEN age >= 63 THEN 1 ELSE 0 END                            AS senior,
                                             COALESCE(personal__country, shipping__country, billing__country) as country,
                                             billing__card_type                                               as pay_method,
                                             account__source,
                                             billing__stripe_customer_id,
                                             billing__tokenizer,
                                             mst_membership_start_date,
                                             nu.subscription_set_to as cohort_sub,
                                             nu.payment_set_to as cohort_pay,
                                             (DATEDIFF('day', mst_membership_start_date, GETDATE()) / 30) as tenure
                                      FROM prodmongo.users u
                                               JOIN new_users nu on u._id = nu.users_id
                                               LEFT JOIN (
                                          SELECT DISTINCT parent_user_id,
                                                          sec_users_on_parent_id
                                          FROM tl_primary_secondary_user_map tl
                                      ) parents
                                                         on u._id = parents.parent_user_id
                                      WHERE (cohort_pay = 'yearly' AND DATEDIFF('month', mst_membership_start_date,
                                                     CONVERT_TIMEZONE('AMERICA/DENVER', GETDATE())) = 16)
                                      OR (cohort_pay = 'monthly' AND DATEDIFF('month', mst_membership_start_date,
                                                     CONVERT_TIMEZONE('AMERICA/DENVER', GETDATE())) <= 16)
                                  )
                         ),
                              acct_orders AS (
                                  SELECT *
                                  FROM (
                                           SELECT *,
                                                  ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
                                           FROM (
                                                    SELECT user_id                                                                as ub_user_id,
                                                           mst_membership_start_date,
                                                           uah.*,
                                                           LAG(user_type, 1) OVER (PARTITION BY uah.users_id ORDER BY start_date) as prev_sub_type,
                                                           LAG(subscription_set_to,1) OVER (PARTITION BY uah.users_id ORDER BY start_date) as prev_sub,
                                                           LAG(payment_set_to, 1) OVER (PARTITION BY uah.users_id ORDER BY start_date) as prev_pay_type
                                                    FROM user_base ub
                                                             JOIN users__account_history uah
                                                                  on ub.user_id = uah.users_id
                                                                      AND
                                                                     CONVERT_TIMEZONE('AMERICA/DENVER', uah.start_date) >=
                                                                     mst_membership_start_date
                                                )
                                       ) mobility
                                           LEFT JOIN (
                                      SELECT o.user_id                                        as orders_user_id,
                                             CONVERT_TIMEZONE('AMERICA/DENVER', o.order_date) as mst_order_date,
                                             o.order_complete,
                                             o.item_total,
                                             i.auto_renewal_id,
                                             s.id                                             as stripe_id
                                      FROM prodmongo.orders o
                                               JOIN prodmongo.orders__items oi on o._id = oi.orders_id
                                               JOIN prodmongo.items i on oi.item = i._id
                                               LEFT JOIN stripe.charges s on o.order_number = s.metadata_po_number
                                  ) orders
                                                     ON mobility.users_id = orders.orders_user_id
                                                         AND orders.mst_order_date::DATE = mobility.start_date::DATE
                                      --orders.mst_order_date BETWEEN mobility.start_date - INTERVAL '30 second' AND mobility.start_date + INTERVAL '30 second'
                                           LEFT JOIN (
                                      SELECT *
                                      FROM (
                                               SELECT ua.user_id                                     as ua_user_id,
                                                      CONVERT_TIMEZONE('AMERICA/DENVER', ua.created) as mst_ua_created,
                                                      LISTAGG("type", ',')
                                                      WITHIN GROUP (ORDER BY ua.created ASC) --as ord_type_logs
                                                      OVER (PARTITION BY user_id, created::DATE)     as ord_type_logs
                                                      --ua.type,
                                                      --ua.readable
                                               FROM prodmongo.useractivities ua
                                               GROUP BY 1, 2, "type", created
                                           )
                                      GROUP BY ua_user_id, mst_ua_created, ord_type_logs
                                  ) ua_logs
                                                     ON mobility.ub_user_id = ua_logs.ua_user_id
                                                         AND
                                                        CONVERT_TIMEZONE('AMERICA/DENVER', mobility.start_date)::DATE =
                                                        ua_logs.mst_ua_created::DATE
                                  --AND mobility.start_date BETWEEN ua_logs.mst_ua_created- INTERVAL '30 second' AND ua_logs.mst_ua_created + INTERVAL '30 second'
                              )
                        SELECT user_id,
                               u.account__subscription_type as current_sub,
                               u.account__payment_type as current_pay,
                               senior,
                               age,
                               country,
                               first_paid_date,
                               cohort_sub,
                               cohort_pay,
                               tenure,
                               dependents,
                               payment_processor,
                               pre_final.account__source,
                               billing,
                               CASE WHEN churns_list LIKE ('%1%') THEN 1 ELSE 0 END AS past_churn,
                               CASE WHEN churns_list LIKE ('%1') THEN 1 ELSE 0 END AS current_churn_status,
                               wkout_count
                        FROM (
                                 SELECT acct.user_id,
                                        ub.senior,
                                        ub.age,
                                        ub.country,
                                        ub.mst_membership_start_date     as first_paid_date,
                                        ub.cohort_sub,
                                        ub.cohort_pay,
                                        ub.tenure,
                                        ub.dependents,
                                        CASE
                                            WHEN billing__stripe_customer_id IS NOT NULL OR stripe_id IS NOT NULL
                                                THEN 'STRIPE'
                                            WHEN billing__tokenizer = 'paymetric' THEN 'PAYMETRIC'
                                            WHEN billing__tokenizer = 'cybersource' THEN 'CYBERSOURCE'
                                            ELSE 'PAYMETRIC'
                                            END                          AS payment_processor,
                                        ub.account__source,
                                        acct.prev_sub,
                                        acct.prev_pay_type,
                                        acct.prev_sub_type,
                                        acct.membership_type,
                                        acct.billing,
                                        acct.ord_events,
                                        LISTAGG(acct.churn_event, ',') WITHIN GROUP (ORDER BY start_date)
                                        OVER (PARTITION BY acct.user_id) as churns_list,
                                        LISTAGG(acct.start_date::DATE, ',') WITHIN GROUP (ORDER BY start_date)
                                        OVER (PARTITION BY acct.user_id) as dates_list,
                                        --acct.churn_event             as churned,
                                        wkouts.wkout_count
                                 FROM user_base ub
                                          JOIN (
                                     SELECT *,
                                            CASE
                                                WHEN ord_type_logs NOT LIKE ('%manual%') AND
                                                     auto_renewal_id IS NOT NULL AND
                                                     order_complete = 1 AND
                                                     item_total > 0
                                                    AND ord_type_logs IN
                                                        ('monthlyAutoRenewal', 'yearlyAutoRenewal', 'yearlyMembership',
                                                         'monthlyMembership') THEN 'AUTO'
                                                ELSE 'MANUAL'
                                                END        AS billing,
                                            CASE
                                                WHEN user_type = 'Free' AND prev_sub_type IN ('Paid', 'Trial') THEN 1
                                                ELSE 0 END AS churn_event
                                     FROM (
                                              SELECT DISTINCT acct_orders.ub_user_id                                  as user_id,
                                                              mst_membership_start_date                               as first_paid_date,
                                                              acct_orders.start_date,
                                                              acct_orders.end_date,
                                                              CASE
                                                                  WHEN acct_orders.subscription_set_to = 'coach-plus' and
                                                                       acct_orders.payment_set_to = 'monthly'
                                                                      THEN 'FAMILY MONTHLY'
                                                                  WHEN acct_orders.subscription_set_to = 'coach-plus' and
                                                                       acct_orders.payment_set_to IN ('yearly', 'two-year')
                                                                      THEN 'FAMILY YEARLY'
                                                                  WHEN acct_orders.subscription_set_to = 'premium' and
                                                                       acct_orders.payment_set_to = 'monthly'
                                                                      THEN 'INDIVIDUAL MONTHLY'
                                                                  WHEN acct_orders.subscription_set_to = 'premium' and
                                                                       acct_orders.payment_set_to IN ('yearly', 'two-year')
                                                                      THEN 'INDIVIDUAL YEARLY'
                                                                  WHEN acct_orders.subscription_set_to = 'premium-non-equipment' and
                                                                       acct_orders.payment_set_to = 'monthly'
                                                                      THEN 'NON-EQ MONTHLY'
                                                                  WHEN acct_orders.subscription_set_to = 'premium-non-equipment' and
                                                                       acct_orders.payment_set_to IN ('yearly', 'two-year')
                                                                      THEN 'NON-EQ YEARLY'
                                                                  WHEN acct_orders.subscription_set_to = 'web' and
                                                                       acct_orders.payment_set_to = 'monthly'
                                                                      THEN 'INDIVIDUAL MONTHLY'
                                                                  WHEN acct_orders.subscription_set_to = 'web' and
                                                                       acct_orders.payment_set_to IN ('yearly', 'two-year')
                                                                      THEN 'INDIVIDUAL YEARLY'
                                                                  WHEN acct_orders.subscription_set_to = 'free' OR
                                                                       acct_orders.payment_set_to = 'none' THEN 'FREE'
                                                                  ELSE NULL
                                                                  END                                                 AS membership_type,
                                                              acct_orders.user_type,
                                                              acct_orders.is_secondary,
                                                              acct_orders.prev_sub_type,
                                                              acct_orders.prev_sub,
                                                              acct_orders.prev_pay_type,
                                                              acct_orders.mst_order_date,
                                                              acct_orders.auto_renewal_id,
                                                              acct_orders.order_complete,
                                                              acct_orders.item_total,
                                                              acct_orders.stripe_id,
                                                              acct_orders.mst_ua_created,
                                                              acct_orders.ord_type_logs,
                                                              ROW_NUMBER()
                                                              OVER (PARTITION BY ub_user_id ORDER BY start_date DESC) as ord_events
                                              from acct_orders
                                          )
                                 ) acct
                                               on ub.user_id = acct.user_id
                                          LEFT JOIN (
                                     SELECT ul.user_id,
                                            count(*) as wkout_count
                                     FROM unique_logs ul
                                              JOIN user_base ub on ul.user_id = ub.user_id
                                         AND CONVERT_TIMEZONE('AMERICA/DENVER', ul.start) >=
                                             ub.mst_membership_start_date
                                     GROUP BY 1
                                 ) wkouts
                                                    on ub.user_id = wkouts.user_id
                             ) pre_final
                        JOIN prodmongo.users u on pre_final.user_id = u._id
                        WHERE ord_events = 1
