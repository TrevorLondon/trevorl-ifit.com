SELECT *, ROUND(((total_wkout_min / 60) / unique_user_count),2) as avg_wkout_hrs_per_user
FROM (
select pw.programs_id, p.title, ROUND(SUM(duration / 60000),2) as total_wkout_min,
        COUNT(distinct user_id) as unique_user_count
FROM unique_logs ul
JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
JOIN prodmongo.programs p on pw.programs_id = p._id
WHERE CONVERT_TIMEZONE('AMERICA/DENVER',"start")::DATE >= '2020-01-01'
group by 1,2 
order by total_wkout_min DESC
)
group by 1,2,3,4
order by total_wkout_min DESC
LIMIT 20
