with base as (
    select distinct website_user_id
    from analytics_warehouse.fact_challenge_completion
    where completed_during_challenge = 1
),
households as (
    select du.user_household_id,
           b.website_user_id,
           al.activity_date
    from base b 
    left join analytics_warehouse.dim_users du on b.website_user_id = du.website_user_id
    left join analytics_warehouse.fact_activity_log al on du.website_user_id = al.website_user_id
    order by 1,2,3
),
wkouts_summed as (
select user_household_id,
       date_trunc('month', activity_date)::DATE as wkout_month,
       count(*) as total_household_wkouts
from households 
group by 1,2
order by 1,2
),
users_memb as (
select b.website_user_id,
       du.user_cohort_date::DATE as cohort_date,
       (du.cohort_subscription_type || '/' || du.cohort_payment_interval) as cohort_membership_type,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_promo_price as promo_price,
       du.first_anniversary_date,
       du.first_anniversary_category,
       (du.user_subscription_type || '/' || du.user_payment_type) as current_membership_type
from base b
left join analytics_warehouse.dim_users du on b.website_user_id = du.website_user_id
left join analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
where first_anniversary_date < GETDATE()
and du.cohort_payment_interval = 'Yearly'
)
select um.*,
       sum(total_household_wkouts) as household_wkouts_total
from users_memb um
left join wkouts_summed ws on um.website_user_id = ws.user_household_id
group by 1,2,3,4,5,6,7,8
