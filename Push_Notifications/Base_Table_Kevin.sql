--Developed the logic behind incorporating all the several segments for the Push notifications segments

WITH paying_secondary_users AS
    (
        SELECT
            uah.users_id,
            uah.primary_user_id,
            u.account__payment_type,
            u.account__subscription_type
        FROM
            public.users__account_history uah
            JOIN prodmongo.users u ON uah.primary_user_id = u._id
        WHERE
            uah.is_secondary = 1
            AND LOWER(u.account__subscription_type) != 'free'
            AND LOWER(u.account__payment_type) != 'none'
    )
    SELECT
        *
    FROM
        (
            SELECT
                u._id,
                u.created,
                acc.subscription_set_to,
                u.login__ifit__email,
                acc.user_type,
                acc.is_secondary,
                (CASE WHEN live.user_id IS NULL THEN 0 ELSE 1 END) AS completed_live,
                (CASE WHEN fam_sub.primary_user_id IS NULL THEN 0 ELSE 1 END) AS has_secondary,
                equip_users.equipment_type,
                equip_users.wkout_count,
                DATEDIFF(hours, TRUNC(CONVERT_TIMEZONE('America/Denver', u.created)), CURRENT_DATE)/24 AS Num_Days
            FROM
                prodmongo.users u
                JOIN
                    ( -- Pulls most recent
                        WITH acc_act AS (
                            SELECT
                                uah.users_id,
                                uah.subscription_set_to,
                                uah.primary_user_id,
                                uah.is_secondary,
                                uah.user_type,
                                row_number() OVER (PARTITION BY uah.users_id ORDER BY uah.start_date DESC) AS row_number
                            FROM
                                public.users__account_history uah
                            WHERE
                                (LOWER(uah.user_type) != 'free' OR uah.is_secondary = 1)
                            )
                        SELECT acc_act.users_id, acc_act.subscription_set_to, acc_act.is_secondary, acc_act.user_type, acc_act.row_number FROM acc_act WHERE row_number = 1
                    ) acc ON u._id = acc.users_id
                LEFT JOIN
                    ( -- Pulls all users who've completed live workout
                        SELECT DISTINCT al.user_id
                        FROM
                            prodmongo.activitylogs al
                            JOIN prodmongo.users u ON al.user_id = u._id
                        WHERE
                            al.workout_context IN ('scheduledLive', 'scheduledPre')
                            AND TRUNC(CONVERT_TIMEZONE('America/Denver', u.created)) >= CURRENT_DATE - INTERVAL '90 DAY'
                    ) live ON acc.users_id = live.user_id
                LEFT JOIN
                    ( -- Pulls coach users that don't have sub-users
                        WITH stuff AS
                            (
                                SELECT *, row_number() OVER (PARTITION BY uah.users_id ORDER BY uah.start_date DESC) AS row_number
                                FROM public.users__account_history uah
                                WHERE uah.is_secondary = 1
                            )
                        SELECT stuff.primary_user_id FROM stuff WHERE row_number = 1
                    ) fam_sub ON acc.users_id = fam_sub.primary_user_id AND LOWER(u.account__subscription_type) = 'coach-plus'
                LEFT JOIN
                    (
                        SELECT user_id,
                               equipment_type,
                               count(*) as wkout_count
                        FROM (
                                SELECT ul.user_id,
                                ul."start",
                                ul.software_number,
                                sc.equipment_type
                                FROM unique_logs ul
                                JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
                                WHERE equipment_type IN ('Treadmill','Bike','Strider','Rower')
                                AND ul."start" >= CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE()) - 90
                                )
                        GROUP BY 1,2
                        ) equip_users on acc.users_id = equip_users.user_id
            WHERE
                LOWER(u.account__subscription_type) != 'free'
        ) x
    WHERE
        x.Num_Days <= 90;
