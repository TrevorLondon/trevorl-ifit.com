--Wrote this on 10/22 to provide Mike/Julie counts of completed series thus far. Originally pulled using DISTINCT workouts per User (duplicated, completed
-- workouts don't count). Ran removing that (as it is below) and it only changed slightly so NOT using the DISTINCT clause

select COUNT(distinct user_id)
FROM (
SELECT user_id, series, count(workout_title), set_series_wkouts
FROM (
WITH series_count as (
select programs_id, p."title", count(ws._id) as series_set_count
from prodmongo.programs__workouts pw 
join workout_store.workouts ws on pw.workouts = ws._id
join prodmongo.programs p on pw.programs_id = p._id
where pw.programs_id IN ('5f74b2d7497642038b52a66d',
'5f74b8a6d3692201c837aa1f',
'5f74b9ac8bed3101305b5a2e',
'5f74bbba9594ce07a5f67ecc',
'5f74bc74e71b30024dd5467f',
'5f74bd0bcbb7c808078b2afa')
group by 1,2
)
SELECT user_id, programs_id, series, workout_title, 
        count(workout_title) as distinct_completed_workouts,
        CASE WHEN programs_id = '5f74b9ac8bed3101305b5a2e' THEN 11
        WHEN programs_id = '5f74bbba9594ce07a5f67ecc' THEN 7
        ELSE series_set_count
        END as set_series_wkouts
FROM (
select ul.*, ROUND((duration / 1000 / target_value),2) as percent_complete, pw.programs_id, p.title as series, ws."title" as workout_title,
        series_set_count
from unique_logs ul
join prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
join prodmongo.programs p on pw.programs_id = p._id
join workout_store.workouts ws on pw.workouts = ws._id
join series_count on p._id = series_count.programs_id
where pw.programs_id IN ('5f74b2d7497642038b52a66d',
'5f74b8a6d3692201c837aa1f',
'5f74b9ac8bed3101305b5a2e',
'5f74bbba9594ce07a5f67ecc',
'5f74bc74e71b30024dd5467f',
'5f74bd0bcbb7c808078b2afa')
AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start")::DATE >= '2020-10-01'
) 
WHERE percent_complete >= 0.70
GROUP BY 1,2,3,4,6
)
group by 1,2,4
)
WHERE "count" >= set_series_wkouts
group by 1
