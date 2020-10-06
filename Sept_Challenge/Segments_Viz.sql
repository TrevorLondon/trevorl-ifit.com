-- Used different variants of this general idea to get workout counts by program, gender, etc.
SELECT personal__gender, count(*) from (
SELECT DISTINCT(user_id),
        CASE WHEN age <= 20 THEN '<=20'
        WHEN age BETWEEN 21 and 30 THEN '21-30'
        WHEN age BETWEEN 31 and 40 THEN '31-40'
        WHEN age between 41 and 50 THEN '41-50'
        WHEN age between 51 and 60 then '51-60'
        WHEN age > 60 THEN '>60'
        END as age_group, 
        personal__gender,
        count(series_name) as series_comp
FROM (
WITH dups_removed AS (
        SELECT user_id, programs_id, workout_id, title, duration,
        CASE WHEN programs_id IN ('5f340d02ba026d003716a165','5f57b6f2fbe59c003add0bd7') THEN 'Strengthen the Mind'
             WHEN programs_id = '5f121d3e2ff7e7007f3720bf' THEN 'Outdoor HIIT Strength'
             WHEN programs_id IN ('5f121ee9e020ae00f1335508','5f174849b526c1002ecae9d2') THEN 'Power Walking Intervals'
             WHEN programs_id IN ('5f174678ce7af400355e2702','5f174f6a5bed99002d4fd9b4') THEN 'Intro to Endurance Jogging'
             WHEN programs_id = '5f17549c65904d0034e9659e' THEN 'Heartward Yoga Series'
             END AS series_name
        FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY user_id, title ORDER BY duration DESC) as ord_events, user_id, programs_id, workout_id, "title", duration
        FROM (
        SELECT ul.*, pw.programs_id, ws."title",
        ROUND((duration / 1000 / ws.target_value),2) as percent_complete
        from unique_logs ul
        join prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
        join workout_store.workouts ws on ul.workout_id = ws._id
        join prodmongo.users u on ul.user_id = u._id
        where programs_id IN ('5f340d02ba026d003716a165',
                '5f57b6f2fbe59c003add0bd7',
                '5f121d3e2ff7e7007f3720bf',
                '5f121ee9e020ae00f1335508',
                '5f174849b526c1002ecae9d2',
                '5f174678ce7af400355e2702',
                '5f174f6a5bed99002d4fd9b4',
                '5f17549c65904d0034e9659e')
        AND CONVERT_TIMEZONE(personal__tz,start_minute)::date BETWEEN '2020-09-01' AND '2020-09-30'
        )
        WHERE percent_complete >= 0.70
        )
        WHERE ord_events = 1
)
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname, shipping__street1, 
        shipping__city, shipping__state, shipping__zip, shipping__country, domestic_user, series_name,
        age, personal__gender, series_count
FROM ( 
SELECT * --LAG (series_name,1) OVER (PARTITION BY user_id ORDER BY series_name) as other_completed 
FROM (
SELECT user_id, u.login__ifit__email, u.personal__firstname, u.personal__lastname,
    u.shipping__street1, u.shipping__city, u.shipping__state, u.shipping__zip, 
    u.shipping__country, datediff(year,personal__birthday,getdate()) as age, personal__gender,
    CASE WHEN shipping__country = 'US' THEN 1
    ELSE 0
    END AS domestic_user,
    series_name, 
    count(*) AS series_count
from dups_removed
join prodmongo.users u on dups_removed.user_id = u._id
group by user_id, series_name, 2,3,4,5,6,7,8,9,10,11
)
WHERE series_count >= 6 
)
WHERE domestic_user = 1
)
GROUP BY 1,2,3
)
GROUP BY 1
