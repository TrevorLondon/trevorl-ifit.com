select login__ifit__email from (
select _id, login__ifit__email, "created", account__expiration_date, account__expected_auto_renewal_date, account__subscription_type, account__payment_type
from prodmongo.users
WHERE _id NOT IN (
        select u1 from churned_30d) --takes care of not churning in last 30 days
AND _id NOT IN (
        select u_id from mem_day_segments_final) --takes care of not being new in last 30 days
AND account__expiration_date::date NOT BETWEEN '2020-05-25' AND '2020-05-25' + 90
AND account__expiration_date::date > '2020-05-25'
AND account__expiration_date::date < '2021-05-25'
AND users._id NOT IN (
  SELECT users._id
  FROM prodmongo.users
  WHERE app_billing_token IS NOT NULL 
  AND account__source IN ('android', 'ios')
  AND account__subscription_type <> 'free'
  ))
WHERE account__subscription_type = 'premium' AND account__payment_type = 'yearly'
