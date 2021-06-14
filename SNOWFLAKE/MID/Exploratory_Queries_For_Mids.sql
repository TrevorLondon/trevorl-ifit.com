WITH user_base AS (
SELECT es_username,
       pm.value:accountId::varchar as acct_id,
       pm.value:created::DATE as created_date,
       pm.value:customerId::varchar as customer_id,
       pm.value:status::varchar as billing_status,
       pm.value:stripeCustomerid::varchar as stripe_cust_Id
FROM fivetran_database.ifit_website.users, lateral flatten( input => billing:paymentMethods) pm
WHERE _fivetran_deleted = 0
)
SELECT user_payment_mid,
        count(*)
FROM (
SELECT *,
      CASE
        -- payment methods are not delted but marked inactive. So if it is inactive we default to ifit
        WHEN billing_status = 'inactive' THEN 'iFIT'
        WHEN acct_id = 'pk_live_Q0cYTjsTJLWdYuZXgPM07Kjl00tXeIY3JZ' THEN 'NT USA'
        WHEN acct_id = 'pk_live_RWFOVWgwEvLAleFTjGpfiVYd' THEN 'iFIT'
        WHEN acct_id = 'pk_live_xqQaahLEUw7RzeyWDAxsKp2O' THEN 'NT AUD'
        WHEN acct_id = 'pk_live_tBSt7hsKBX5fWFdVhV9ZQig100qujwPvVD' THEN 'NT CA'
        WHEN acct_id = 'pk_live_4joov8zEgmX7Q83QYRJmFRbb00REzwiRlW' THEN 'PF US'
        WHEN acct_id = 'pk_live_AUucCrrnkL68ks2tV2xLgJ2r006jlMP7HW' THEN 'PF AUD'
        WHEN acct_id = 'pk_live_SkbWfEn8FmSLPRXc0fiUwtXK004VJr8U6S' THEN 'PF CA'
        ELSE acct_id
        END AS user_payment_mid 
FROM user_base 
)
GROUP BY 1
limit 100

WITH user_base AS (
SELECT distinct website_user_id
FROM analytics_warehouse.fact_order__orders_items
WHERE order_completed_flag = 1
AND order_settled_flag = 1
AND line_item_total_usd > 0
),
mid as (
SELECT _id, 
       es_username,
       pm.value:accountId::varchar as acct_id,
       pm.value:created::DATE as created_date,
       pm.value:customerId::varchar as customer_id,
       pm.value:status::varchar as billing_status,
       pm.value:stripeCustomerid::varchar as stripe_cust_Id
FROM fivetran_database.ifit_website.users, lateral flatten( input => billing:paymentMethods) pm
WHERE _fivetran_deleted = 0
--AND billing:paymentMethods IS NOT NULL 
       )
SELECT acct_id, count(*)
FROM user_base ub 
JOIN mid on ub.website_user_id = mid._id
GROUP BY 1
