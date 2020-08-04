SELECT count(*), sum(miles) 
FROM (
SELECT ul.*, workout_id,
	CONVERT_TIMEZONE(personal__timezone,ul."start") as local_wkout_time,
	round((summary__total_meters / 1609),2) as "miles"
FROM unique_logs ul
--JOIN prodmongo.workouts on ul.workout_id = workouts._id
LEFT JOIN prodmongo.users on ul.user_id = users._id
LEFT JOIN prodmongo.workouts on ul.workout_id = workouts._id
WHERE CONVERT_TIMEZONE('America/Denver',ul."start")::date BETWEEN '2020-08-03' AND '2020-08-04'
--WHERE CONVERT_TIMEZONE(personal__timezone,ul."start")
	--BETWEEN '2020-08-03' AND '2020-08-04'
AND metadata__trainer = '5ae8e4d46f4fbe0027860fa7')
