select account_history_date::date as reactivated_date,
       DATE_TRUNC('month', user_cohort_date) as cohort_month,
       count(*)
from (
select fmm.website_user_id,
       fmm.user_cohort_date,
       fmm.account_history_date,
       fmm.ACCOUNT_HISTORY_REACTIVATION_FLAG,
       fmm.USER_EQUIPMENT_COHORT_EQUIPMENT_ID,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_promo_price
from analytics_revenue_mart.fact_membership_mobility fmm
JOIN analytics_warehouse.dim_equipment de on fmm.user_equipment_cohort_equipment_id = de.equipment_id
WHERE fmm.account_history_date::DATE >= '2021-03-01' AND fmm.account_history_date::DATE <='2021-03-31'
AND fmm.account_history_reactivation_flag = 1 
)
where wifi = 'Glass'
and equipment_promo_price >= 1999
group by 1,2
order by 1, 2
