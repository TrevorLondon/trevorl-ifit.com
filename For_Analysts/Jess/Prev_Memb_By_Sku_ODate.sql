--Jess needed to see all orders with the below SKUs since June 2019 and what membership they came from. 
-- Ran by sku as running all together has a large output

SELECT sap_product_id as sku, CONVERT_TIMEZONE('AMERICA/DENVER',order_date)::DATE as mst_order_date,
        item_total,
        CASE 
             WHEN prev_sub_type = 'coach-plus' and prev_pay_type IN ('monthly','none') THEN 'FAMILY MONTHLY'
             WHEN prev_sub_type = 'coach-plus' and prev_pay_type IN ('yearly','two-year') THEN 'FAMILY YEARLY'
             WHEN prev_sub_type = 'premium' and prev_pay_type IN ('monthly','none') THEN 'INDIVIDUAL MONTHLY'
             WHEN prev_sub_type = 'premium' and prev_pay_type IN ('yearly','two-year') THEN 'INDIVIDUAL YEARLY'
             WHEN prev_sub_type = 'premium-non-equipment' and prev_pay_type IN ('monthly','none') THEN 'NON-EQ MONTHLY'
             WHEN prev_sub_type = 'premium-non-equipment' and prev_pay_type IN ('yearly','two-year') THEN 'NON-EQ YEARLY'
             WHEN prev_sub_type = 'web' and prev_pay_type IN ('monthly','none') THEN 'INDIVIDUAL MONTHLY'
             WHEN prev_sub_type = 'web' and prev_pay_type IN ('yearly','two-year') THEN 'INDIVIDUAL YEARLY'
             WHEN prev_sub_type = 'free' THEN 'FREE'
             ELSE NULL
             END AS prev_membership_type
FROM (
WITH prior_types AS (
select *, LAG(user_type,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_memb,
        LAG(subscription_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) as prev_sub_type,
        LAG(payment_set_to,1) OVER (PARTITION BY users_id ORDER BY start_date) AS prev_pay_type
FROM users__account_history uah
)
SELECT ps.*, i.sap_product_id, o.order_date, o.item_total
FROM prior_types ps
JOIN prodmongo.orders o on ps.users_id = o.user_id 
  AND CONVERT_TIMEZONE('AMERICA/DENVER', ps.start_date)
        BETWEEN CONVERT_TIMEZONE('AMERICA/DENVER',o.order_date) - INTERVAL '1 day'
        AND CONVERT_TIMEZONE('AMERICA/DENVER', o.order_date) + INTERVAL '1 day'
JOIN prodmongo.orders__items oi on o._id = oi.orders_id
JOIN prodmongo.items i on oi.item = i._id
WHERE i.sap_product_id IN ('ifrmme', 'ifrmmewact', 'ifrmse', 'ifrmseact','ifrmsewact', 'ifryme', 'ifryse',
        'ifryseact', 'ifrysewact') 
AND CONVERT_TIMEZONE('AMERICA/DENVER',o.order_date) >= '2019-06-01'
AND is_secondary = 0
AND o.settled = 1
)
WHERE sap_product_id = 'ifrysewact'
ORDER BY mst_order_date DESC
