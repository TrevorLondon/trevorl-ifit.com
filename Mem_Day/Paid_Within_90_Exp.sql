SELECT * FROM ( 
select * from ( 
select uah.*, ROW_NUMBER() OVER (PARTITION BY users_id ORDER BY "date" DESC) as Most_Recent, login__ifit__email,
    CASE WHEN (billing__stripe_customer_id IS NOT NULL 
                OR(
                (billing__tokenizer = 'paymetric' OR billing__tokenizer = 'cybersource')
                AND billing__token IS NOT NULL 
                AND billing__card_type IS NOT NULL
                AND billing__zip IS NOT NULL 
                )
               )
               AND DATE_TRUNC('day', COALESCE(CONVERT_TIMEZONE('UTC', personal__tz, account__expiration_date), GETDATE()))
               <= LAST_DAY(TO_DATE('20' || billing__year || '-' || billing__month || '-' || '01', 'YYYY-MM-DD'))
             THEN 1
             ELSE 0
             END AS has_billing
FROM prodmongo.users__account_history uah 
LEFT JOIN prodmongo.users on uah.users_id = users._id)
WHERE Most_Recent = 1 AND expiration_date_set_to::date < '2021-05-25')
WHERE (expiration_date_set_to::date BETWEEN '2020-05-25' and '2020-05-25' + 90)
AND payment_set_to <> 'free'
and users_id NOT IN (
        select u_id from mem_day_segments_final)
AND users_id NOT IN (
  SELECT users._id
  FROM prodmongo.users
  WHERE app_billing_token IS NOT NULL 
  AND account__source IN ('android', 'ios')
  AND account__subscription_type <> 'free'
  )
AND subscription_set_to = 'coach-plus' AND payment_set_to = 'yearly'
