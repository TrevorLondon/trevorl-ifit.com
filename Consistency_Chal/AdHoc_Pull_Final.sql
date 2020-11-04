--This is what i finalized and used to pull Users that completed up through week 3 for Mike and Kelsey. 
--This can be used as a foundational layer to build out the automation script

WITH running_champs AS (
WITH tl_users_ids AS (
SELECT tl.user_id,
	   u._id as users_id 
FROM tl_consistency_challenge_users tl
JOIN prodmongo.users u on tl.user_id = u.login__ifit__email
)
SELECT distinct(users_id) 
FROM (
SELECT users_id,
       --count(wkout_week) as consecutive_weeks
       LISTAGG(wkout_week,',') WITHIN GROUP (ORDER BY wkout_week ASC) OVER (PARTITION BY users_id) as ord_weeks
FROM (
SELECT users_id,
	   local_wkout_week_start as wkout_week,
	   count(*)
FROM ( 
SELECT tl.users_id,
	   ul.workout_id,
	   CASE WHEN al.workout_context IN ('scheduledPre','scheduledLive') THEN 'LIVE'
	   		WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
	   		WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
	   		ELSE 'MANUAL'
	   		END AS wkout_type,
	   	DATE_TRUNC('week',CONVERT_TIMEZONE(u.personal__tz,ul."start"))::date as local_wkout_week_start,
	   (local_wkout_week_start + 6) as local_wkout_week_end
FROM tl_users_ids tl
JOIN unique_logs ul on tl.users_id = ul.user_id
LEFT JOIN prodmongo.activitylogs al on ul._id = al._id
	--AND ul.workout_id = al.workout_id
LEFT JOIN workout_store.workouts ws on ul.workout_id = ws._id
LEFT JOIN prodmongo.users u on tl.users_id = u._id
WHERE ul."start"::DATE >= '2020-10-12'
)
WHERE wkout_type <> 'MANUAL'
GROUP BY 1,2
)
WHERE "count" >= 3
group by 1, wkout_week
)
--WHERE ord_weeks LIKE ('2020-10-12,2020-10-19,2020-10-26%')
WHERE ord_weeks LIKE ('2020-10-12,2020-10-19,2020-10-26%')
)
SELECT u.login__ifit__email
FROM running_champs rc
JOIN prodmongo.users u on rc.users_id = u._id
