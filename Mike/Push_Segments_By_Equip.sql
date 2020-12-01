WITH equip_ordered AS (
             SELECT *
             FROM (
                      SELECT ul.*,
                             sc.equipment_type,
                             ROW_NUMBER() OVER (PARTITION BY ul.user_id ORDER BY "start" DESC) as ord_events
                      FROM unique_logs ul
                               JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
                      WHERE equipment_type IN ('Treadmill', 'Bike', 'Elliptical',
                                               'Strider', 'Rower')
                  )
             WHERE ord_events = 1
         )
                           select equipment_type, count(*)  --Change this output as needed
                                  /*user_id,
                                  personal__firstname,
                                  personal__lastname,
                                  login__ifit__email */
                FROM (
                select *
                           FROM (
                                    SELECT user_id,
                                           personal__firstname,
                                           personal__lastname,
                                           login__ifit__email,
                                           equipment_type,
                                           (account__subscription_type || '-' || account__payment_type) as memb_type,
                                           MIN(ord_equip)
                                    FROM (
                                             SELECT u._id   as user_id,
                                                    u.personal__firstname,
                                                    u.personal__lastname,
                                                    u.login__ifit__email,
                                                    eo.equipment_type,
                                                    u.account__subscription_type,
                                                    u.account__payment_type,
                                                    CASE
                                                        WHEN equipment_type = 'Treadmill' THEN 1
                                                        WHEN equipment_type = 'Bike' THEN 2
                                                        WHEN equipment_type IN ('Elliptical', 'Strider') THEN 3
                                                        WHEN equipment_type = 'Rower' THEN 4
                                                        ELSE 0
                                                        END AS ord_equip
                                             FROM prodmongo.users u
                                                      JOIN equip_ordered eo on u._id = eo.user_id
                                             WHERE u.account__subscription_type <> 'free'
                                               AND u.account__payment_type <> 'none'
                                               AND CONVERT_TIMEZONE('AMERICA/DENVER', u.created) >=
                                                   CONVERT_TIMEZONE('AMERICA/DENVER', u.created) - 90
                                               AND COALESCE(u.personal__country, u.shipping__country,
                                                            u.billing__country) IN ('US', 'USA')
                                         )
                                    WHERE ord_equip > 0
                                    GROUP BY 1, 2, 3, 4, 5, 6
                                )
                           GROUP BY 1, 2, 3, 4, 5, 6, 7
                       )
GROUP BY 1
