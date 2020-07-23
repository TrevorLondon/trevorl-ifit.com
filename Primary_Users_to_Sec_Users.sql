/*Count of actively paid primary users that have NO secondary users on account */
SELECT distinct(users_id), login__ifit__email, personal__firstname, personal__lastname
FROM (
SELECT uah.*, created::date as Joined_Date, login__ifit__email, personal__firstname, personal__lastname
FROM users__account_history uah
JOIN prodmongo.users u on uah.users_id = u._id
WHERE end_date IS NULL
AND uah.is_secondary = '0'
AND subscription_set_to = 'coach-plus'
)
/* Count of actively paid primary users that have secondary users on account - CORRECTED */
SELECT distinct(_id), login__ifit__email, personal__firstname, personal__lastname
FROM prodmongo.users
JOIN (
        select * from (
        select *, row_number() over (partition by primary_user_id order by start_date DESC) as Num_Sec_Users
        from users__account_history 
        where is_secondary = '1'
        AND end_date IS NULL
        )
        WHERE num_sec_users <= 3
        ) Primary_Users_With_Secs
on users._id = primary_users_with_secs.primary_user_id
WHERE account__subscription_type = 'coach-plus'
