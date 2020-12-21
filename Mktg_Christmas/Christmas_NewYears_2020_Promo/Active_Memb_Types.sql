-- This is for Fam Yearly, Fam Monthly, Ind Yearly (US and Foreign)
-- Did Premium Monthly separately to better filter out Trials

select count(DISTINCT user_id)
FROM (
         SELECT user_id,
                personal__firstname,
                personal__lastname,
                email
                --(account__subscription_type || ' ' || account__payment_type) as memb_type
         FROM (
                  SELECT u._id                                                                  AS user_id,
                         u.login__ifit__email                                                   as email,
                         u.personal__firstname,
                         u.personal__lastname,
                         u.account__subscription_type,
                         u.account__payment_type,
                         u.app_billing_token,
                         u.account__source,
                         COALESCE(u.personal__country, u.shipping__country, u.billing__country) as country,
                         u.is_secondary,
                         CASE
                             WHEN app_billing_token IS NOT NULL AND account__source = 'ios' THEN 'APPLE'
                             WHEN app_billing_token IS NOT NULl AND account__source = 'android' THEN 'GOOGLE'
                             WHEN account__source = 'amazon' THEN 'AMAZON'
                             ELSE 'OTHER'
                             END                                                                AS app_pay
                  FROM prodmongo.users u
                  WHERE account__subscription_type = 'coach-plus'  --update these lines for memb type needed
                    --AND account__payment_type IN ('yearly','two-year')
                    AND account__payment_type = 'monthly'
                    AND is_secondary = 0
                    AND u.account__trial_membership = 0
                    AND u._id NOT IN (  --Built this table of Users that renewed early with the BF/CM
                      SELECT DISTINCT user_id
                      FROM tl_BF_CM_Early_Renewals
                  )
              )
         WHERE app_pay = 'OTHER'
        -- AND (country IN ('US', 'USA') OR country IS NULL)
        AND country NOT IN ('US', 'USA') AND country IS NOT NULL
     )
