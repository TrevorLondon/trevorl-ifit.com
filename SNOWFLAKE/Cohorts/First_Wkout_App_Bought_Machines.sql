WITH foundation AS (
    WITH only_app_users AS (
        SELECT DISTINCT website_user_id,
                list_swn
        FROM (
        SELECT website_user_id,
                   equipment_product_line,
                   equipment_product_spec_wifi as wifi,
                   equipment_promo_price,
                   LISTAGG(DISTINCT(CASE WHEN LOWER(equipment_product_line_subtype) LIKE ('%app%') THEN 1 ELSE 0 END), ',') OVER (PARTITION BY al.website_user_id) as list_swn
            FROM analytics_warehouse.fact_activity_log al 
            LEFT JOIN analytics_warehouse.dim_equipment de on al.activity_software_number = de.equipment_software_number
        )
        WHERE list_swn LIKE ('1%')
    ),
    only_app_with_wkout_date AS (
        SELECT oau.*,
               MIN(al.activity_date)::DATE as wkout_date
        FROM only_app_users oau 
        LEFT JOIN analytics_warehouse.fact_activity_log al on oau.website_user_id = al.website_user_id
        GROUP BY 1,2
    )
    SELECT DISTINCT website_user_id,
            wkout_date,
            DATE_TRUNC('MONTH', wkout_date) as cohort_month,
            COALESCE(purchase_date,do_purchase_date,activity_date)::DATE as purchase_date,
            equipment_product_line,
            wifi,
            promo_price,
            --CASE WHEN purchase_date IS NOT NULL AND DATEDIFF('day', wkout_date, purchase_date) <= 30 THEN 1 ELSE 0 END AS less_than_30_days,
            CASE WHEN purchase_date IS NOT NULL AND DATEDIFF('day', wkout_date, purchase_date) BETWEEN 30 AND 59 THEN 1 ELSE 0 END AS more_than_30_days,
            CASE WHEN purchase_date IS NOT NULL AND DATEDIFF('day', wkout_date, purchase_date) >= 60 THEN 1 ELSE 0 END AS more_than_60_days
    FROM (
    SELECT a.*,
           sap.sales_order_create_date as purchase_date,
           do.direct_order_user_id,
           do.direct_order_order_date as do_purchase_date,
           de.equipment_product_line,
           de.equipment_product_spec_wifi as wifi,
           de.equipment_software_number,
           de.equipment_promo_price as promo_price,
           MIN(al.activity_date) AS activity_date
    FROM only_app_with_wkout_date a
    LEFT JOIN analytics_staging.staging_directorders do on a.website_user_id = do.direct_order_user_id
    LEFT JOIN analytics_warehouse.dim_sap_sales_order_basic sap on do.direct_order_request_po_number = sap.sales_order_customer_reference
    LEFT JOIN analytics_warehouse.dim_equipment de on sap.sales_order_material = de.equipment_product_id
    LEFT JOIN analytics_warehouse.fact_activity_log al on a.website_user_id = al.website_user_id
              AND al.activity_date > a.wkout_date
              AND lower(de.equipment_product_line_subtype) NOT LIKE ('%app%')
    WHERE do.is_current_version = 1
    GROUP BY 1,2,3,4,5,6,7,8,9,10
    )
)
SELECT cohort_month,
       COUNT(*) AS cohort_users,
       --SUM(CASE WHEN less_than_30_days = 1 AND wifi IN ('Glass', 'BLE', 'Legacy') THEN 1 ELSE 0 END) as cohort_purchased_less_than_30_days,
       SUM(CASE WHEN more_than_30_days = 1 AND wifi IN ('Glass', 'BLE', 'Legacy') THEN 1 ELSE 0 END) as cohort_purchased_between_30_and_60_days,
       SUM(CASE WHEN more_than_60_days = 1 AND wifi IN ('Glass', 'BLE', 'Legacy') THEN 1 ELSE 0 END) as cohort_purchased_after_60_days
FROM foundation
WHERE cohort_month >= '2018-06-01'
GROUP BY 1
ORDER BY 1 
LIMIT 50
