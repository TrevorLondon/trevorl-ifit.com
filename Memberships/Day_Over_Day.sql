-- Created this with Tyson to provide a day over day view of new memberships. Dates can be amended as needed. 
-- Companion script with this in the Expiring_FT_Count script within this same file

SELECT created, user_type, count(*) 
FROM (
SELECT *, 
        CASE WHEN subscription_set_to = 'premium' AND payment_set_to = 'monthly' AND trial_membership = 1 
                THEN 'Trial'
             WHEN subscription_set_to = 'premium' AND payment_set_to = 'monthly' AND trial_membership = 0
                THEN 'Individual Monthly'
             WHEN subscription_set_to = 'premium' AND payment_set_to = 'yearly' AND trial_membership = 0
                THEN 'Individual Yearly'
             WHEN subscription_set_to = 'coach-plus' AND payment_set_to = 'monthly' THEN 'Fam Monthly'
             WHEN subscription_set_to = 'coach-plus' AND payment_set_to = 'yearly' THEN 'Fam Yearly'
             WHEN promo_code = '1MEMBED' THEN 'Trial'
             ELSE 'other'
             END AS user_type
from (
select *, row_number() over (partition by _id order by "date" DESC) as events 
fROM (
select u._id, CONVERT_TIMEZONE('America/Denver', "created")::date as created, CONVERT_TIMEZONE('America/Denver',uah."date") as "date", uah.subscription_set_to, uah.payment_set_to, o.promo_code, i.trial_membership
from prodmongo.users u
join prodmongo.users__account_history uah on u._id = uah.users_id
  AND uah."date" BETWEEN u.created - INTERVAL '1 day' AND u.created + INTERVAL '1 day'
LEFT JOIN prodmongo.orders o on u._id = o.user_id
  AND o.order_date BETWEEN u.created - INTERVAL '1 day' AND u.created + INTERVAL '1 day'
LEFT JOIN prodmongo.orders__items oi on o._id = oi.orders_id
LEFT JOIN prodmongo.items i on oi.item = i._id
where CONVERT_TIMEZONE('America/Denver',"created")::date > '2020-05-31'
)
)
where events = 1
)
GROUP BY created, user_type
ORDER BY created ASC
