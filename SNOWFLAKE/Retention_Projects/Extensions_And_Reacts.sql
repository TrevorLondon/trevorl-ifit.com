*** exten cohort query ***

WITH user_base AS (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       --CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as mst_cohort_date,
       --DATE_TRUNC('month', DATEADD('day', 395, user_cohort_date))::DATE AS reporting_period,
      -- daily_user_history_date::DATE AS ann_day,
       --historical_paid_trial_free_member as user_type_ann_day,
       ua_types.*,
       CASE WHEN ua_types.exten_user_id IS NOT NULL THEN 1 ELSE 0 END AS extension 
from analytics_revenue_mart.fact_daily_user_history fduh
LEFT JOIN (
	select user_id as exten_user_id,
		   user_activity_created,
		   user_activity_type,
		   user_activity_description,
		   row_number() over (partition by user_id order by user_activity_created) as ord_events
	from analytics_staging.staging_useractivities
	where user_activity_type IN ('twoHundredWorkoutsFreeMonthExtension','oneHundredWorkoutsFreeMonthExtension', 'membershipTimeExtended')
	and user_activity_description NOT LIKE ('Membership extended 2%')
	and is_current_version = 1
	) ua_types 
ON fduh.website_user_id = ua_types.exten_user_id 
	AND ua_types.ord_events = 1
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
AND equipment_cohort_equipment_promo_price >= 1999
--AND DATEADD('day', 395, mst_cohort_date)::DATE = daily_user_history_date::DATE 
--AND DATEADD('day', 425, mst_cohort_date)::DATE = daily_user_history_date::DATE
)
select DATE_TRUNC('month', reporting_day)::DATE, count(*)
from (
select website_user_id,
       cohort_user_type,
       cohort_date,
       user_activity_type,
       CASE WHEN exten_user_id IS NOT NULL THEN DATEADD('day', 425, cohort_date)::DATE
            WHEN exten_user_id IS NULL THEN DATEADD('day', 395, cohort_date)::DATE 
       END  AS reporting_day
from user_base ub 
)
WHERE user_activity_type IS NULL 
AND reporting_day >= '2019-06-01' --AND reporting_day < GETDATE()
GROUP BY 1
ORDER BY 1
limit 500


*** exten retained query ***8

WITH user_base AS (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       --CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as mst_cohort_date,
       --DATE_TRUNC('month', DATEADD('day', 395, user_cohort_date))::DATE AS reporting_period,
      -- daily_user_history_date::DATE AS ann_day,
       --historical_paid_trial_free_member as user_type_ann_day,
       ua_types.*,
       CASE WHEN ua_types.exten_user_id IS NOT NULL THEN 1 ELSE 0 END AS extension 
from analytics_revenue_mart.fact_daily_user_history fduh
LEFT JOIN (
      select user_id as exten_user_id,
               user_activity_created,
               user_activity_type,
               user_activity_description,
               row_number() over (partition by user_id order by user_activity_created) as ord_events
      from analytics_staging.staging_useractivities
      where user_activity_type IN ('twoHundredWorkoutsFreeMonthExtension','oneHundredWorkoutsFreeMonthExtension', 'membershipTimeExtended')
      and user_activity_description NOT LIKE ('Membership extended 2%')
      and is_current_version = 1
      ) ua_types 
ON fduh.website_user_id = ua_types.exten_user_id 
      AND ua_types.ord_events = 1
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
AND equipment_cohort_equipment_promo_price >= 1999
--AND DATEADD('day', 395, mst_cohort_date)::DATE = daily_user_history_date::DATE 
--AND DATEADD('day', 425, mst_cohort_date)::DATE = daily_user_history_date::DATE
)
select DATE_TRUNC('month', reporting_day)::DATE, count(*)
from ( 
SELECT ub2.*,
       fduh.date_actual,
       fduh.historical_paid_trial_free_member
FROM (
select website_user_id,
       cohort_user_type,
       cohort_date,
       user_activity_type,
       extension,
       CASE WHEN exten_user_id IS NOT NULL THEN DATEADD('day', 425, cohort_date)::DATE
            WHEN exten_user_id IS NULL THEN DATEADD('day', 395, cohort_date)::DATE 
       END  AS reporting_day
from user_base ub 
) ub2
JOIN analytics_revenue_mart.fact_daily_user_history fduh on ub2.website_user_id = fduh.website_user_id
    AND fduh.date_actual::DATE = reporting_day::DATE 
)
WHERE extension = 1 --change this to get extension or no extension
AND historical_paid_trial_free_member = 'Paid'
AND reporting_day >= '2019-06-01' --AND reporting_day < GETDATE()
GROUP BY 1
ORDER BY 1


*** Reactivations WITH extensions built in ***

