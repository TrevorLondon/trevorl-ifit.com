-- Built this for Becca to see the gross change of the times the machine inclined and declined during a workout for Users in 2021. Only on x22i and x32i machines.

with workouts as (
    select workout_id,
           CONTROLS_INDEX,
           CONTROLS_AT,
           ceil(CONTROLS_AT / 60) as controls_at_min,
           CONTROLS_TYPE,
           CONTROLS_VALUE
    from ANALYTICS.ANALYTICS_STAGING.STAGING_PARSED_LYCAN_WORKOUTS_CONTROLS
    where CONTROLS_TYPE = 'incline'
      and IS_CURRENT_VERSION = 1
),
calculated as (
    select al.WEBSITE_USER_ID,
           w.WORKOUT_ID,
           al.ACTIVITY_DATE::date             as activity_date,
           w.CONTROLS_INDEX,
           w.CONTROLS_AT,
           w.controls_at_min,
           w.CONTROLS_TYPE,
           w.CONTROLS_VALUE,
           al.ACTIVITY_START,
           al.ACTIVITY_END,
           round(al.ACTIVITY_DURATION_MINUTES, 2) as duration
    from ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG al
    join workouts w on al.WORKOUT_ID = w.WORKOUT_ID
        and w.controls_at_min <= ceil(al.ACTIVITY_DURATION_MINUTES)
    where ACTIVITY_DATE >= '2021-01-01'
    and ACTIVITY_EXPERIENCE_CATEGORY = 'Video'
    and ACTIVITY_SOFTWARE_NUMBER in ('387193',
'398317',
'399670',
'405374',
'405474',
'416421',
'425691',
'425695',
'433314',
'437186',
'437213',
'404740',
'416429',
'416433',
'425699',
'425703',
'434437',
'437182')
    order by 1, 2, 4
),
net_change as (
    select *,
           abs((CONTROLS_VALUE - lag(CONTROLS_VALUE, 1)
                                 over (partition by WEBSITE_USER_ID, WORKOUT_ID order by activity_date, CONTROLS_INDEX))) as net_inc_change
    from calculated
)
select nc.WEBSITE_USER_ID,
       pi.PERSONAL_WEIGHT_LBS_ROUNDED,
       ACTIVITY_START::date as workout_date,
       duration,
       sum(net_inc_change) as gross_inc_dec_change
from net_change nc
join ANALYTICS.ANALYTICS_PII.STAGING_WEBSITE_USERS_PII pi on nc.WEBSITE_USER_ID = pi.WEBSITE_USER_ID
where IS_CURRENT_VERSION = 1
group by 1,2,3,4
limit 500000
