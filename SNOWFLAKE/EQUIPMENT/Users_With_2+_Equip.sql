-- Needed to get Users that had > 1 equipment identified via activitylogs and what type, cost, date, etc. associated to their 1st and 2nd equips

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
