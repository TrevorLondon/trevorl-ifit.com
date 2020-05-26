/* Pulling out Trials From Group (not perfect yet) */
SELECT distinct(have_been_trial._id), week_start, wkout_count, user_type, account__subscription_type,
  CASE WHEN account__subscription_type = 'free' THEN 'T'
  ELSE 'F'
  END as Churned_User
FROM prodmongo.users
JOIN (
SELECT * FROM 
(
SELECT q4.*,
        user_type,
        order_date,
        row_number,
        "date"
FROM acq_20_q4_okr_base q4
JOIN
(
SELECT *,
    CASE WHEN trial_membership = 1 AND item_total = 0 AND subscription_set_to <> 'free' THEN 'Trial'
       WHEN subscription_set_to <> 'free' THEN 'Paid'
       WHEN subscription_set_to = 'free' THEN 'Free'
       ELSE NULL
       END AS user_type
FROM
(
  SELECT uah.*, 
          ua.type,
          orders.sku,
          orders.promo_code,
          orders.item_total,
          orders.order_date,
          orders.trial_membership,
          ROW_NUMBER() OVER (PARTITION BY uah.users_id ORDER BY uah.date ASC) as row_number
  FROM prodmongo.users__account_history uah
  LEFT JOIN prodmongo.useractivities ua 
    on uah.users_id = ua.user_id AND uah.date BETWEEN ua.created - INTERVAL '30 second'
      AND ua.created + INTERVAL '30 second'
  LEFT JOIN 
(
  SELECT a._id as orders_id,
          a.user_id,
          a.promo_code,
          a.item_total,
          c.sap_product_id as sku,
          a.order_date,
          c.trial_membership
  FROM prodmongo.orders a
  JOIN prodmongo.orders__items b on a._id = b.orders_id
  JOIN prodmongo.items c on b.item = c._id
  WHERE c.category = 'Account'
) orders
    on uah.users_id = orders.user_id AND uah.date BETWEEN orders.order_date - INTERVAL '30 second'
      and orders.order_date + INTERVAL '30 second'
  WHERE 
    CONVERT_TIMEZONE('America/Denver',uah.date)::date >= '2020-03-01'
) ordered_account_changes
) user_snapshot
    on q4._id = user_snapshot.users_id
GROUP BY 1,2,3,4,5,6,7,8
order by _id, row_number desc)
WHERE user_type = 'Trial') Have_Been_Trial
ON users._id = have_been_trial._id
