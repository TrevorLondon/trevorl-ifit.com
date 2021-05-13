with activity_log_equipment as (
    select 
        WEBSITE_USER_ID,
        ACTIVITY_DATE,
        ACTIVITY_SOFTWARE_NUMBER,
        EQUIPMENT_PRODUCT_SPEC_WIFI as WIFI,
        EQUIPMENT_PRODUCT_ID as epd,
        EQUIPMENT_PROMO_PRICE,
        ROW_NUMBER() over (partition by A.WEBSITE_USER_ID, A.ACTIVITY_SOFTWARE_NUMBER order by A.ACTIVITY_DATE asc) as ord_softwares
    from ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG A 
        left join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_EQUIPMENT B on A.ACTIVITY_SOFTWARE_NUMBER = B.EQUIPMENT_SOFTWARE_NUMBER
    where 
        ACTIVITY_SOFTWARE_NUMBER < 700000
        and LOWER(EQUIPMENT_PRODUCT_LINE_SUBTYPE) not like '%app%'
)
,
swn_ordered_count as (
    select 
        *,
        ROW_NUMBER() over (partition by WEBSITE_USER_ID order by ACTIVITY_DATE) as swn_ordered
    from activity_log_equipment
    where ORD_SOFTWARES = 1
    order by WEBSITE_USER_ID, ORD_SOFTWARES
)
,
cohort as (
    select 
       WEBSITE_USER_ID,
       swn_ordered as software_count,
       ACTIVITY_DATE as first_software_initial_log,
       ACTIVITY_SOFTWARE_NUMBER as first_swn,
       epd as first_epd,
       EQUIPMENT_PROMO_PRICE as first_promo_price,
       WIFI as first_wifi,
       LEAD(ACTIVITY_DATE,1) over (partition by WEBSITE_USER_ID order by SWN_ORDERED) as second_software_initial_log,
       LEAD(ACTIVITY_SOFTWARE_NUMBER,1) over (partition by WEBSITE_USER_ID order by SWN_ORDERED) as second_swn,
       LEAD(epd,1) over (partition by WEBSITE_USER_ID order by SWN_ORDERED) as second_epd,
       LEAD(WIFI,1) over (partition by WEBSITE_USER_ID order by SWN_ORDERED) as second_wifi,
       LEAD(EQUIPMENT_PROMO_PRICE,1) over (partition by WEBSITE_USER_ID order by SWN_ORDERED) as second_promo_price
    from swn_ordered_count
    where swn_ordered < 3
    
)
,
cohort_users as (
    select 
        c.WEBSITE_USER_ID,
        du.USER_COHORT_DATE as join_date,
        (du.COHORT_SUBSCRIPTION_TYPE || '/' || du.COHORT_PAYMENT_INTERVAL) as cohort_memb_type,
        DATEDIFF('DAY', du.USER_COHORT_DATE, GETDATE()) as tenure,
        (du.USER_SUBSCRIPTION_TYPE || '/' || du.USER_PAYMENT_TYPE) as current_memb_type,
        c.first_software_initial_log,
        c.first_swn,
        c.first_promo_price,
        c.first_wifi,
        c.second_software_initial_log,
        c.second_swn,
        c.second_promo_price,
        c.second_wifi,
        du.ACCOUNT_HISTORY_ORIGIN
    from cohort c 
    join ANALYTICS_WAREHOUSE.DIM_USERS du on c.WEBSITE_USER_ID = du.WEBSITE_USER_ID
    WHERE second_software_initial_log IS NOT NULL 
)
,
retained as (
	select cu.WEBSITE_USER_ID,
		   cu.join_date,
           cu.first_wifi,
		   DATEADD('day', 395, CONVERT_TIMEZONE('America/Denver', cu.join_date)::DATE)::DATE AS ann_day,
		   CONVERT_TIMEZONE('America/Denver', fduh.date_actual)::DATE as calendar_day,
       	   CASE WHEN fduh.historical_paid_trial_free_member = 'Paid' THEN 1 ELSE 0 END AS retained
    from cohort_users cu 
    JOIN analytics_revenue_mart.fact_daily_user_history fduh on cu.WEBSITE_USER_ID = fduh.WEBSITE_USER_ID
    	AND CONVERT_TIMEZONE('America/Denver', fduh.date_actual)::DATE >= cu.join_date 
        AND CONVERT_TIMEZONE('America/Denver', fduh.date_actual)::DATE < CONVERT_TIMEZONE('America/Denver', GETDATE())::DATE
)
,
months_calc AS (
  SELECT cu.website_user_id,
         cu.join_date,
         ROW_NUMBER() OVER (PARTITION BY fduh.website_user_id ORDER BY fduh.date_actual::DATE) as ord_months
  FROM cohort_users cu 
  LEFT JOIN analytics_revenue_mart.fact_daily_user_history fduh on cu.website_user_id = fduh.website_user_id
      --AND TO_DATE(CONVERT_TIMEZONE('UTC','America/Denver', CAST(fduh.date_actual as timestamp_ntz))) >= ub.cohort_date
      --AND TO_DATE(CONVERT_TIMEZONE('UTC','America/Denver', CAST(fduh.date_actual as timestamp_ntz))) < TO_DATE(CONVERT_TIMEZONE('UTC','America/Denver', CAST(GETDATE() as timestamp_ntz)))
      AND CONVERT_TIMEZONE('America/Denver', fduh.date_actual)::DATE >= cu.join_date
      AND CONVERT_TIMEZONE('America/Denver', fduh.date_actual)::DATE < CONVERT_TIMEZONE('America/Denver', GETDATE())::DATE 
      AND fduh.is_last_day_of_month = 1
 )
