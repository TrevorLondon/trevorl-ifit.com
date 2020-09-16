CREATE TABLE sept_challenge AS (
WITH series_completed AS (
SELECT user_id, programs_id, count(*) 
FROM (
SELECT ul.user_id, pw.programs_id, ul.type, ul."start", ul.duration, CONVERT_TIMEZONE(personal__tz,"start") as local_tz,
	ROUND((duration / 1000) / ws.target_value, 2) as percent_complete,
	ws.target_value, ws.title
FROM unique_logs ul
JOIN prodmongo.users u on ul.user_id = u._id
JOIN workout_store.workouts ws on ul.workout_id = ws._id
JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
WHERE start_minute::date BETWEEN '2020-09-08' AND '2020-09-30'
AND pw.programs_id IN ('5f340d02ba026d003716a165',
'5f121d3e2ff7e7007f3720bf',
'5f121ee9e020ae00f1335508',
'5f174678ce7af400355e2702',
'5f17549c65904d0034e9659e')
)
WHERE percent_complete >= 0.70
GROUP BY user_id, programs_id
)
SELECT series_completed.user_id, u.login__ifit__email, u.personal__firstname, u.personal__lastname,
        u.shipping__street1, u.shipping__city, u.shipping__state, u.shipping__zip, u.shipping__country,
        series_completed.programs_id, 
        CASE WHEN programs_id = '5f340d02ba026d003716a165' THEN 'Strengthen the Mind'
             WHEN programs_id = '5f121d3e2ff7e7007f3720bf' THEN 'Outdoor HIIT Strength'
             WHEN programs_id = '5f121ee9e020ae00f1335508' THEN 'Power Walking Intervals'
             WHEN programs_id = '5f174678ce7af400355e2702' THEN 'Intro to Endurance Jogging'
             WHEN programs_id = '5f17549c65904d0034e9659e' THEN 'Heartward Yoga Series'
             END AS series_name,
        series_completed."count",
        u.billing__country, 
        CASE WHEN COALESCE(shipping__country,billing__country) = 'US' THEN 1
        ELSE 0
        END AS domestic_user
FROM series_completed
JOIN prodmongo.users u on series_completed.user_id = u._id
)
