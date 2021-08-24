--Wrote this for Jess/Tess to get counts of downgrades bucketed by the provided reasons in the last 90 days

with base as (
    select user_id,
           USER_ACTIVITY_CREATED,
           USER_ACTIVITY_TYPE,
           USER_ACTIVITY_DESCRIPTION,
           case when USER_ACTIVITY_DESCRIPTION like ('%User requested to%') then
               case when substr(user_activity_description, 77, 7) like ('%other%') then 'Other'
                    when substr(USER_ACTIVITY_DESCRIPTION, 77, 7) not like ('%other%') then substr(USER_ACTIVITY_DESCRIPTION, 77, 800)
               end
           else USER_ACTIVITY_DESCRIPTION
           end as description_trimmed
    from ANALYTICS.ANALYTICS_STAGING.STAGING_USERACTIVITIES
    where USER_ACTIVITY_TYPE = 'downgradeRequested'
    and datediff('day', USER_ACTIVITY_CREATED, getdate()) <= 90
    and IS_CURRENT_VERSION = 1
)
select replace(replace(value, '"'),'.') as value,
       count(*)
from (
         select *,
                row_number() over (partition by user_id order by USER_ACTIVITY_CREATED, index) as ord_events
         from (
                  select *
                  from base,
                      lateral split_to_table(description_trimmed, ' ')
                  order by 1
              )
         where value like ('%-%')
         or value like ('%other%')
     )
group by 1
