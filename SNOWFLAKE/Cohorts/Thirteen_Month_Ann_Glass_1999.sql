WITH reactivations AS (
    SELECT website_user_id,
               (cohort_subscription_type || '/' || cohort_payment_interval) as cohort_memb_type,
               account_history_date as reactivation_date,
               previous_and_current_user_type,
               (previous_subscription_type || '/' || previous_payment_interval) as previous_memb_type,
               (subscription_type || '/' || payment_interval) as reactivated_to_memb_type,
               account_history_reactivation_flag,
               equipment_cohort_equipment_product_spec_wifi as cohort_wifi 
    FROM analytics_revenue_mart.fact_membership_mobility fmm 
    WHERE account_history_reactivation_flag = 1
    AND cohort_memb_type = 'Family/Yearly'
    AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
    AND equipment_cohort_equipment_promo_price >= 1999
),
retained AS (
	select * 
	from (
	SELECT website_user_id,
		   cohort_membership_type,
		   cohort_user_type,
		   de.equipment_product_spec_wifi as cohort_wifi,
		   de.equipment_promo_price as cohort_promo_price,
		   user_cohort_date as first_paid_date,
		   DATE_TRUNC('month', user_cohort_date) as first_paid_month,
		   DATEADD('month', 13, user_cohort_date) as thirteen_months_later,
		   retention_status
	FROM analytics_warehouse.fact_daily_subscriptions fds 
	JOIN analytics_warehouse.dim_users__equipment_cohort due on fds.website_user_id = due.user_equipment_user
	JOIN analytics_warehouse.dim_equipment de on due.user_equipment_software_number = de.equipment_software_number
	WHERE DATEDIFF('MONTH', DATE_TRUNC('MONTH', user_cohort_date), DATE_TRUNC('MONTH', daily_user_history_date)) = 13
	--AND is_last_day_of_month = 1
	)
	WHERE retention_status = 'Retained Same Cohort'
	AND cohort_membership_type = 'Family/Yearly'
	AND cohort_wifi = 'Glass'
	AND cohort_promo_price >= 1999
)
SELECT DATE_TRUNC('MONTH',r.thirteen_months_later)::DATE as reporting_period,
	   r.first_paid_month as cohort_month,
	   count(distinct r.website_user_id) as retained,
	   count(distinct ract.website_user_id) as reactivations
FROM retained r 
LEFT JOIN reactivations ract on DATE_TRUNC('month', r.thirteen_months_later) = DATE_TRUNC('MONTH', ract.reactivation_date)
	 AND ract.website_user_id NOT IN (
	 		select distinct website_user_id
	 		from retained
	 		)
WHERE reporting_period BETWEEN '2018-06-01' AND '2021-04-01'
GROUP BY 1,2
ORDER BY 1
LIMIT 100
