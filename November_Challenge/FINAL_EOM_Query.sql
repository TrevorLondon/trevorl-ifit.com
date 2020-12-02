--Adjust as needed to get age_groups, etc. The subqueries at the bottom were an attempt to grab users that have completed a prior challenge

SELECT count(*)
from (
         SELECT DISTINCT user_id, personal__gender
         FROM (
                  SELECT user_id,
                         personal__firstname,
                         personal__lastname,
                         login__ifit__email,
                         series_name,
                         wkout_count,
                         personal__gender,
                         age,
                         tenure_years,
                         country
                  FROM (
                           SELECT ul.user_id,
                                  u.personal__firstname,
                                  u.personal__lastname,
                                  u.login__ifit__email,
                                  u.personal__gender,
                                  COALESCE(u.personal__country, u.shipping__country, u.billing__country) as country,
                                  DATEDIFF('year', u.personal__birthday, GETDATE())                      AS age,
                                  DATEDIFF('year', u.created, GETDATE())                                 as tenure_years,
                                  p."title"                                                              as series_name,
                                  count(*)                                                               as wkout_count,
                                  CASE
                                      WHEN p._id = '5d8d43c4d0f6180374d90363' THEN 10
                                      WHEN p._id = '5e53f245dc5c7d07a24db51a' THEN 10
                                      WHEN p._id = '5dc1ebcdd3f35000a9cae5d7' THEN 5
                                      WHEN p._id = '5ef0e0663dbc5f026cddfacf' THEN 4
                                      END                                                                AS adjusted_series_wkout_completed,
                                  CASE
                                      WHEN p._id = '5d8d43c4d0f6180374d90363' THEN 12
                                      WHEN p._id = '5e53f245dc5c7d07a24db51a' THEN 12
                                      WHEN p._id = '5dc1ebcdd3f35000a9cae5d7' THEN 7
                                      WHEN p._id = '5ef0e0663dbc5f026cddfacf' THEN 6
                                      END                                                                AS series_set_wkouts
                           FROM unique_logs ul
                                    JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
                                    JOIN prodmongo.programs p on pw.programs_id = p._id
                                    JOIN prodmongo.users u on ul.user_id = u._id
                           WHERE COALESCE(CONVERT_TIMEZONE(u.personal__tz, ul."start"),
                                          CONVERT_TIMEZONE('AMERICA/DENVER', ul."start"))
                               BETWEEN '2020-11-02' AND '2020-11-30'
                             AND p._id IN ('5d8d43c4d0f6180374d90363',
                                           '5e53f245dc5c7d07a24db51a',
                                           '5dc1ebcdd3f35000a9cae5d7',
                                           '5ef0e0663dbc5f026cddfacf')
                             --AND COALESCE(u.personal__country, u.shipping__country, u.billing__country)
                           GROUP BY 1, 2, 3, 4, 5, 6, personal__birthday, created, adjusted_series_wkout_completed,
                                    series_set_wkouts,
                                    p."title"
                       )
                  WHERE wkout_count >= adjusted_series_wkout_completed
              )
     )
WHERE user_id IN (
    SELECT DISTINCT user_id from all_challenges_users
    )
OR user_id IN (
    SELECT DISTINCT user_id from tl_oct_challenge_users
    )
