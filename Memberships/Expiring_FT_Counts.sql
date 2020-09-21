SELECT order_date, subscription_set_to, payment_set_to, count(*)
FROM (
SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id order by order_date ASC) as events
FROM (
SELECT o.user_id, CONVERT_TIMEZONE('America/Denver',o.updated_at)::date as order_date, 
        CONVERT_TIMEZONE('America/Denver',uah."date")::date as uah_date, uah.subscription_set_to, uah.payment_set_to
FROM prodmongo.orders o
JOIN prodmongo.users__account_history uah on o.user_id = uah.users_id
        AND CONVERT_TIMEZONE('America/Denver',o.order_date)::date = CONVERT_TIMEZONE('America/Denver',uah."date")::date --BETWEEN o.order_date - INTERVAL '1 day' AND o.order_date + INTERVAL '1 day'
WHERE 
o.usdtotal > 0
AND
order_complete > 0
AND
CONVERT_TIMEZONE('America/Denver',updated_at)::date BETWEEN '2020-06-01' AND '2020-08-29'
AND
user_id IN (SELECT orders.user_id 
        FROM prodmongo.orders
        JOIN prodmongo.orders__items oi on orders._id = oi.orders_Id
        JOIN prodmongo.items i on oi.item = i._id
        WHERE promo_code LIKE '1MEMBED'
        OR i.trial_membership = 1) 
)
)
where events = 1
GROUP BY order_date, subscription_set_to, payment_set_to
ORDER BY order_date ASC
