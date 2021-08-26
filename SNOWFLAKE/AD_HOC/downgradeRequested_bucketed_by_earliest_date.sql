-- this splits out the reasons and then grabs the first date it was used and then counts the times it has been used since that first date

with base as (
    select user_id,
           USER_ACTIVITY_CREATED,
           split_part(USER_ACTIVITY_DESCRIPTION, '"', 2) as reasons
    from ANALYTICS.ANALYTICS_STAGING.STAGING_USERACTIVITIES
         --lateral split_to_table(USER_ACTIVITY_TYPE)
    where IS_CURRENT_VERSION = 1
      and USER_ACTIVITY_TYPE = 'downgradeRequested'
    order by 1
),
unique_reasons as (
    select *
    from base,
         lateral split_to_table(reasons, ' ') as rt
    order by 1, index, seq
),
beg_dates as (
    select value,
           min(user_activity_created)::DATE as first_date_used
    from unique_reasons
    group by 1
)
select ur.value as reason,
       bd.first_date_used,
       count(ur.value) as total
from unique_reasons ur
join beg_dates bd on ur.value = bd.value
group by 1,2
limit 50
