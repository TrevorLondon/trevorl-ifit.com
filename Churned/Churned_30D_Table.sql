DROP TABLE public.Churned_30d 
CREATE TABLE public.Churned_30d AS (
SELECT * FROM (
SELECT *, row_number () over (partition by u1 order by olddate desc) as Events
FROM (
SELECT uah1.users_id as u1, uah1."date" as NewDate, uah1.subscription_set_to as NewSub, 
       uah2.users_id as u2, uah2."date" as OldDate, uah2.subscription_set_to as OldSub,
       uah2.payment_set_to as old_pay_type
FROM 
   prodmongo.users__account_history uah1
JOIN
   prodmongo.users__account_history uah2 on uah1.users_id = uah2.users_id
   AND uah1."date" > uah2."date"
left join prodmongo.users on uah1.users_id = users._id
WHERE uah1."date" > CONVERT_TIMEZONE('America/Denver',GETDATE())::DATE - 30
ORDER BY 
  uah1."date" desc) )
WHERE events = 1 AND newsub = 'free' AND oldsub <> 'free')
