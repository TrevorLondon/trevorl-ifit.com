WITH running_champs AS (
SELECT distinct user_id, email
FROM (
SELECT user_id,
        email,
       --count(wkout_week) as consecutive_weeks
       LISTAGG(wkout_week,',') WITHIN GROUP (ORDER BY wkout_week ASC) OVER (PARTITION BY user_id) as ord_weeks
FROM (
SELECT user_id,
           email,
	   mst_wkout_week_start as wkout_week,
	   count(*)
FROM (
SELECT ul.user_id,
       u.login__ifit__email as email,
	   ul.workout_id,
	   CASE WHEN al.workout_context IN ('scheduledPre','scheduledLive') THEN 'LIVE'
	   		WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
	   		WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
	   		ELSE 'MANUAL'
	   		END AS wkout_type,
	   	DATE_TRUNC('week',CONVERT_TIMEZONE(u.personal__tz,ul."start"))::date as local_wkout_week_start,
	   	DATE_TRUNC('week',CONVERT_TIMEZONE('AMERICA/DENVER',ul."start"))::date as mst_wkout_week_start,
	   (local_wkout_week_start + 6) as local_wkout_week_end,
	   (mst_wkout_week_start + 6) as mst_wkout_week_end
FROM unique_logs ul
JOIN prodmongo.activitylogs al on ul._id = al._id
	--AND ul.workout_id = al.workout_id
LEFT JOIN workout_store.workouts ws on ul.workout_id = ws._id
JOIN prodmongo.users u on ul.user_id = u._id
WHERE CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE >= '2020-10-12'
AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE < '2021-01-04'
)
WHERE wkout_type <> 'MANUAL'
GROUP BY 1,2,3
)
WHERE "count" >= 3
group by 1, 2,wkout_week
)
WHERE ord_weeks IN ('2020-10-12,2020-10-19,2020-10-26,2020-11-02,2020-11-09,2020-11-16,2020-11-23,2020-11-30,2020-12-07,2020-12-14,2020-12-21,2020-12-28')
    OR ord_weeks IN ('2020-10-12,2020-10-19,2020-10-26,2020-11-02,2020-11-09,2020-11-23,2020-11-30,2020-12-07,2020-12-14,2020-12-21,2020-12-28') 
)
/*SELECT CASE WHEN country IN ('US', 'USA') THEN 'domestic'
            WHEN country NOT IN ('US', 'USA') AND country IS NOT NULL THEN 'intl'
            WHEN country IS NULL THEN 'unknown'
       END AS country_group,
       COUNT(DISTINCT user_id)
from ( */
SELECT rc.user_id,
       u.login__ifit__email,
       u.personal__firstname,
       u.personal__lastname
       --COALESCE(u.personal__country, u.billing__country, u.shipping__country) as country
FROM running_champs rc
JOIN prodmongo.users u on rc.user_id = u._id
WHERE rc.email NOT IN (
        SELECT user_id FROM tl_consistency_challenge_users
        )
AND (rc.email NOT LIKE ('%@ifit.com%') 
OR rc.email NOT LIKE ('%icon%')
OR rc.email NOT LIKE ('%test%'))
