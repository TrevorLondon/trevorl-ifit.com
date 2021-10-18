-- Tanya's dataset for expiring --

with churned_users as (
    select WEBSITE_USER_ID,
           ACCOUNT_HISTORY_DATE,
           PREVIOUS_ACCOUNT_HISTORY_SUBSCRIPTION_PAYMENT as churned_from_memb,
           ACCOUNT_HISTORY_CHURN_FLAG,
           TRIAL_CHURN_TO_FREE_FLAG,
           lag(ORDER_DATE::date, 1) over (partition by WEBSITE_USER_ID order by ACCOUNT_HISTORY_DATE) as prior_order_date,
           lag(ORDER_PROMO_CODE, 1) over (partition by WEBSITE_USER_ID order by ACCOUNT_HISTORY_DATE) as prior_promo_code,
           lag(ORDER_SKU, 1) over (partition by WEBSITE_USER_ID order by ACCOUNT_HISTORY_DATE) as prior_sku
    from analytics.ANALYTICS_WAREHOUSE.DIM_USERS__REACTIVATION
),
churned_users_all_types as (
    select distinct cu.WEBSITE_USER_ID,
           listagg(distinct dur.ACCOUNT_HISTORY_SUBSCRIPTION_PAYMENT, ',') over (partition by cu.WEBSITE_USER_ID) as all_types
    from churned_users cu
    join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS__REACTIVATION dur on cu.WEBSITE_USER_ID = dur.WEBSITE_USER_ID
    where dur.TRIAL_MEMBERSHIP_FLAG = 0
),
churned_users_wkouts as (
    select cu.*,
           cuat.all_types,
           sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Video' then 1 else 0 end) as content_wkouts,
           sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Live' then 1 else 0 end) as live_wkouts,
           sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Map' then 1 else 0 end) as map_wkouts,
           sum(case when ACTIVITY_EXPERIENCE_CATEGORY in ('Manual', 'Uncategorized') then 1 else 0 end) as manual_wkouts,
           count(al.ACTIVITY_DATE) as all_wkouts_total
    from churned_users cu
    join churned_users_all_types cuat on cu.WEBSITE_USER_ID = cuat.WEBSITE_USER_ID
    left join ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG al on cu.WEBSITE_USER_ID = al.WEBSITE_USER_ID
        and al.ACTIVITY_DATE < cu.ACCOUNT_HISTORY_DATE
    where ACCOUNT_HISTORY_CHURN_FLAG = 1
    and TRIAL_CHURN_TO_FREE_FLAG = 0
    and datediff('day', ACCOUNT_HISTORY_DATE::date, current_date()::date) <= 90
    group by 1,2,3,4,5,6,7,8,9
),
churned_users_final as (
    select *
    from churned_users_wkouts
    where all_wkouts_total = 0
),
expiring_users as (
    select du.WEBSITE_USER_ID,
           COMBINED_SUBSCRIPTION_PAYMENT as membership_type,
           USER_EXPIRATION_DATE::date as expiration_date,
           dur.ACCOUNT_HISTORY_DATE::date as memb_began_date,
           ORDER_SKU,
           ORDER_PROMO_CODE,
           order_date,
           all_types,
           has_churned,
           datediff('day', current_date()::date, USER_EXPIRATION_DATE::date),
           al.content_wkouts,
           al.live_wkouts,
           al.manual_wkouts,
           al.map_wkouts,
           al.all_wkouts_total
    from ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS du
    left join (
        select website_user_id,
               sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Video' then 1 else 0 end) as content_wkouts,
               sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Live' then 1 else 0 end) as live_wkouts,
               sum(case when ACTIVITY_EXPERIENCE_CATEGORY = 'Map' then 1 else 0 end) as map_wkouts,
               sum(case when ACTIVITY_EXPERIENCE_CATEGORY in ('Manual', 'Uncategorized') then 1 else 0 end) as manual_wkouts,
               count(ACTIVITY_DATE) as all_wkouts_total
        from ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG
        group by 1
    ) al
    on du.WEBSITE_USER_ID = al.WEBSITE_USER_ID
    join (
        select distinct WEBSITE_USER_ID,
               ACCOUNT_HISTORY_DATE,
               ACCOUNT_HISTORY_SUBSCRIPTION_PAYMENT,
               ORDER_PROMO_CODE,
               ORDER_SKU,
               ORDER_DATE::date as order_date,
               listagg(distinct SUBSCRIPTION_TYPE,',') over (partition by WEBSITE_USER_ID) as all_types,
               listagg(distinct ACCOUNT_HISTORY_CHURN_FLAG,',') over (partition by WEBSITE_USER_ID) has_churned
        from ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS__REACTIVATION
        qualify row_number() over (partition by WEBSITE_USER_ID order by ACCOUNT_HISTORY_DATE desc) = 1
   ) dur
    on du.WEBSITE_USER_ID = dur.WEBSITE_USER_ID
    where datediff('day', current_date()::date, USER_EXPIRATION_DATE::date) <= 90
    and CURRENT_PAID_TRIAL_FREE_MEMBER = 'Paid'
)
select eu.WEBSITE_USER_ID,
       du.USER_CREATED_DATE::date as created_on,
       pi2.LOGIN_EMAIL as email,
       regexp_replace(pi.PERSONAL_FIRST_NAME::varchar, '^%$@#!')  as first_name,
       regexp_replace(pi.PERSONAL_LAST_NAME::varchar, '^%$@#!') as last_name,
       du.USER_GENDER as gender,
       du.user_subscription_type as membership_type,
       du.USER_PAYMENT_TYPE as payment_type,
       du.USER_IS_TRIAL_MEMBER,
       du.USER_BILLING_COUNTRY as country,
       du.USER_PERSONAL_LOCALE as locale,
       regexp_replace(pi.BILLING_ZIP::varchar, '[^0-9_]')                                   as zip,
       regexp_replace(pi.billing_city::varchar, '[^a-zA-Z0-9]+') as city,
       regexp_replace(pi.SHIPPING_STATE_ABBREVIATION::varchar, '[^a-zA-Z0-9]+') as state,
       iff(du.USER_PRIMARY_OR_SECONDARY = 'Secondary', TRUE, FALSE)                          as is_secondary,
       NULL as subscription_was,
       NULL as downgrade_date,
       de.EQUIPMENT_TYPE as equipment,
       du.USER_HAS_SECONDARY_USERS as has_co_users,
       --FALSE as is_coach_user, (for churns list)
       iff(eu.membership_type like ('%Family%'), TRUE, FALSE) as is_coach_user,
      -- NULL as coach_user_date, (for churns list)
       iff(eu.membership_type like ('%Family%'), eu.memb_began_date, NULL) as coach_user_date,
       iff(du.USER_QUALIFIED_FOR_AUTORENEWAL = 1, du.USER_EXPIRATION_DATE, NULL) as expected_autorenewal_date,
       iff(eu.all_types like any ('%Individual%'), TRUE, FALSE) as has_been_premium,
       iff(eu.has_churned like ('%1%'), TRUE, FALSE) as has_churned,
       de.EQUIPMENT_TYPE as type,
       du.USER_EQUIPMENT_COHORT_SOFTWARE_NUMBER as software_number,
       null as has_used_wolf_app,
       case when de.EQUIPMENT_PRODUCT_SPEC_WIFI = 'Glass' then 'Glass'
            when de.EQUIPMENT_PRODUCT_SPEC_WIFI = 'BLE' then 'BLE'
            else null
       end as screen,
       iff(de.EQUIPMENT_PRODUCT_SPEC_WIFI in ('Glass', 'BLE'), TRUE, FALSE) as has_used_wolf_built_in,
       eu.content_wkouts,
       eu.live_wkouts,
       eu.map_wkouts,
       eu.manual_wkouts,
       eu.all_wkouts_total,
       eu.order_promo_code as promoCode,
       eu.order_date as orderDate,
       eu.order_sku as item_sapProductId
from expiring_users eu
join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS du on eu.WEBSITE_USER_ID = du.WEBSITE_USER_ID
join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_EQUIPMENT de on du.USER_EQUIPMENT_COHORT_SOFTWARE_NUMBER = de.EQUIPMENT_SOFTWARE_NUMBER
join ANALYTICS.ANALYTICS_PII.STAGING_WEBSITE_USERS_PII pi on eu.WEBSITE_USER_ID = pi.WEBSITE_USER_ID
    and pi.IS_CURRENT_VERSION = 1
join ANALYTICS.ANALYTICS_PII.STAGING_WEBSITE_USERS_LOGIN_PII pi2 on eu.WEBSITE_USER_ID = pi2.WEBSITE_USER_ID
    and pi2.IS_CURRENT_VERSION = 1
where eu.all_wkouts_total = 0 or eu.all_wkouts_total is null
