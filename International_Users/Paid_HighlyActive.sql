SELECT user_id,
                personal__firstname,
                personal__lastname,
                login__ifit__email,
                country,
                wkouts
         FROM (
                  SELECT ul.user_id,
                         u.personal__firstname,
                         u.personal__lastname,
                         u.login__ifit__email,
                         COALESCE(u.billing__country, u.shipping__country, u.personal__country) AS country,
                         (u.account__subscription_type || ' ' || u.account__payment_type)       as memb_type,
                         u.account__trial_membership,
                         uah.user_type,
                         count("start")                                                         as wkouts
                  FROM unique_logs ul
                           JOIN prodmongo.users u on ul.user_id = u._id
                           JOIN (
                      SELECT users_id, user_type
                      FROM (
                               SELECT *
                               FROM (
                                        SELECT *,
                                               ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY start_date DESC) as ord_events
                                        FROM users__account_history
                                    )
                               WHERE ord_events = 1
                           )
                  ) uah
                                ON u._id = uah.users_id
                  WHERE DATEDIFF('DAY', CONVERT_TIMEZONE('AMERICA/DENVER', ul."start")::DATE, GETDATE()) <= 90
                    AND COALESCE(u.billing__country, u.shipping__country, u.personal__country) NOT IN
                        ('US', 'USA', 'United States', 'CA', 'Canada')
                    AND COALESCE(u.billing__country, u.shipping__country, u.personal__country) IS NOT NULL
                    AND COALESCE(u.billing__country, u.shipping__country, u.personal__country) NOT LIKE ('%Can%')
                  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
              )
         WHERE user_type = 'Paid'
         AND wkouts >= 30
         AND country <> 'Other'
