-- Logic built into this final week pull to include the "Flash Challenge" they offered. Program_IDs provided by Jomil. 

WITH actual_chal_users AS (
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
        AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE BETWEEN '2021-02-01' AND '2021-02-28'
        )
WHERE ord_wkouts = 8 
AND mst_start::DATE BETWEEN '2021-02-01' AND '2021-02-28'
)
SELECT user_id,
       login__ifit__email,
       personal__firstname,
       personal__lastname,
       age,
       tenure,
       personal__gender,
       country,
       CASE WHEN country IN ('US', 'USA', 'United States') THEN 'DOMESTIC'
            WHEN country NOT IN ('US', 'USA', 'United States') AND country IS NOT NULL THEN 'FOREIGN'
            WHEN country IS NULL THEN 'UNKNOWN'
            ELSE 'OTHER'
       END AS country_cleaned,
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
               datediff('year', u.personal__birthday, GETDATE()) AS age,
               /*CASE WHEN age <= '20' THEN 1
                    WHEN age BETWEEN '21' AND '30' THEN 2
                    WHEN age BETWEEN '31' AND '40' THEN 3
                    WHEN age BETWEEN '41' AND '50' THEN 4
                    WHEN age BETWEEN '51' AND '60' THEN 5
                    WHEN age > '60' THEN 6
               END AS age_bucket,*/
               u.personal__gender,
               datediff('year', u.created, GETDATE()) as tenure,
               /*CASE WHEN tenure < '1' THEN 1
                    WHEN tenure BETWEEN '1' AND '2' THEN 2
                    WHEN tenure > '2' AND <= '3' THEN 3
                    WHEN tenure > '3' AND <= '4' THEN 4
                    WHEN tenure > '4' THEN 5
               END AS tenure_buckets, */
               COALESCE(u.billing__country, u.shipping__country, u.personal__country) as country,
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
)
/*SELECT CASE WHEN series_comp = 5 THEN 5
            WHEN series_comp = 4 THEN 4
            WHEN series_comp = 3 THEN 3
            WHEN series_comp = 2 THEN 2
            WHEN series_comp = 1 THEN 1
       END AS series_comp_bucket,
       COUNT(*)
FROM ( */
SELECT /*CASE WHEN tenure < 1 THEN 1
            WHEN tenure >= 1 AND tenure < 2 THEN 2
            WHEN tenure >= 2 AND tenure < 3 THEN 3
            WHEN tenure >= 3 AND tenure < 4 THEN 4
            WHEN tenure >= 4 AND tenure < 5 THEN 5
            WHEN tenure >= 5 THEN 6
            ELSE 7 
            END AS tenure_bucket,   */
        personal__gender,
        count(distinct user_id) 
FROM (
SELECT user_id,
       login__ifit__email,
       personal__firstname,
       personal__lastname,
       age,
       tenure,
       personal__gender,
       country_cleaned,
       series,
       equip_type
FROM (
SELECT acu.*,
       flash_types,
       flash_count,
       CASE WHEN flash_count >= 3 THEN 1 ELSE 0 END AS flash_user
FROM actual_chal_users acu
LEFT JOIN (
        SELECT user_id,
               CASE WHEN workout_id IN ('5fe4db6f05b676000770ea7c', '5fff633ad85b630007402f7d',
                        '5d53177fe2ce8d006c6becc9') THEN 'TREADMILL'
                    WHEN workout_id IN ('5fb8401d35db71000809bcc9','6009ec05f240ca000892e51f',
                        '5fbd54c99323c800081166c0') THEN 'BIKE'
                    WHEN workout_id IN ('5e1cc5659831140038e3cb31', '5db87bfa6a3ee407f1fe0c52',
                        '5cb6294a1643740284ede920') THEN 'ELLIP'
                    WHEN workout_id IN ('5c194f844ea1890053ee8ed7', '5dd44b19f245f50079289f0c',
                        '5c6464fb01ca6501f96b7ac3') THEN 'ROWER'
                    WHEN workout_id IN ('5f623d919d2d9b00079727ba', '5eebd9eed24d6d00073823b0',
                        '5dcc4d124e8e6000f07cdfdb') THEN 'STRENGTH'
                END AS flash_types,
                count(*) as flash_count
        FROM unique_logs ul
        WHERE workout_id IN ('5fe4db6f05b676000770ea7c','5fff633ad85b630007402f7d',
                        '5d53177fe2ce8d006c6becc9','5fb8401d35db71000809bcc9','6009ec05f240ca000892e51f',
                        '5fbd54c99323c800081166c0','5e1cc5659831140038e3cb31', '5db87bfa6a3ee407f1fe0c52',
                        '5cb6294a1643740284ede920','5c194f844ea1890053ee8ed7', '5dd44b19f245f50079289f0c',
                        '5c6464fb01ca6501f96b7ac3','5f623d919d2d9b00079727ba', '5eebd9eed24d6d00073823b0',
                        '5dcc4d124e8e6000f07cdfdb')
        AND ul."start"::DATE BETWEEN '2021-02-22' AND '2021-02-24'
        GROUP BY 1,2
) flash_wkouts
ON acu.user_id = flash_wkouts.user_id
        AND equip_type = flash_types
        OR flash_types IS NULL 
)
WHERE flash_user = 0
)
GROUP BY 1

