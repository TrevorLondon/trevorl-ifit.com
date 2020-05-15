SELECT * FROM ( 
create table public.Mem_Day_Segments_Final AS
SELECT U_ID, trial_date, convert_date, account__subscription_type, account__payment_type, equipment, segment, churned_user, has_billing,
    md_type, md_sn, login__ifit__email
FROM (
SELECT *, 
        CASE WHEN ua_type = 'amazonActivation' then 'Amazon'
                WHEN pf = 'T' THEN 'Planet Fitness'
                WHEN promo_code = 'FREE30ISO' THEN promo_code
                WHEN readable LIKE '%Freemotion%' AND ua_type <> 'amazonActivation' THEN 'Freemotion'
                 WHEN trial_date > CONVERT_TIMEZONE('America/Denver',GETDATE())::DATE - 30
                      AND convert_date IS NULL THEN 'Activate Trial'
                WHEN account__subscription_type <> 'free' THEN 'Paid'
                Else 'Other'
        END AS "Segment",
        CASE WHEN Churned_User_Id IS NOT NULL THEN 'T' 
                WHEN Churned_User_Id IS NULL THEN 'F'
        END AS Churned_User,
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
FROM(
SELECT * FROM (
SELECT users._id as U_ID, useractivities."type" as UA_Type, login__planet_fitness__membership_managed_by_planet_fitness as PF, useractivities.readable, churned_30D.u1 as Churned_User_Id,
        activate.trial_date, activate.convert_date, billing__stripe_customer_id, billing__tokenizer, billing__token, billing__card_type, 
        billing__zip, account__expiration_date, billing__year, billing__month, personal__tz, mem_day_users.account__subscription_type, 
        mem_day_users.account__payment_type, equipment, mem_day_users."type" as md_type, mem_day_users.software_number as md_sn, orders.promo_code,
        login__ifit__email
FROM Mem_Day_Users
LEFT JOIN prodmongo.users on Mem_Day_Users._id = users._id
LEFT JOIN churned_30D on mem_day_users._id = churned_30D.u1
LEFT JOIN prodmongo.useractivities on mem_day_users._id = useractivities.user_id
        AND (readable LIKE '%Freemotion%' OR useractivities."type" = 'amazonActivation') 
LEFT JOIN (
        select distinct user_id, promo_code from prodmongo.orders
        WHERE promo_code = 'FREE30ISO') orders
   ON mem_day_users._id = orders.user_id
LEFT JOIN (
        select distinct user_id, trial_date, convert_date from activate
          ) activate
         on mem_day_users._id = activate.user_id) Big_Data)))
WHERE segment = 'Activate Trial'         


) group by segment
