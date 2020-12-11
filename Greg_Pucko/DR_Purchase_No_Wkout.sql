WITH sap_users AS (
    select *
    from (
             SELECT user_id,
                    mst_created,
                    memb_type as current_memb_type,
                    line,
                    order_date,
                    CASE
                        WHEN mst_created < order_date THEN (DATEDIFF(day, mst_created, order_date) || ' days BEFORE')
                        WHEN mst_created > order_date THEN (DATEDIFF(day, mst_created, order_date) || ' days AFTER')
                        WHEN mst_created = order_date THEN 'SAME DAY'
                        ELSE 'OTHER'
                        END   AS order_to_join_day_diff
             FROM (
                      SELECT ssc.email,
                             ssc.line,
                             ssc.order_date,
                             CONVERT_TIMEZONE('AMERICA/DENVER', u.created)::DATE              as mst_created,
                             u._id                                                            as user_id,
                             (u.account__subscription_type || '-' || u.account__payment_type) as memb_type
                      FROM sap_sales_categorized ssc
                               JOIN prodmongo.users u on ssc.email = u.login__ifit__email
                          AND DATEDIFF(day, u.created, GETDATE()) <= 90
                      WHERE ssc.line IN ('TREADMILL', 'ROWER', 'WEIGHTS', 'ELLIPTICAL', 'BIKE', 'STRENGTH TRAINING')
                        AND ssc.extended_price > 0
                  )
         )
)
select *,
       ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date DESC) as ord_order_date
from (
         SELECT su.*,
                SUM(CASE WHEN (ul.software_number BETWEEN 424110 AND 424114) OR (ul.software_number = 424992) THEN 1 ELSE 0 END) AS app_wkout_count,
                SUM(CASE WHEN ul.software_number NOT BETWEEN 424110 AND 424114 AND ul.software_number <> 424992 THEN 1 ELSE 0 END) as normal_wkouts
         FROM sap_users su
         LEFT JOIN unique_logs ul on su.user_id = ul.user_id
         GROUP BY 1, 2, 3, 4, 5, 6
     )
WHERE (normal_wkouts = 0
OR (app_wkout_count > 0 AND normal_wkouts = 0))
AND (current_memb_type NOT LIKE '%free%' AND current_memb_type NOT LIKE '%none%')
LIMIT 500
