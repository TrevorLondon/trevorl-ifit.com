SELECT DISTINCT user_id FROM(
SELECT * FROM (
SELECT unique_logs.user_id, login__ifit__email, TRIM(LEADING 'America/' FROM personal__tz) as personal__tz, datediff(year, personal__birthday, current_date) as Age, 
        ROUND(personal__weight * 2.2) as personal__weight, personal__gender, sng."name" as Equip_Name,
        account__subscription_type, account__payment_type,
        datediff(month, users."created", current_date) as iFit_Length,
        --live_workout_schedule_id, workout_context,
        SUM(CASE WHEN start_minute IS NOT NULL THEN 1
          WHEN start_minute IS NULL THEN 0
          END) as wkout_count
FROM unique_logs
JOIN prodmongo.workouts on unique_logs.workout_id = workouts._id
JOIN prodmongo.softwarenumbergroups__software_numbers ssn on unique_logs.software_number = ssn.software_numbers
JOIN prodmongo.softwarenumbergroups sng on ssn.softwarenumbergroups_id = sng._id
LEFT JOIN prodmongo.users on unique_logs.user_id = users._id
--JOIN prodmongo.activitylogs on unique_Logs.workout_id = activitylogs.workout_id
WHERE is_live_workout = 'TRUE'
AND start_minute::date >= '2020-05-11'
--AND workout_context IS NOT NULL 
group by unique_logs.user_id, login__ifit__email, personal__tz, Age, personal__weight, personal__gender, sng."name", account__subscription_type, account__payment_type, users."created" 
        --live_workout_schedule_id, workout_context
)
GROUP BY user_id, login__ifit__email, personal__tz, Age, personal__weight, personal__gender, equip_name, account__subscription_type, account__payment_type, ifit_length, wkout_count
        --live_workout_schedule_id, workout_context, wkout_count
)
