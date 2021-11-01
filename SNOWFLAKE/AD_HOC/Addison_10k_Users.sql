with users as (
    select du.WEBSITE_USER_ID,
           du.COMBINED_SUBSCRIPTION_PAYMENT,
           du.USER_AGE,
           case when user_age between 0 and 20 then 1
                when user_age between 21 and 30 then 2
                when user_age between 31 and 40 then 3
                when user_age between 41 and 50 then 4
                when user_age between 51 and 60 then 5
                when user_age > 60 then 6
           end as age_buckets,
           du.USER_GENDER,
           de.EQUIPMENT_TYPE
    from ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS du
    join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_EQUIPMENT de on du.USER_EQUIPMENT_COHORT_SOFTWARE_NUMBER = de.EQUIPMENT_SOFTWARE_NUMBER
    where CURRENT_PAID_TRIAL_FREE_MEMBER = 'Paid'
    and EQUIPMENT_PRODUCT_SPEC_WIFI = 'Glass'
    and EQUIPMENT_TYPE in ('Rower', 'Treadmill', 'Bike', 'Elliptical')
    and USER_GENDER in ('Male', 'Female')
),
users_pii as (
    select u.*,
           pi2.PERSONAL_FIRST_NAME as first_name,
           pi2.PERSONAL_LAST_NAME as last_name,
           pi.LOGIN_EMAIL as email
    from users u
    join ANALYTICS.ANALYTICS_PII.STAGING_WEBSITE_USERS_LOGIN_PII pi on u.WEBSITE_USER_ID = pi.WEBSITE_USER_ID
    join ANALYTICS.ANALYTICS_PII.STAGING_WEBSITE_USERS_PII pi2 on u.WEBSITE_USER_ID = pi2.WEBSITE_USER_ID
    where pi.IS_CURRENT_VERSION = 1
    and pi2.IS_CURRENT_VERSION = 1
),
manuals as (
    select website_user_id,
           count(*) as manual_wkouts,
           max(ACTIVITY_DATE::date) as last_manual_wkout_date
    from ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG
    where ACTIVITY_EXPERIENCE_CATEGORY = 'Manual'
    and ACTIVITY_DATE >= current_date - 90
    group by 1
    --qualify row_number() over (partition by WEBSITE_USER_ID order by ACTIVITY_DATE desc) = 1
),
avg_wkouts as (
    select *,
           round((manual_wkouts/3),1) as avg_wkouts_per_user
    from manuals
    group by 1,2,3
)
select *,
       row_number() over (partition by EQUIPMENT_TYPE, age_buckets, USER_GENDER order by random()) as partitions
from users_pii up
join avg_wkouts aw on up.WEBSITE_USER_ID = aw.WEBSITE_USER_ID
where datediff('day', last_manual_wkout_date, current_date::date) <= 90
qualify row_number() over (partition by EQUIPMENT_TYPE, age_buckets, USER_GENDER order by random()) <= 210
order by EQUIPMENT_TYPE, age_buckets, USER_GENDER;
