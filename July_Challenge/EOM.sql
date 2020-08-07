********FINAL CODE FOR JULY EOM USED BELOW (CHUNK 2 = truly distinct for all of July not on mid-month) ************
**** Identifying people that were in the mid-month pull and have a new completion on the EOM pull*****
SELECT DISTINCT whole_user, whoLE_equip, whole_count, email, firstname, lastname
FROM (
WITH eom_dist_users AS (
SELECT * FROM (
select jmm.user_id as mid_user, jmm.equipment_type as mid_equip, jmm."count" as mid_count, jwm.user_id as whole_user, jwm.equipment_type as whole_equip, jwm."count" as whole_count,
 jwm.login__ifit__email as email, jwm.personal__firstname as firstname, jwm.personal__lastname as lastname
from july_whole_month jwm
LEFT join july_mid_month jmm on jwm.user_id = jmm.user_id
  AND jwm.programs_id = jmm.programs_id
JOIN prodmongo.users on jwm.user_id = users._id
)
WHERE mid_user IS NULL
)
SELECT whole_user, whole_equip, whole_count, email, firstname, lastname
FROM eom_dist_users
JOIN july_mid_month on eom_dist_users.whole_user = july_mid_month.user_id
  AND eom_dist_users.whole_equip <> july_mid_month.equipment_type
)
*********************************************************************************************

SELECT * FROM july_whole_month
where user_id NOT IN (
        select user_id from july_mid_month
        )
select * from july_whole_month 
