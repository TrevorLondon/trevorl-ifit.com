SELECT * FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country, programs_id, 
        CASE WHEN programs_id = '5ecea31f375a7b007f25bcbe' THEN 'Walking'
         WHEN programs_id = '5eb5a176a190200137c1338b' THEN 'Bike'
        WHEN programs_id = '5ee7ce6441410a00bdd94cd9' THEN 'Strength'
         --WHEN programs_id = '5ecfdc864ecb1a0094defaf7' THEN 'Rower'
         END as Equipment_Type,
        --percent_complete,
        count(start_minute),
       CASE WHEN login__ifit__email LIKE '%@ifit.com%' THEN 1
        ELSE 0
        END as "iFit_Employee" 
FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country as country, start_minute, programs_id, duration,
        (duration / 1000) as Duration_Secs,
     CASE WHEN workout_id = '5ed6720a4a09d8000831e0cd' THEN round((duration / 1000) / 2139, 2)
     WHEN workout_id = '5ef03cb975394e0007da0344' THEN round((duration / 1000) / 589, 2)
     --WHEN workout_id = '5ecff5e6f4965200096969a4' THEN round((duration / 1000) / 1720, 2)
     --WHEN workout_id = '5ecff8d4f4965200096969b0' THEN round((duration / 1000) / 1201, 2)
     ELSE round((duration / 1000) / target_value, 2) 
     END as percent_complete
FROM unique_logs
JOIN prodmongo.programs__workouts pw on unique_logs.workout_id = pw.workouts
LEFT JOIN prodmongo.workouts on unique_logs.workout_id = workouts._id
JOIN prodmongo.users on unique_logs.user_id = users._id
WHERE start_minute::date BETWEEN '2020-07-01' AND '2020-07-15'
AND programs_id IN ('5ecea31f375a7b007f25bcbe',
'5eb5a176a190200137c1338b',
'5ee7ce6441410a00bdd94cd9')
)
WHERE percent_complete >= 0.7
GROUP BY user_id, programs_id, login__ifit__email, personal__firstname, personal__lastname, shipping__name, shipping__street1,
        shipping__city, shipping__state, shipping__zip, shipping__country
)
WHERE (equipment_type = 'Bike' and count >= 6)
OR (equipment_type <> 'Bike' and count >= 7)
AND shipping__country = 'US'
