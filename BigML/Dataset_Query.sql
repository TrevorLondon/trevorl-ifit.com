-- Data Dictionary for this in sheets. This was used as an interim solution to get an idea of what BigML predictors may be identified as risk users, etc. 

WITH cohort_build AS (
    SELECT *,
           CASE
               WHEN prev_type IS NULL OR ((subscription_set_to || payment_set_to) = (prev_sub || prev_pay))
                   THEN 'STATIC'
               WHEN prev_type IN ('Free', 'Trial') AND user_type = 'Paid' THEN 'UPGRADE'
               WHEN prev_type IN ('Paid', 'Trial') AND user_type = 'Free' THEN 'DOWNGRADE'
               WHEN subscription_set_to = 'coach-plus' AND payment_set_to IN ('yearly', 'two-year')
                        AND prev_sub IN ('premium', 'free') OR (prev_sub = 'coach-plus' AND prev_pay = 'monthly')
                   OR prev_pay = 'none' THEN 'UPGRADE'
               WHEN subscription_set_to = 'premium' AND prev_sub = 'coach-plus' THEN 'DOWNGRADE'
               WHEN subscription_set_to = 'premium' AND payment_set_to IN ('yearly', 'two-year')
                   AND (prev_sub = 'free' OR prev_pay IN ('monthly', 'none')) THEN 'UPGRADE'
               WHEN subscription_set_to = prev_sub AND payment_set_to IN ('yearly', 'two-year') AND
                    prev_pay IN ('yearly', 'two-year')
                   THEN 'STATIC'
               ELSE 'OTHER'
               END                                                                                            AS down_or_up,
           CASE
               WHEN user_type = 'Free' AND prev_type IN ('Paid', 'Trial') THEN 1
               ELSE 0 END                                                                                     AS churn_event,
           CASE
               WHEN user_type = 'Free' AND prev_sub = 'coach-plus' AND prev_pay = 'yearly' THEN 1
               ELSE 0 END                                                                                     AS cohort_sub_churn,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY start_date DESC)                                  as ord_events
    FROM (
             SELECT tl.*,
                    TO_DATE(cohort, 'YYYY-MM-DD')                                                AS fam_yearly_start,
                    UAH.start_date,
                    uah.subscription_set_to,
                    uah.payment_set_to,
                    uah.user_type,
                    LAG(user_type, 1) OVER (PARTITION BY uah.users_id ORDER BY start_date)       as prev_type,
                    LAG(subscription_set_to, 1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_sub,
                    LAG(payment_set_to, 1) OVER (PARTITION BY users_id ORDER BY start_date)      AS prev_pay,
                    LAG(start_date, 1) OVER (PARTITION BY users_id ORDER BY start_date)          as prev_start_date
             FROM tl_ML_FY_Cohort tl
             LEFT JOIN users__account_history uah on tl.user_id = uah.users_id
                 AND DATE_TRUNC('month', uah.start_date) >= TO_DATE(cohort, 'YYYY-MM-DD')
             WHERE user_type <> 'Memorial Promo 2017'
         )
),
most_recently_churned AS (
    SELECT *
    FROM cohort_build
    WHERE churn_event = 1
      AND ord_events = 1
      AND prev_sub = 'coach-plus'
      AND prev_pay IN ('yearly', 'two-year')
      AND DATEDIFF('month', start_date, GETDATE()) < 7
),
original_subs AS (
    SELECT user_id,
           start_date as join_date,
           subscription_set_to as original_sub_type,
           payment_set_to as original_pay_type,
           CASE WHEN user_type = 'Trial' THEN 1 ELSE 0 END AS in_trial_at_join
    FROM (
             SELECT mrc.user_id,
                    uah.*,
                    ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY uah.start_date ASC) as ord_events
             FROM most_recently_churned mrc
                      JOIN users__account_history uah on mrc.user_id = uah.users_id
             WHERE uah.user_type NOT IN ('Memorial Promo 2017')
               AND DATEDIFF('day', uah.start_date, uah.end_date) > 1
         )
    WHERE ord_events = 1
),
ua_logs AS (
    SELECT user_id,
           start_date,
           list_types,
           list_logs
    FROM (
             SELECT mrc.*,
                    LISTAGG(ua.type, ',') WITHIN GROUP (ORDER BY created) OVER (PARTITION BY ua.user_id)     as list_types,
                    LISTAGG(ua.readable, ',') WITHIN GROUP (ORDER BY created)
                    OVER (PARTITION BY ua.user_id)                                                           as list_logs
             FROM most_recently_churned mrc
                      LEFT JOIN prodmongo.useractivities ua on mrc.user_id = ua.user_id
                 AND ua.created BETWEEN mrc.start_date - INTERVAL '60 second' AND mrc.start_date + INTERVAL '60 second'
         )
    GROUP BY 1, 2, 3, 4
),
prev_order AS (
    SELECT *
    FROM (
             SELECT cb.user_id,
                    cb.prev_start_date,
                    cb.ord_events,
                    o.order_date,
                    o.item_total,
                    o.order_complete,
                    o.total,
                    o.usdtotal,
                    o.source,
                    o.in_app_order_id,
                    i.sap_product_id                                                    as sku,
                    ROW_NUMBER() OVER (PARTITION BY o.user_id ORDER BY order_date DESC) as ord_orders
             FROM cohort_build cb
                      LEFT JOIN prodmongo.orders o on cb.user_id = o.user_id
                 AND
                                                      o.order_date BETWEEN cb.prev_start_date - INTERVAL '60 second' AND cb.prev_start_date + INTERVAL '60 second'
                      JOIN prodmongo.orders__items oi on o._id = oi.orders_id
                      JOIN prodmongo.items i on oi.item = i._id
             WHERE i.category = 'Account'
               AND order_complete = 1
               AND item_total > 0
         )
    WHERE ord_orders = 1
),
wkouts AS (
    SELECT wkout_cats.user_id,
           wkout_category,
           count(*) as wkout_count_in_category,
           most_recent_wkout,
           series_participation
    FROM (
             SELECT mrc.user_id,
                    mrc.prev_start_date,
                    mrc.start_date as churn_date,
                    al."start" as wkout_start,
                    CASE
                        WHEN al.workout_context IN ('scheduledLive', 'scheduledPre', 'ondemand') THEN 'LIVE'
                        WHEN ws.brightcove_video_id IS NOT NULL AND ws.brightcove_video_id <> '' THEN 'VIDEO'
                        WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
                        WHEN al.duration > 0 AND (ws.target_value IS NULL OR ws.title = 'Manual Workout') THEN 'MANUAL'
                        WHEN al.wolf_generated_id IS NOT NULL THEN 'MANUAL'
                        ELSE 'OTHER'
                        END        AS wkout_category,
                    CASE WHEN mrc.user_id IN (SELECT DISTINCT user_id FROM all_challenges_users) THEN 1 ELSE 0 END AS series_participation
             FROM most_recently_churned mrc
                      JOIN prodmongo.activitylogs al on mrc.user_id = al.user_id
                 AND al.start BETWEEN mrc.prev_start_date AND mrc.start_date
                      LEFT JOIN workout_store.workouts ws on al.workout_id = ws._id
         ) wkout_cats
    JOIN (
        SELECT user_id,
               MAX(start) as most_recent_wkout
        FROM prodmongo.activitylogs
        GROUP BY 1
        ) rec_wkout
    ON wkout_cats.user_id = rec_wkout.user_id
    GROUP BY 1,2,4,5
),
equip AS (
SELECT *
FROM (
         SELECT *,
                ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY line) as ord_lines
         FROM (
                  SELECT user_id,
                         model_number,
                         line,
                         MAX(promo) as equipment_promo_price,
                         wifi
                  FROM (
                           SELECT DISTINCT mrc.user_id                                   as user_id,
                                           ue.purchase_date,
                                           ssc.order_date                                as dr_order_date,
                                           ue.model_number,
                                           COALESCE(ssc.wifi, skum1.wifi, skum2.wifi)    as wifi,
                                           COALESCE(ssc.line, skum1.line, skum2.line)    as line,
                                           ssc.net_unit_price,
                                           ssc.extended_price,
                                           COALESCE(ssc.msrp, skum1.msrp, skum2.msrp)    as msrp,
                                           COALESCE(ssc.promo, skum1.promo, skum2.promo) as promo
                           FROM most_recently_churned mrc
                                    LEFT JOIN sap_sales_categorized ssc on mrc.user_id = ssc.user_id
                               AND ssc.wifi IN ('GLASS', 'WIFI', 'LEGACY')
                               AND ssc.extended_price > 0
                                    LEFT JOIN userequipments_categorized ue on mrc.user_id = ue.users_id
                                    LEFT JOIN prodmongo.stationaryconsoles sc on ue.software_number = sc.software_number
                                    LEFT JOIN equipment_sku_map skum2 on sc.part_number = skum2.console_number
                                    LEFT JOIN equipment_sku_map skum1 on ue.model_number = skum1.PRDNO
                           WHERE (ue.software_number IS NOT NULL OR dr_order_date IS NOT NULL)
                       )
                  GROUP BY 1, 2, 3, 5
              )
     )
    WHERE ord_lines = 1 --SOME MAX promos had same cost but diff machines - per Tess only want one doesn't matter which
)
SELECT DISTINCT mrc.user_id,
       os.join_date::DATE as join_date,
       CASE WHEN ua.list_types LIKE ('%autoDowngrade%') OR ua.list_types LIKE ('%FailedAutoRenewal%') THEN 'INVOLUNTARY'
            ELSE 'VOLUNTARY'
       END AS churn_type,
       os.original_sub_type,
       os.original_pay_type,
       os.in_trial_at_join,
       CASE WHEN mrc.user_id IN (SELECT DISTINCT(users_id) FROM new_users WHERE origin = 'DR') THEN 'DR'
            WHEN u.account__source = 'ios' THEN 'iOS'
            WHEN u.account__source = 'android' THEN 'Android'
            WHEN u.account__source = 'amazon' THEN 'Amazon'
            ELSE 'Retail'
       END AS origin,
       CASE WHEN (os.original_sub_type IN ('free', 'premium') OR in_trial_at_join = 1) AND mrc.prev_sub = 'coach-plus' THEN 'UPGRADE'
            WHEN (os.original_sub_type = 'free' OR in_trial_at_join = 1) AND mrc.prev_sub = 'premium' THEN 'UPGRADE'
            WHEN (os.original_sub_type <> 'free' OR in_trial_at_join = 1) AND mrc.prev_sub = 'free' THEN 'DOWNGRADE'
            WHEN os.original_sub_type = 'coach-plus' AND in_trial_at_join = 0 and mrc.prev_sub IN ('premium', 'free') THEN 'DOWNGRADE'
            WHEN OS.original_sub_type = mrc.prev_sub THEN 'STATIC'
       ELSE 'OTHER'
       END AS mobility,
       CASE WHEN u.is_secondary = 0 AND tl.parent_user_id IS NOT NULL THEN 1 ELSE 0 END AS has_secondary,
       CASE WHEN has_secondary = 1 THEN tl.sec_users_on_parent_id ELSE NULL END AS number_of_secondary_users,
       po.item_total as previous_item_total,
       po.prev_start_date::DATE as previous_purchase_date,
       po.sku as previous_purchase_sku,
       w1.wkout_count_in_category as total_live_wkouts,
       w2.wkout_count_in_category as total_map_wkouts,
       w3.wkout_count_in_category as total_video_wkouts,
       w4.wkout_count_in_category as total_manual_wkouts,
       w.series_participation,
       w.most_recent_wkout::DATE AS most_recent_wkout,
       DATEDIFF('year', u.personal__birthday, GETDATE()) as age,
       u.personal__gender as gender,
       u.billing__zip as zip_code,
       e.model_number as equipment_model_number,
       e.line as equipment_product_line,
       MAX(e.equipment_promo_price) as equipment_promo_price,
       e.wifi as wifi_type,
       CASE WHEN e2.equip_count > 1 THEN 1 ELSE 0 END AS multiple_equipment
FROM most_recently_churned mrc
LEFT JOIN ua_logs ua on mrc.user_id = ua.user_id
LEFT JOIN original_subs os on mrc.user_id = os.user_id
LEFT JOIN prev_order po on mrc.user_id = po.user_id
LEFT JOIN wkouts w on mrc.user_id = w.user_id
LEFT JOIN wkouts w1 on mrc.user_id = w1.user_id
    AND w1.wkout_category = 'LIVE'
LEFT JOIN wkouts w2 on mrc.user_id = w2.user_id
    AND w2.wkout_category = 'MAP'
LEFT JOIN wkouts w3 on mrc.user_id = w3.user_id
    AND w3.wkout_category = 'VIDEO'
LEFT JOIN wkouts w4 on mrc.user_id = w4.user_id
    AND w4.wkout_category = 'MANUAL'
LEFT JOIN equip e on mrc.user_id = e.user_id
LEFT JOIN (
    SELECT user_id,
           count(*) as equip_count
    FROM equip
    GROUP BY 1
    ) AS e2
ON e.user_id = e2.user_id
LEFT JOIN prodmongo.users u on mrc.user_id = u._id
LEFT JOIN tl_primary_secondary_user_map tl on mrc.user_id = tl.parent_user_id
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,27
