WITH running_champs AS (
WITH tl_users_ids AS (
SELECT tl.user_id,
	   u._id as users_id
FROM tl_consistency_challenge_users tl
JOIN prodmongo.users u on tl.user_id = u.login__ifit__email
)
SELECT distinct users_id
FROM (
SELECT users_id,
       --count(wkout_week) as consecutive_weeks
       LISTAGG(wkout_week,',') WITHIN GROUP (ORDER BY wkout_week ASC) OVER (PARTITION BY users_id) as ord_weeks
FROM (
SELECT users_id,
	   mst_wkout_week_start as wkout_week,
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
	   	DATE_TRUNC('week',CONVERT_TIMEZONE('AMERICA/DENVER',ul."start"))::date as mst_wkout_week_start,
	   (local_wkout_week_start + 6) as local_wkout_week_end,
	   (mst_wkout_week_start + 6) as mst_wkout_week_end
FROM tl_users_ids tl
JOIN unique_logs ul on tl.users_id = ul.user_id
LEFT JOIN prodmongo.activitylogs al on ul._id = al._id
	--AND ul.workout_id = al.workout_id
LEFT JOIN workout_store.workouts ws on ul.workout_id = ws._id
LEFT JOIN prodmongo.users u on tl.users_id = u._id
WHERE CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE >= '2020-10-12'
AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE < '2021-01-04'
)
WHERE wkout_type <> 'MANUAL'
GROUP BY 1,2
)
WHERE "count" >= 3
group by 1, wkout_week
)
WHERE ord_weeks IN ('2020-10-12,2020-10-19,2020-10-26,2020-11-02,2020-11-09,2020-11-16,2020-11-23,2020-11-30,2020-12-07,2020-12-14,2020-12-21,2020-12-28')
    OR ord_weeks IN ('2020-10-12,2020-10-19,2020-10-26,2020-11-02,2020-11-09,2020-11-23,2020-11-30,2020-12-07,2020-12-14,2020-12-21,2020-12-28') 
)
/*SELECT CASE WHEN country IN ('US', 'USA') THEN 'domestic'
            WHEN country NOT IN ('US', 'USA') AND country IS NOT NULL THEN 'intl'
            WHEN country IS NULL THEN 'unknown'
       END AS country_group,
       COUNT(DISTINCT users_id)
from ( */
SELECT rc.users_id,
       u.login__ifit__email,
       u.personal__firstname,
       u.personal__lastname
       --COALESCE(u.personal__country, u.billing__country, u.shipping__country) as country
FROM running_champs rc
JOIN prodmongo.users u on rc.users_id = u._id
/*)
GROUP BY 1 */
