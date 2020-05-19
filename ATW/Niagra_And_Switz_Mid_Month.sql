SELECT * FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, 
       shipping__name, shipping__street1, shipping__city, shipping__state, shipping__country, 
       programs_id, "Program", count(*)
FROM (
SELECT *, CASE WHEN workout_id IN ('5e1cbf54d7a7fa003502fd7d',
        '5e1ca98a4d7c6706e0be375d',
        '5e1cb9722ad4be04cddd4034',
        '5e1cc4976dff550033cdfb52',
        '5e2752493ec1b50008b6d92b') THEN 'Niagra'
        ELSE 'Switzerland'
        END as "Program"      
FROM ( 
        SELECT A.user_id, start_minute, duration, workout_id,
             (duration / 1000) as Duration_Secs,
             round((duration / 1000) / target_value, 2) as Percent_Complete,
             login__ifit__email, personal__firstname, personal__lastname, shipping__name,
             shipping__street1, shipping__city, shipping__state, shipping__country, 
             programs_id
        FROM temp_Niag_Switz_Users_TL A
        JOIN unique_logs B on A.user_id = B.user_id
        LEFT JOIN prodmongo.workouts on B.workout_id = workouts._id
        LEFT JOIN prodmongo.programs__workouts on workouts._id = programs__workouts.workouts
        LEFT JOIN prodmongo.users on A.user_id = users._id
 WHERE CONVERT_TIMEZONE('America/Denver', start_minute)::date BETWEEN '2020-05-01' AND '2020-05-19'
 AND workout_id IN ('5c0a9a5030900f00296ad9bc',
'5be32bb8eecaa60028099343',
'5c057363ee28bd002d298d51',
'5bfec6a7d530b8002dfacb3d',
'5c0b03254de9ec00293116a2',
'5c0567f721d1ac002ee57515',
'5bfdd1b4d530b8002dfaca37',
'5be5d6307f9749002daa232e',
'5c01aa9c6bfc03002d51ccb1',
'5c0b0a6c77da50002e8fad45',
'5bfd93a929cd01002f99728d',
'5c0af29730900f00296ada09',
'5c0ae90e0673b4002efeac80',
'5c0ea53d4de9ec00293116e7',
'5c0176f36bfc03002d51cc80',
'5c0707ee92c03100293ccf3e',
'5c0ea76877da50002e8fad85',
'5bb264242ddd620027a8a2c0',
'5be484a6cdf3b10028b4d180',
'5c09b9d330900f00296ad997',
'5e1cbf54d7a7fa003502fd7d',
'5e1ca98a4d7c6706e0be375d',
'5e1cb9722ad4be04cddd4034',
'5e1cc4976dff550033cdfb52',
'5e2752493ec1b50008b6d92b'))
WHERE percent_complete >= 0.7)
GROUP BY user_id, login__ifit__email, personal__firstname, personal__lastname, 
       shipping__name, shipping__street1, shipping__city, shipping__state, shipping__country, 
       programs_id, "Program")
WHERE (program = 'Switzerland' AND count >= 5) 
OR (program = 'Niagra' AND count >= 4)