WITH user_base AS (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       --CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as mst_cohort_date,
       --DATE_TRUNC('month', DATEADD('day', 395, user_cohort_date))::DATE AS reporting_period,
      -- daily_user_history_date::DATE AS ann_day,
       --historical_paid_trial_free_member as user_type_ann_day,
       ua_types.*,
       CASE WHEN ua_types.exten_user_id IS NOT NULL THEN 1 ELSE 0 END AS extension 
from analytics_revenue_mart.fact_daily_user_history fduh
LEFT JOIN (
      select user_id as exten_user_id,
               user_activity_created,
               user_activity_type,
               user_activity_description,
               row_number() over (partition by user_id order by user_activity_created) as ord_events
      from analytics_staging.staging_useractivities
      where user_activity_type IN ('twoHundredWorkoutsFreeMonthExtension','oneHundredWorkoutsFreeMonthExtension', 'membershipTimeExtended')
      and user_activity_description NOT LIKE ('Membership extended 2%')
      and is_current_version = 1
      ) ua_types 
ON fduh.website_user_id = ua_types.exten_user_id 
      AND ua_types.ord_events = 1
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
AND equipment_cohort_equipment_promo_price >= 1999
--AND DATEADD('day', 395, mst_cohort_date)::DATE = daily_user_history_date::DATE 
--AND DATEADD('day', 425, mst_cohort_date)::DATE = daily_user_history_date::DATE
)
select DATE_TRUNC('month', react_date)::DATE, count(*)
from (
select * 
from (
select *,
       row_number() over (partition by website_user_id order by react_date) as ord_reacts
from ( 
SELECT ub2.*,
       fduh.date_actual,
       fduh.historical_paid_trial_free_member
FROM (
select website_user_id,
       cohort_user_type,
       cohort_date,
       user_activity_type,
       extension,
       CASE WHEN exten_user_id IS NOT NULL THEN DATEADD('day', 425, cohort_date)::DATE
            WHEN exten_user_id IS NULL THEN DATEADD('day', 395, cohort_date)::DATE 
       END  AS reporting_day
from user_base ub 
) ub2
JOIN analytics_revenue_mart.fact_daily_user_history fduh on ub2.website_user_id = fduh.website_user_id
    AND fduh.date_actual::DATE = reporting_day::DATE 
) ann_days_check
LEFT JOIN (
select website_user_id as fmm_user_id,
        account_history_date::DATE as react_date,
        previous_user_type as pre_react_user_type
        --row_number() over (partition by website_user_id order by account_history_date) as ord_events
FROM analytics_revenue_mart.fact_membership_mobility fmm 
WHERE account_history_reactivation_flag = 1
) fmm 
ON ann_days_check.website_user_id = fmm.fmm_user_id 
    AND fmm.react_date > ann_days_check.reporting_day
WHERE extension = 0
AND historical_paid_trial_free_member <> 'Paid'
)
where fmm_user_id IS NOT NULl 
AND ord_reacts = 1
)
WHERE reporting_day >= '2019-06-01' --AND reporting_day < GETDATE()
GROUP BY 1
ORDER BY 1


** Ann Day check with cohort + 30 days check **
select DATE_TRUNC('month', ann_day)::DATE,
       count(*)
from (
select website_user_id,
       cohort_membership_type,
       user_cohort_date::DATE as cohort_date,
       DATEADD('day', 30, user_cohort_date)::DATE as month_1_check,
       DATEADD('day', 395, user_cohort_date)::DATE as ann_day,
       historical_paid_trial_free_member as user_type_at_month_1
      -- count(distinct website_user_id)
from analytics_revenue_mart.fact_daily_user_history
where cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
AND equipment_cohort_equipment_promo_price >= 1999
--AND user_cohort_date >= '2018-06-01'
AND daily_user_history_date::DATE = user_cohort_date::DATE + 30
)
where user_type_at_month_1 = 'Paid'
group by 1


***Finding 2 weeks and 2 weeks again extension User ***
WITH double_two_weeks_users AS (
SELECT *
FROM (
select *,
       LEAD(user_activity_description,1) OVER (PARTITION BY user_id ORDER BY user_activity_created) as next_ua_desc,
       LEAD(user_activity_created,1) OVER (PARTITION BY user_id ORDER BY user_activity_created) as next_ua_date
from (
select *,
        row_number() over (partition by user_id, user_activity_type order by user_activity_created) as ord_events
from analytics_staging.staging_useractivities
where user_activity_type IN ('membershipTimeExtended')
AND is_current_version = 1
)
)
WHERE ord_events = 1
AND next_ua_desc IS NOT NULL 
AND next_ua_date IS NOT NULL
AND next_ua_desc LIKE ('Membership extended 2%')
--AND datediff('day', user_activity_created, next_ua_date) > 1 --BETWEEN  AND 15
)
SELECT DATE_TRUNC('MONTH', user_cohort_date)::DATE, count(*)
FROM (
SELECT dtwu.user_id,
       du.user_cohort_date,
       de.equipment_product_spec_wifi,
       de.equipment_promo_price
FROM double_two_weeks_users dtwu 
JOIN analytics_warehouse.dim_users du on dtwu.user_id = du.website_user_id 
JOIN analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
WHERE de.equipment_product_spec_wifi = 'Glass'
AND de.equipment_promo_price >= 1999
)
GROUP BY 1
ORDER BY 1


