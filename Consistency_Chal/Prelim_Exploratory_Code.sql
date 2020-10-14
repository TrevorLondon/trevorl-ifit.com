-- LISTAGG WITHIN GROUP OVER function essentially concatenates all the values stipulated in the field (ord_weeks) by user_id. 
-- This was a good way to just get my row_numbers in sequential orders on one row to grab everyone that had 1-11 

SELECT DISTINCT(user_id), listagg
FROM (
SELECT *, listagg(ord_weeks) within group (order by ord_weeks) over(partition by user_id) 
FROM(
SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id Order by wkout_week) as ord_weeks
FROM (
SELECT user_id, wkout_week, count(*)
FROM (
SELECT *, case when wkout_type = 'library' AND completion_rate >= 0.70 THEN 1
        when wkout_type = 'map' AND completion_rate >= 10.00 THEN 2
        ELSE 0
        END as wkout_completed
FROM (
SELECT *, CASE WHEN wkout_type = 'library' THEN COALESCE(ROUND((duration / 1000 / target_value),2),0)
        WHEN wkout_type = 'map' THEN COALESCE(((duration / 1000) / 60), 0)
        ELSE NULL
        END as completion_rate
FROM
(
SELECT *, CASE WHEN programs_id IS NULL AND geospatial__total_distance IS NULL THEN 'manual'
        WHEN programs_id IS NULL AND geospatial__total_distance IS NOT NULL THEN 'map'
        WHEN programs_id IS NOT NULL THEN 'library'
        ELSE 'other'
        END as wkout_type
FROM 
(
SELECT ul.*, pw.programs_id, ws."title", ws.geospatial__total_distance, ws.target_value,
        date_trunc('week',"start") as wkout_week
from unique_logs ul
join workout_store.workouts ws on ul.workout_id = ws._id
left join prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
WHERE CONVERT_TIMEZONE('AMERICA/DENVER',"start")::date >= '2020-08-01'
AND ws.target_value > 0
)
)
WHERE wkout_type IN ('map', 'library')
)
)
WHERE wkout_completed IN (1,2)
GROUP BY 1, 2
)
WHERE "count" >= 3
)
)
WHERE listagg = '1234567891011'
