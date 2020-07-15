/* Used this one in a revised pull. Worked a little cleaner to used program_id, but verify on Derek's sheet that our table incluces all workout_ids that he lists. 
 Also be careful with target_value in the workouts table as some are NULL and will require custom calculation */
 
 SELECT COUNT(DISTINCT user_id) from (
SELECT * FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country, programs_id, 
        CASE WHEN programs_id = '5ecfd8fafe885f00a851909f' THEN 'Treadmill'
         WHEN programs_id = '5ecfdb8e9a331e00308db2c6' THEN 'Bike'
         WHEN programs_id = '5ecfdd7d2747a500f4506925' THEN 'Elliptical'
         WHEN programs_id = '5ecfdc864ecb1a0094defaf7' THEN 'Rower'
         END as Equipment_Type,
        --percent_complete,
        count(start_minute),
       CASE WHEN login__ifit__email LIKE '%@ifit.com%' THEN 1
        ELSE 0
        END as "iFit_Employee" 
FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country, start_minute, programs_id, duration,
        (duration / 1000) as Duration_Secs,
     CASE WHEN workout_id = '5ecff69d4d0bde000873b72a' THEN round((duration / 1000) / 1386, 2)
     WHEN workout_id = '5ecff5384d0bde000873b729' THEN round((duration / 1000) / 1531, 2)
     WHEN workout_id = '5ecff5e6f4965200096969a4' THEN round((duration / 1000) / 1720, 2)
     WHEN workout_id = '5ecff8d4f4965200096969b0' THEN round((duration / 1000) / 1201, 2)
     ELSE round((duration / 1000) / target_value, 2) 
     END as percent_complete
FROM unique_logs
JOIN prodmongo.programs__workouts pw on unique_logs.workout_id = pw.workouts
LEFT JOIN prodmongo.workouts on unique_logs.workout_id = workouts._id
JOIN prodmongo.users on unique_logs.user_id = users._id
WHERE start_minute::date BETWEEN '2020-06-01' AND '2020-06-30'
AND programs_id IN ('5ecfd8fafe885f00a851909f',
'5ecfdb8e9a331e00308db2c6',
'5ecfdd7d2747a500f4506925',
'5ecfdc864ecb1a0094defaf7')
AND user_id = '5e652ea88cac67002c4a1184'
)
WHERE percent_complete >= 0.7
GROUP BY user_id, programs_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country
)
WHERE COUNT >= 7
)
