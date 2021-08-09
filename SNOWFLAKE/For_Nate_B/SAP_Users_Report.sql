select pi.login_email,
       pi2.personal_first_name,
       pi2.personal_last_name,
       round(sum(al.activity_duration_minutes) / 60,2) as wkout_hours,
       count(al.activity_log_id) as wkouts,
       du.user_age,
       du.user_gender
from ANALYTICS_PII.STAGING_WEBSITE_USERS_LOGIN_PII pi
         left join ANALYTICS_PII.STAGING_WEBSITE_USERS_PII pi2 on pi.website_user_id = pi2.website_user_id
         left join ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG al on pi2.WEBSITE_USER_ID = al.WEBSITE_USER_ID
         left join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS du on pi2.WEBSITE_USER_ID = du.WEBSITE_USER_ID
where pi.LOGIN_EMAIL IN (
  [EMAILS]
  )
  and pi.IS_CURRENT_VERSION = 1
  and pi2.IS_CURRENT_VERSION = 1
  and pi.LOGIN_EMAIL IS NOT NULL
  and al.ACTIVITY_DATE::DATE BETWEEN '2021-04-01' AND '2021-08-01'
group by 1,2,3,6,7


--This one was for the much larger group, so uploaded a data source to local env. and ran this query on it--
with base as (
    select nsu.*,
           pi.login_email,
           pi.website_user_id,
           du.user_gender,
           du.user_age
    from development.dbt_tlondon.nate_sap_users nsu
    left join ANALYTICS.ANALYTICS_pii.STAGING_WEBSITE_USERS_LOGIN_PII pi on nsu.contact_email = pi.login_email
    left join ANALYTICS.ANALYTICS_WAREHOUSE.DIM_USERS du on pi.website_user_id = du.website_user_id
    where is_current_version = 1
)
select b.contact_email,
       b.contact_name,
       b.last_name,
       round((sum(al.activity_duration_minutes) / 60),2) as wkout_hours,
       count(al.activity_log_id) as wkouts,
       b.user_age,
       b.user_gender
from base b
left join ANALYTICS.analytics_warehouse.fact_activity_log al on b.website_user_id = al.website_user_id
where ACTIVITY_DATE::DATE BETWEEN '2021-04-01' AND '2021-08-01'
group by 1,2,3,6,7
