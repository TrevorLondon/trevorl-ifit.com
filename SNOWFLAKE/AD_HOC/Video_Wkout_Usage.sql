select date_trunc('week',activity_date)::DATE as wkout_date,
       count(distinct unique_video_id)
from analytics_warehouse.fact_activity_log
where unique_video_id IS NOT NULL
and activity_date::DATE > getdate()::DATE - 35
group by 1
order by 1


select count(distinct unique_video_id) 
from analytics_warehouse.fact_activity_log
where unique_video_id IS NOT NULL
and max(activity_date)::DATE > '2020-01-01'


select count(*)
from (
select unique_video_id,
       count(activity_log_id) as usage
from analytics_warehouse.fact_activity_log
where unique_video_id IS NOT NULL
and is_current_version = 1
group by 1
)
where usage >= 20



--Most RECENTLY used one --
select count(*)
from (
select equipment_product_line,
       unique_video_id,
       count(activity_log_id) as usage
from analytics_revenue_mart.fact_activity_log_composite
where unique_video_id IS NOT NULL
and is_current_version = 1
group by 1,2
)
where usage >= 50
