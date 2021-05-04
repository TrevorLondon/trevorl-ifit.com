--** DEFINING COHORT SIZES **--
WITH user_base AS (
select *
from (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       DATEADD('day', 30, user_cohort_date)::DATE as month_1_check_date,
       historical_paid_trial_free_member as user_type_at_month_1
from analytics_revenue_mart.fact_daily_user_history fduh
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
--AND equipment_cohort_equipment_promo_price >= 1999
AND daily_user_history_date::DATE = user_cohort_date::DATE + 30
)
where user_type_at_month_1 = 'Paid'
)
select DATE_TRUNC('month', reporting_day)::DATE, count(*)
from (
select ub.website_user_id,
       ub.cohort_user_type,
       ub.cohort_date,
       DATEADD('day', 395, cohort_date)::DATE as reporting_day,
       fduh.historical_paid_trial_free_member
from user_base ub
LEFT JOIN analytics_revenue_mart.fact_daily_user_history fduh on ub.website_user_id = fduh.website_user_id
        AND fduh.date_actual::DATE = DATEADD('day', 395, cohort_date)::DATE 
)
--WHERE user_activity_type IS NULL 
WHERE reporting_day >= '2019-06-01' AND reporting_day < GETDATE()
--AND historical_paid_trial_free_member = 'Paid'
GROUP BY 1
ORDER BY 1

--***GETTING RETAINED ALL GLASS **---
WITH user_base AS (
select *
from (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       DATEADD('day', 30, user_cohort_date)::DATE as month_1_check_date,
       historical_paid_trial_free_member as user_type_at_month_1
from analytics_revenue_mart.fact_daily_user_history fduh
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
--AND equipment_cohort_equipment_promo_price >= 1999
AND daily_user_history_date::DATE = user_cohort_date::DATE + 30
)
where user_type_at_month_1 = 'Paid'
)
select DATE_TRUNC('month', reporting_day)::DATE, count(*)
from (
select ub.website_user_id,
       ub.cohort_user_type,
       ub.cohort_date,
       DATEADD('day', 395, cohort_date)::DATE as reporting_day,
       fduh.historical_paid_trial_free_member
from user_base ub
LEFT JOIN analytics_revenue_mart.fact_daily_user_history fduh on ub.website_user_id = fduh.website_user_id
        AND fduh.date_actual::DATE = DATEADD('day', 395, cohort_date)::DATE 
)
--WHERE user_activity_type IS NULL 
WHERE reporting_day >= '2019-06-01' AND reporting_day < GETDATE()
AND historical_paid_trial_free_member = 'Paid'
GROUP BY 1
ORDER BY 1



--** GETTING REACTIVATIONS FOR ALL GLASS **--
WITH user_base AS (
select *
from (
select DISTINCT website_user_id,
       cohort_user_type,
       CONVERT_TIMEZONE('America/Denver', user_cohort_date)::DATE as cohort_date,
       DATEADD('day', 30, user_cohort_date)::DATE as month_1_check_date,
       historical_paid_trial_free_member as user_type_at_month_1
from analytics_revenue_mart.fact_daily_user_history fduh
WHERE cohort_user_type = 'Paid'
AND lower(cohort_membership_type) IN ('individual/yearly', 'family/yearly', 'individual/monthly', 'family/monthly')
AND user_primary_or_secondary = 'Primary'
AND equipment_cohort_equipment_product_spec_wifi = 'Glass'
--AND equipment_cohort_equipment_promo_price >= 1999
AND daily_user_history_date::DATE = user_cohort_date::DATE + 30
)
where user_type_at_month_1 = 'Paid'
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
       DATEADD('DAY', 395, cohort_date)::DATE as reporting_day
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
WHERE historical_paid_trial_free_member <> 'Paid'
)
where fmm_user_id IS NOT NULl 
AND ord_reacts = 1
)
WHERE reporting_day >= '2019-06-01' AND reporting_day < GETDATE()
GROUP BY 1
ORDER BY 1
