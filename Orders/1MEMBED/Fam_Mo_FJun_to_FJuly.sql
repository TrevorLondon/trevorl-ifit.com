-- The outside portion can be changed as needed to get months interested in, etc. --
-- This was devloped to track people that redeemed the '1MEMBED' code and then what they were after it "expired" --
SELECT fiscal_end_month, subscription_set_to, payment_set_to, count(*) 
FROM (
with membed_users as  ( --Getting most recent event in uah with promo code used/ bucketing in fiscal months
SELECT *, CASE WHEN exp_date::date <= '2020-05-31' THEN 'Fisc May'
           WHEN exp_date::date BETWEEN '2020-06-01' AND '2020-06-27' THEN 'Fisc June'
           WHEN exp_date::date BETWEEN '2020-06-28' AND '2020-07-25' THEN 'Fisc July'
           Else 'other'
           END as fiscal_end_month
FROM (
select *,row_number() over (partition by users_id order by "date" DESC) as events,
        CASE WHEN "date" <= '2020-05-31' THEN '<=05/31'
        WHEN "date" BETWEEN '2020-06-01' AND '2020-06-27' THEN 'Fisc June'
        WHEN "date" BETWEEN '2020-06-28' AND '2020-07-25' THEN 'Fisc July'
        Else 'other' 
        END as redeemed_in,
        coalesce(expiration_date_set_to, ("date" + 30)) as exp_date
FROM (
select uah.*, promo_code
from prodmongo.users
join prodmongo.orders o on users._id = o.user_id
join prodmongo.users__account_history uah on o.user_id = uah.users_id
        AND uah.date BETWEEN o.order_date - INTERVAL '30 second' AND o.order_date + INTERVAL '30 second'
where promo_code = '1MEMBED'
)
)
WHERE events = 1
group by 1,2,3,4,5,6,7,8,9
) --joining back on to membed_users to get most recent sub status from uah 
SELECT uah.*, redeemed_in, fiscal_end_month
FROM users__account_history uah
join membed_users on uah.users_id = membed_users.users_id
where end_date IS NULL
)
WHERE fiscal_end_month = 'Fisc July'
AND start_date::date > '2020-06-26'
GROUP BY fiscal_end_month, subscription_set_to, payment_set_to
