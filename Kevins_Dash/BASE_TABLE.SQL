**** FINAL CODE FOR BASE TABLE FOR KEVINS DASH *****
DROP TABLE public.acq_20_q4_OKR_base
CREATE TABLE public.Acq_20_Q4_OKR_Base AS 
--SELECT week_start, count(_id) FROM (
select * from ( 
select distinct(users_start_week._id), membership, users_start_week.created, week_start, TZ_Create_Date,
        SUM(CASE WHEN start_minute IS NOT NULL THEN 1
            WHEN start_minute IS NULL THEN 0
            END) as Wkout_Count
       /*CASE WHEN useractivities."type" = 'amazonActivation' THEN 'Amazon'
        WHEN useractivities.readable LIKE '%Freemotion%' and useractivities."type" <> 'amazonActivation' THEN 'Freemotion'
        WHEN log_PF = 'T' then 'Planet Fitness'
        ELSE 'Other'
      END as Segment */
FROM
(select
      users._id,
      users.account__subscription_type || ' ' || users.account__payment_type as Membership,
      users.created::date,
      CONVERT_TIMEZONE('America/Denver', users.created)::date as TZ_Create_Date,
      fiscal_weeks.week_start
      --users.login__planet_fitness__membership_managed_by_planet_fitness as log_PF
from
      prodmongo.users            
join
      fiscal_weeks on CONVERT_TIMEZONE('America/Denver',users.created)::date between fiscal_weeks.week_start and fiscal_weeks.week_end 
) users_start_week
left join unique_logs on users_start_week._id = unique_logs.user_id 
        and "start"::date BETWEEN users_start_week.week_start AND users_start_week.week_start + 6 
--left join prodmongo.useractivities on users_start_week._id = useractivities.user_id 
WHERE users_start_week.TZ_Create_Date BETWEEN '2020-03-01' AND 
  CONVERT_TIMEZONE('America/Denver', getdate())::date
GROUP BY users_start_week._id, membership, users_start_week.created, week_start, tz_create_date /*useractivities."type", readable, log_PF */
)
group by _id, membership, created, week_start, tz_create_date, wkout_count --segment
)
--where wkout_count > 0
--group by week_start
