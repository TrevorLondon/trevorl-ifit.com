/***Going forward- map workouts won't have a target_duration but a target_distance, how will manual workouts play out?, testing accounts ***/
SELECT DISTINCT personal__firstname, personal__lastname, login__ifit__email, count(percent_complete) FROM ( 
SELECT * FROM (
SELECT personal__firstname, personal__lastname, login__ifit__email, workout_id, "start",
        target_value, duration,
        CASE WHEN target_value > 0 THEN round((duration / 1000) / target_value,2)
        ELSE NULL 
        END AS percent_complete
       --round((duration / 1000) / target_value, 2) as Percent_Complete
FROM prodmongo.users
JOIN unique_logs on users._id = unique_logs.user_id
JOIN prodmongo.workouts on unique_logs.workout_id = workouts._id
WHERE start_minute::date BETWEEN '2020-06-14' AND '2020-06-20'
AND ((login__ifit__email LIKE '%@ifit.com%')
OR (login__ifit__email IN ('laurelbstewart73@gmail.com',
'joseph.chrisman@gmail.com',
'matthewt+premium@ifit.com',
'emh815@yahoo.com',
'chasewatterson@gmail.com',
'Jacob.thurman@gmail.com')))
)
WHERE percent_complete >= .80
AND personal__lastname <> 'Tester'
)
GROUP BY personal__firstname, personal__lastname, login__ifit__email
