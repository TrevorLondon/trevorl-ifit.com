-- Ran this for Mike to grab how many have completed all workouts in the series, but also provided him series_set_wkouts - 1, 2, and 3

SELECT series_name, count(*) FROM (
SELECT ul.user_id,
	   p."title" as series_name,
	   count(*) as wkout_count,
	   CASE WHEN p._id = '5d8d43c4d0f6180374d90363' THEN 12
	   		WHEN p._id = '5e53f245dc5c7d07a24db51a' THEN 12
	   		WHEN p._id = '5dc1ebcdd3f35000a9cae5d7' THEN 7
	   		WHEN p._id = '5ef0e0663dbc5f026cddfacf' THEN 6
	   	END AS series_set_wkouts
FROM unique_logs ul
JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts 
JOIN prodmongo.programs p on pw.programs_id = p._id
JOIN prodmongo.users u on ul.user_id = u._id
WHERE COALESCE(CONVERT_TIMEZONE(u.personal__tz,ul."start"),CONVERT_TIMEZONE('AMERICA/DENVER',ul."start"))
	BETWEEN '2020-11-02' AND '2020-11-30'
AND p._id IN('5d8d43c4d0f6180374d90363',
'5e53f245dc5c7d07a24db51a',
'5dc1ebcdd3f35000a9cae5d7',
'5ef0e0663dbc5f026cddfacf')
AND COALESCE(u.personal__country, u.shipping__country) IN ('US', 'USA')
GROUP BY user_id, series_name, series_set_wkouts
)
WHERE wkout_count >= series_set_wkouts
GROUP BY 1
