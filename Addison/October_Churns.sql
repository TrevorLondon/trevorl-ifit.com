SELECT u._id as user_id,
       u.login__ifit__email as email,
       u.personal__firstname as first_name,
       u.personal__lastname as last_name,
       CASE WHEN churned.prev_memb_type = 'coach-plus' AND churned.prev_payment_type IN ('yearly', 'two-year') then 'FAMILY YEARLY'
            WHEN churned.prev_memb_type = 'coach-plus' AND churned.prev_payment_type = 'monthly' THEN 'FAMILY MONTHLY'
            WHEN churned.prev_memb_type = 'premium' AND churned.prev_payment_type IN ('yearly', 'two-year') THEN 'INDIVIDUAL YEARLY'
            WHEN churned.prev_memb_type = 'premium' AND churned.prev_payment_type = 'monthly' THEN 'INDIVIDUAL MONTHLY'
            WHEN churned.prev_memb_type = 'premium-non-equipment' AND churned.prev_payment_type IN ('yearly', 'two-year') THEN 'NON-EQ YEARLY'
            WHEN churned.prev_memb_type = 'premium-non-equipment' AND churned.prev_payment_type = 'monthly' THEN 'NON-EQ MONTHLY'
            END AS churned_from_membership_type
FROM prodmongo.users u
JOIN (
        SELECT * FROM (
        select *, LAG(subscription_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_memb_type,
                LAG(payment_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_payment_type,
                LAG(user_type,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_user_type
        from users__account_history 
        --WHERE CONVERT_TIMEZONE('America/Denver',start_date)::date BETWEEN '2020-10-01' AND '2020-10-31'
        )
        WHERE CONVERT_TIMEZONE('America/Denver',start_date)::date BETWEEN '2020-10-01' AND '2020-10-31'
        AND user_type = 'Free' and prev_user_type = 'Paid'
        AND prev_payment_type <> 'none' 
        AND is_secondary = 0
        AND end_date IS NULL
) churned 
on u._id = churned.users_id
