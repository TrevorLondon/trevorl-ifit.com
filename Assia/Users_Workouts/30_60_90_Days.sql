--Identifies Users that were created between 16 and 30, 46 and 60, or 76 and 90 days ago that have NEVER done a workout
-- Building an automation script based off this same general logic which will populate the date at which a User that hasn't done a workout hits the 30, 60, 90 days

SELECT _id as user_id, login__ifit__email, personal__firstname, personal__lastname
FROM (
SELECT *, CASE WHEN days_since_started BETWEEN 76 AND 90 THEN 3
        WHEN days_since_started BETWEEN 46 AND 60 THEN 2
        WHEN days_since_started BETWEEN 16 AND 30 THEN 1
        END AS days_bucket
FROM (
SELECT u._id, login__ifit__email, personal__firstname, personal__lastname, created, DATEDIFF(day,created,GETDATE()) as days_since_started
fROM prodmongo.users u
WHERE created >= GETDATE() - 90
AND u._id NOT IN 
        (SELECT user_id FROM unique_logs) --unique_logs worked
)
)
WHERE days_bucket = 1. -- grab as needed.