SELECT date_trunc('month', r.join_date::DATE)::DATE as cohort,
       --date_trunc('month', r.ann_day::DATE)::DATE as ann_day,
       COUNT(distinct r.website_user_id) AS month_0, 
       SUM(CASE WHEN ord_months = 1 and r.retained = 1 THEN 1 ELSE 0 END) AS month_1, --r.calendar_day = DATEADD('day', (30.385*ord_months), )) as month_1,
       SUM(CASE WHEN ord_months = 2 and r.retained = 1 THEN 1 ELSE 0 END) AS month_2,
       SUM(CASE WHEN ord_months = 3 and r.retained = 1 THEN 1 ELSE 0 END) AS month_3,
       SUM(CASE WHEN ord_months = 4 and r.retained = 1 THEN 1 ELSE 0 END) AS month_4,
       SUM(CASE WHEN ord_months = 5 and r.retained = 1 THEN 1 ELSE 0 END) AS month_5,
       SUM(CASE WHEN ord_months = 6 and r.retained = 1 THEN 1 ELSE 0 END) AS month_6,
       SUM(CASE WHEN ord_months = 7 and r.retained = 1 THEN 1 ELSE 0 END) AS month_7,
       SUM(CASE WHEN ord_months = 8 and r.retained = 1 THEN 1 ELSE 0 END) AS month_8,
       SUM(CASE WHEN ord_months = 9 and r.retained = 1 THEN 1 ELSE 0 END) AS month_9,
       SUM(CASE WHEN ord_months = 10 and r.retained = 1 THEN 1 ELSE 0 END) AS month_10,
       SUM(CASE WHEN ord_months = 11 and r.retained = 1 THEN 1 ELSE 0 END) AS month_11,
       SUM(CASE WHEN ord_months = 12 and r.retained = 1 THEN 1 ELSE 0 END) AS month_12,
       SUM(CASE WHEN ord_months = 13 and r.retained = 1 THEN 1 ELSE 0 END) AS month_13
       --reactivated_calc.reactivations
FROM retained r 
LEFT JOIN months_calc mc on r.website_user_id = mc.website_user_id
    AND r.calendar_day = DATEADD('day', (30.385*ord_months), r.join_date)::DATE
/*LEFT JOIN (
    SELECT date_trunc('month', reactivation_date_retention_metric::DATE)::DATE as reactivation_date_retention_metric, 
           count(*) as reactivations 
    FROM analytics_warehouse.dim_users
    JOIN cohort_users cu on dim_users.website_user_id = cu.website_user_id
    GROUP BY 1
) reactivated_calc
ON date_trunc('month', r.ann_day)::DATE = date_trunc('month', CONVERT_TIMEZONE('America/Denver', reactivated_calc.reactivation_date_retention_metric)::DATE)::date --TO_DATE(CONVERT_TIMEZONE('UTC','America/Denver', CAST(reactivated_calc.reactivation_date_retention_metric as timestamp_ntz))) */
WHERE r.ann_day >= '2019-06-01'
AND first_wifi = 'Glass'
GROUP BY 1
ORDER BY 1 DESC 
LIMIT 200

