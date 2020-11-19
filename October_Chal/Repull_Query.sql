WITH champs AS (
SELECT * 
FROM (
SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id, wkout_group ORDER BY series_set_wkouts DESC) as ord_group
FROM (
SELECT * 
FROM (
SELECT user_id,
	   program_id,
	   series_name,
	   count(*) as wkout_count,
	   series_set_wkouts,
	   wkout_group
	   --ROW_NUMBER() OVER (PARTITION BY user_id, wkout_group ORDER BY series_set_wkouts DESC) as ord_group
FROM (
	SELECT ul.user_id,
	   p._id as program_id,
	   p."title" as series_name,
	   ul.workout_id,
	   ul."start" as utc_start,
	   CONVERT_TIMEZONE(u.personal__tz,ul."start") as local_start,
	   ul.duration,
	   CASE WHEN p._id = '5f74bbba9594ce07a5f67ecc' THEN 7
	   		WHEN p._id = '5f74b9ac8bed3101305b5a2e' THEN 11
	   		WHEN p._id = '5f74b2d7497642038b52a66d' THEN 13
	   		WHEN p._id = '5f74b8a6d3692201c837aa1f' THEN 9
	   		WHEN p._id = '5f74bd0bcbb7c808078b2afa' THEN 5
	   		WHEN p._id = '5f74bc74e71b30024dd5467f' THEN 9
	   	END AS series_set_wkouts,
	   	CASE WHEN p._id IN ('5f74b2d7497642038b52a66d', '5f74b8a6d3692201c837aa1f')
	   			THEN 'A'
	   		WHEN p._id IN ('5f74b9ac8bed3101305b5a2e', '5f74bbba9594ce07a5f67ecc')
	   			THEN 'B'
	   		WHEN p._id IN ('5f74bc74e71b30024dd5467f', '5f74bd0bcbb7c808078b2afa')
	   			THEN 'C'
	   	END as wkout_group
	FROM unique_logs ul
	JOIN prodmongo.users u on ul.user_id = u._id
	JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
	JOIN prodmongo.programs p on pw.programs_id = p._id
	WHERE CONVERT_TIMEZONE(u.personal__tz,ul."start")::DATE BETWEEN '2020-10-01' AND '2020-10-31'
	AND p._id IN ('5f74b2d7497642038b52a66d',
	'5f74b8a6d3692201c837aa1f',
	'5f74b9ac8bed3101305b5a2e',
	'5f74bbba9594ce07a5f67ecc',
	'5f74bc74e71b30024dd5467f',
	'5f74bd0bcbb7c808078b2afa')
	)
GROUP BY user_id, program_id, series_name, series_set_wkouts, wkout_group
)
WHERE wkout_count >= series_set_wkouts
)
)
WHERE ord_group = 1
)
SELECT c.user_id,
           c.program_id,
	   u.login__ifit__email,
	   u.personal__firstname,
	   u.personal__lastname,
	   u.personal__country,
	   c.series_name,
	   c.wkout_count,
	   u.personal__gender,
	   DATEDIFF(year,u.personal__birthday,GETDATE()) as age,
	   DATEDIFF(year,u.created::date,getdate()) as tenure_years
FROM champs c
JOIN prodmongo.users u on c.user_id = u._id
WHERE personal__country IN ('US', 'USA')
