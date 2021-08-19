--- We pulled the first query here about 5 months before the subsequent query. A lot of logic had changed on the backend in equipment cohort mapping, etc. so the numbers 
--- do not tie out just running this query straight across. So, in the end, we went with pulling only from Activity Logs b/c that's technically closest to
-- how the data would've functioned 5 months ago (attributing equip cohort by way of activity logs FIRST then by SAP). 

WITH cohort AS (
SELECT * 
FROM (
SELECT WEBSITE_USER_ID,
       swn_ordered AS software_count,
       ACTIVITY_DATE AS first_software_initial_log,
       ACTIVITY_SOFTWARE_NUMBER AS first_swn,
       epd as first_epd,
       EQUIPMENT_PROMO_PRICE AS first_promo_price,
       WIFI AS first_wifi,
       LEAD(ACTIVITY_DATE,1) OVER (PARTITION BY WEBSITE_USER_ID ORDER BY SWN_ORDERED) AS second_software_initial_log,
       LEAD(ACTIVITY_SOFTWARE_NUMBER,1) OVER (PARTITION BY WEBSITE_USER_ID ORDER BY SWN_ORDERED) AS second_swn,
       LEAD(epd,1) OVER (PARTITION BY WEBSITE_USER_ID ORDER BY SWN_ORDERED) AS second_epd,
       LEAD(WIFI,1) OVER (PARTITION BY WEBSITE_USER_ID ORDER BY SWN_ORDERED) AS second_wifi,
       LEAD(EQUIPMENT_PROMO_PRICE,1) OVER (PARTITION BY WEBSITE_USER_ID ORDER BY SWN_ORDERED) AS second_promo_price
FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY WEBSITE_USER_ID ORDER BY ACTIVITY_DATE) AS swn_ordered
    FROM (
        SELECT WEBSITE_USER_ID,
               ACTIVITY_DATE,
               ACTIVITY_SOFTWARE_NUMBER,
               EQUIPMENT_PRODUCT_SPEC_WIFI AS WIFI,
               EQUIPMENT_PRODUCT_ID AS epd,
               EQUIPMENT_PROMO_PRICE,
               ROW_NUMBER() OVER (PARTITION BY A.WEBSITE_USER_ID, A.ACTIVITY_SOFTWARE_NUMBER ORDER BY A.ACTIVITY_DATE ASC) AS ord_softwares
        FROM ANALYTICS.ANALYTICS_WAREHOUSE.FACT_ACTIVITY_LOG A 
        LEFT JOIN ANALYTICS.ANALYTICS_WAREHOUSE.DIM_EQUIPMENT B ON A.ACTIVITY_SOFTWARE_NUMBER = B.EQUIPMENT_SOFTWARE_NUMBER
        WHERE ACTIVITY_SOFTWARE_NUMBER < 700000
        AND LOWER(EQUIPMENT_PRODUCT_LINE_SUBTYPE) NOT LIKE '%app%'
    )
    WHERE ORD_SOFTWARES = 1
    ORDER BY WEBSITE_USER_ID, ORD_SOFTWARES
) 
WHERE swn_ordered < 3 
)
WHERE SECOND_SOFTWARE_INITIAL_LOG IS NOT NULL
)
SELECT c.WEBSITE_USER_ID,
       du.USER_COHORT_DATE AS join_date,
       (du.COHORT_SUBSCRIPTION_TYPE || '/' || du.COHORT_PAYMENT_INTERVAL) AS cohort_memb_type,
       DATEDIFF('DAY', du.USER_COHORT_DATE, GETDATE()) AS tenure,
       (du.USER_SUBSCRIPTION_TYPE || '/' || du.USER_PAYMENT_TYPE) AS current_memb_type,
       c.first_software_initial_log,
       c.first_swn,
       c.first_promo_price,
       c.first_wifi,
       c.second_software_initial_log,
       c.second_swn,
       c.second_promo_price,
       c.second_wifi,
       du.ACCOUNT_HISTORY_ORIGIN
FROM cohort c 
JOIN ANALYTICS_WAREHOUSE.DIM_USERS du on c.WEBSITE_USER_ID = du.WEBSITE_USER_ID



--- THIS IS THE NEW, FINAL QUERY WE USED JUST USING ACTIVITY LOGS

with base as (
    select WEBSITE_USER_ID,
           min(ACTIVITY_DATE)::DATE as first_wkout,
           USER_COHORT_DATE::DATE as cohort_date,
           EQUIPMENT_SOFTWARE_NUMBER as first_swn,
           EQUIPMENT_PRODUCT_SPEC_WIFI as first_wifi
    from ANALYTICS.ANALYTICS_REVENUE_MART.FACT_ACTIVITY_LOG_COMPOSITE
    where USER_COHORT_DATE::DATE >= '2017-06-01'
    and EQUIPMENT_PRODUCT_SPEC_WIFI IN ('Glass', 'BLE', 'Legacy')
    and USER_COHORT_DATE is not null
    group by 1,3,4,5
)
select date_trunc('month', cohort_date)::DATE as cohort,
       count(distinct website_user_id)
from (
         select b.*,
                min(al2.ACTIVITY_DATE)::DATE    as next_wkout,
                al2.EQUIPMENT_SOFTWARE_NUMBER as second_swn,
                al2.EQUIPMENT_PRODUCT_SPEC_WIFI as second_wifi
         from base b
                  left join ANALYTICS.ANALYTICS_REVENUE_MART.FACT_ACTIVITY_LOG_COMPOSITE al2
                            on b.WEBSITE_USER_ID = al2.WEBSITE_USER_ID
                                and al2.ACTIVITY_DATE > b.first_wkout
                                and al2.EQUIPMENT_SOFTWARE_NUMBER <> b.first_swn
         where ACTIVITY_SOFTWARE_NUMBER < 700000
         and lower(EQUIPMENT_PRODUCT_LINE_SUBTYPE) not like '%app%' --this is b/c the original also didn't specify glass, ble, legacy
         group by 1, 2, 3, 4, 5, 7, 8
     )
where next_wkout IS NOT NULL
and second_wifi is not null
and first_swn <> second_swn
group by 1
order by 1
