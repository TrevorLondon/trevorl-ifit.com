with base as (
SELECT oi.website_user_id,
       oi.order_date,
       oi.sku,
       oi.order_completed_flag,
       oi.line_item_total_usd,
       wu.user_payment_mid
FROM analytics_warehouse.fact_order__orders_items oi
LEFT JOIN analytics_staging.staging_website_users wu on oi.website_user_id = wu.website_user_id
WHERE oi.order_date BETWEEN '2021-07-16' AND '2021-07-20'
AND oi.sku = 'ifrymeauto'
AND oi.order_completed_flag = 1
AND oi.line_item_total_usd > 0
AND wu.is_current_version = 1
)
select date_trunc('day', order_date)::DATE,
       CASE WHEN user_payment_mid LIKE ('%NT%') THEN 'NT'
            WHEN user_payment_mid LIKE ('%PF%') THEN 'PF'
            ELSE 'Other'
        END AS mid, 
       count(*),
       sum(line_item_total_usd) as total_revenue
from base 
group by 1,2
