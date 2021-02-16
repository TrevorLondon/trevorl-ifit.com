WITH champs as (
SELECT * 
FROM (
        SELECT ul.user_id,
               p._id as series,
               CASE WHEN p._id IN ('600a01d2631b9c0044fb4a04', '6009c266cdcdf6072e64d7a7') THEN 'TREADMILL'
                    WHEN p._id = '600a0cae74fd6d0282effca5' THEN 'STRENGTH'
                    WHEN p._id = '600a09f00064f60044cf95ec' THEN 'ROWER'
                    WHEN p._id = '600a068bee29c300449c656d' THEN 'BIKE'
                END AS equip_type,
                8 as series_set_wkout_count,
                CONVERT_TIMEZONE('AMERICA/DENVER',ul."start") as mst_start,
                ROW_NUMBER() OVER (PARTITION BY user_id, series ORDER BY ul."start" ASC) as ord_wkouts
                --COUNT(*) as wkout_count
        FROM unique_logs ul
        JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
        JOIN prodmongo.programs p on pw.programs_id = p._id 
        WHERE p._id IN ('600a01d2631b9c0044fb4a04',
        '600a0cae74fd6d0282effca5',
        '6009c266cdcdf6072e64d7a7',
        '600a09f00064f60044cf95ec',
        '600a068bee29c300449c656d')
        AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE BETWEEN '2021-02-01' AND '2021-02-14'
        )
WHERE ord_wkouts = 8 
AND mst_start::DATE BETWEEN '2021-02-08' AND '2021-02-14'
)
SELECT user_id,
       login__ifit__email,
       personal__firstname,
       personal__lastname,
       series,
       equip_type
FROM (
        SELECT c.*,
               u.login__ifit__email,
               u.personal__firstname,
               u.personal__lastname,
               u.account__subscription_type,
               u.account__payment_type,
               u.is_secondary,
               tl.parent_user_id,
               tl.parent_sub_type,
               tl.parent_pay_type,
               CASE WHEN is_secondary = 0 AND account__subscription_type <> 'free' AND account__payment_type <> 'none'
                        THEN 'PAID PRIMARY USER'
                    WHEN is_secondary = 0 AND (account__subscription_type = 'free' OR account__payment_type = 'none')
                         THEN 'FREE PRIMARY USER'
                    WHEN is_secondary = 1 AND parent_user_id IS NOT NULL AND parent_sub_type <> 'free' 
                          AND parent_pay_type <> 'none' THEN 'FREE SECONDARY USER - PAID PARENT'
                    WHEN is_secondary = 1 AND parent_user_id IS NOT NULL AND parent_sub_type = 'free' 
                          OR parent_pay_type = 'none' THEN 'FREE SECONDARY USER - NON-PAID PARENT'
                    ELSE 'OTHER'
               END AS qualified_user_type
        FROM champs c
        JOIN prodmongo.users u on c.user_id = u._id
        LEFT JOIN tl_primary_secondary_user_map tl on u._id = tl.secondary_user_id
        )
