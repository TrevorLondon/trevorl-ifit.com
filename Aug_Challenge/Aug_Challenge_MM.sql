SELECT * FROM (
WITH series_users AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY partition_key DESC) as ordered_wkouts
FROM (
SELECT *,
    CASE WHEN wkout_count >= series_set_wkout_count THEN 1
    WHEN wkout_count < series_set_wkout_count THEN 0
    ELSE NULL
    END AS series_complete,
    CASE WHEN series = 'Bike - Level 1' THEN 'A1'
            WHEN series = 'Bike - Level 2' THEN 'A2'
            WHEN series = 'Bike - Level 3' THEN 'A3'
            WHEN series = 'Tread - Level 1' THEN 'B1'
            WHEN series = 'Tread - Level 2' THEN 'B2'
            WHEN series = 'Tread - Level 3' THEN 'B3'
            WHEN series = 'Elliptical - Level 1' THEN 'C1'
            WHEN series = 'Elliptical - Level 2' THEN 'C2'
            WHEN series = 'Elliptical - Level 3' THEN 'C3'
            WHEN series = 'Rower - Level 1' THEN 'D1'
            WHEN series = 'Rower - Level 2' THEN 'D2'
            WHEN series = 'Rower - Level 3' THEN 'D3'
     END AS partition_key
FROM (
    SELECT user_id, programs_id, series, count(*) as wkout_count, series_set_wkout_count
    FROM (
        SELECT ul.*, pw.programs_id, 
               CASE WHEN pw.programs_id = '5f2836ccd0725300351d72f3' THEN 'Bike - Level 1'
               WHEN pw.programs_id = '5f283b10cc56050034f2255c' THEN 'Bike - Level 2'
               WHEN pw.programs_id = '5f284003bb0f5000798beaf9' THEN 'Bike - Level 3'
               WHEN pw.programs_id = '5f284279241d3f0034c53ad7' THEN 'Tread - Level 1'
               WHEN pw.programs_id = '5f2844b78880b6008f86c2d5' THEN 'Tread - Level 2'
               WHEN pw.programs_id = '5f2847e78191de00cb2e6b7f' THEN 'Tread - Level 3'
               WHEN pw.programs_id =  '5f284e16540656008f74364c' THEN 'Elliptical - Level 1'
               WHEN pw.programs_id = '5f284f004790ad002ff0197d' THEN 'Elliptical - Level 2'
               WHEN pw.programs_id = '5f284fe9c8d37d00decf21db' THEN 'Elliptical - Level 3'
               WHEN pw.programs_id = '5f2850c8241d3f0034c5a12d' THEN 'Rower - Level 1'
               WHEN pw.programs_id = '5f2851a4bb0f5000798c6820' THEN 'Rower - Level 2'
               WHEN pw.programs_id = '5f285255dc294800927a7b92' THEN 'Rower - Level 3'
               ELSE 'Unknown'
               END as series,
               CASE WHEN programs_id = '5f2836ccd0725300351d72f3' THEN TO_NUMBER('11', '99')
               WHEN programs_id = '5f283b10cc56050034f2255c' THEN TO_NUMBER('11', '99')
               WHEN programs_id = '5f284003bb0f5000798beaf9' THEN TO_NUMBER('15', '99')
               WHEN programs_id = '5f284279241d3f0034c53ad7' THEN TO_NUMBER('10', '99')
               WHEN programs_id = '5f2844b78880b6008f86c2d5' THEN TO_NUMBER('10', '99')
               WHEN programs_id = '5f2847e78191de00cb2e6b7f' THEN TO_NUMBER('12', '99')
               WHEN programs_id =  '5f284e16540656008f74364c' THEN TO_NUMBER('10', '99')
               WHEN programs_id = '5f284f004790ad002ff0197d' THEN TO_NUMBER('10', '99')
               WHEN programs_id = '5f284fe9c8d37d00decf21db' THEN TO_NUMBER('12','99')
               WHEN programs_id = '5f2850c8241d3f0034c5a12d' THEN TO_NUMBER('5', '99')
               WHEN programs_id = '5f2851a4bb0f5000798c6820' THEN TO_NUMBER('7', '99')
               WHEN programs_id = '5f285255dc294800927a7b92' THEN TO_NUMBER('8', '99')
               END AS series_set_wkout_count,
               w."title", target_value, 
               round((duration / 1000) / target_value, 2) as percent_complete
        FROM unique_logs ul
        JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts 
        JOIN workout_store.workouts w on ul.workout_id = w._id
        WHERE pw.programs_id IN ('5f2836ccd0725300351d72f3',
        '5f283b10cc56050034f2255c',
        '5f284003bb0f5000798beaf9',
        '5f284279241d3f0034c53ad7',
        '5f2844b78880b6008f86c2d5',
        '5f2847e78191de00cb2e6b7f',
        '5f284e16540656008f74364c',
        '5f284f004790ad002ff0197d',
        '5f284fe9c8d37d00decf21db',
        '5f2850c8241d3f0034c5a12d',
        '5f2851a4bb0f5000798c6820',
        '5f285255dc294800927a7b92')
        AND ul."start"::date BETWEEN '2020-08-05' AND '2020-08-17'
        )
    WHERE percent_complete >= 0.7
    GROUP BY user_id, programs_id, series, series_set_wkout_count
)
)
WHERE series_complete = 1
)
SELECT series_users.user_id, u.login__ifit__email, u.personal__firstname, u.personal__lastname, u.shipping__street1,
        u.shipping__city, u.shipping__state, u.shipping__zip, u.shipping__country, series_users.programs_id, series_users.series, series_users.wkout_count,
        series_users.series_set_wkout_count, series_users.series_complete, series_users.partition_key, series_users.ordered_wkouts, u.personal__gender,
        DATEDIFF(year,personal__birthday,getdate()) as user_age
FROM series_users
JOIN prodmongo.users u on series_users.user_id = u._id
)
WHERE partition_key IN ('A3', 'B3', 'C3', 'D3')
AND shipping__country = 'US'
