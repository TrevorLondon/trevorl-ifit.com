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
