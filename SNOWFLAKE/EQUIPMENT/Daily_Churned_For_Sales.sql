select *
    from (
    WITH churned_users AS (
    SELECT *
    FROM (
    select website_user_id, 
           (PREVIOUS_SUBSCRIPTION_TYPE || '/' || PREVIOUS_PAYMENT_INTERVAL) AS PREV_MEMB_TYPE,
           account_history_date as churned_date,
           account_history_churn_flag,
           trial_churn_to_free_flag,
           row_number() over (partition by website_user_id order by account_history_date DESC) as ord_events
    from analytics_revenue_mart.fact_membership_mobility
    )
    WHERE ord_events = 1
    AND ACCOUNT_HISTORY_CHURN_FLAG = 1
    AND churned_date >= '2021-04-05' AND churned_date < '2021-04-07'
    ),
    workouts as (
    SELECT cu.website_user_id,
           count(*) as wkout_count
    from churned_users cu 
    LEFT JOIN analytics_warehouse.fact_activity_log al on cu.website_user_id = al.website_user_id
    WHERE al.activity_date >= '2020-03-01'
    group by 1
    ),
    swn_wifi as (
    SELECT cu.website_user_id,
           COALESCE(du.user_first_equipment_purchase_date, due.purchase_date, do.UPDATED_AT) as purchase_date,
           due.software_number,
           de.equipment_product_spec_wifi as wifi 
    FROM churned_users cu 
    LEFT JOIN analytics_warehouse.dim_users du on cu.website_user_id = du.website_user_id
    LEFT JOIN analytics_warehouse.dim_users_equipment due on cu.website_user_id = due.user_id
    LEFT JOIN analytics_warehouse.dim_equipment de on due.software_number = de.equipment_software_number
    LEFT JOIN fivetran_database.ifit_website_atlas_website.directorders do on cu.website_user_id = do.user_id 
    WHERE wifi NOT LIKE ('%App%')
    AND wifi <> 'Wearable'
    )
    SELECT DISTINCT cu.website_user_id,
           u.personal:firstname::varchar as first_name,
           u.personal:lastname::varchar as last_name,
           COALESCE(u.login:ifit:email::varchar, pi2.login_email) as email,
           dos.direct_order_request_shipping_phone as phone_number,
           pi.personal_timezone,
           du.user_cohort_date as first_paid_date,
           (du.cohort_subscription_type || '/' || du.cohort_payment_interval) as cohort_memb_type,
           cu.churned_date,
           cu.prev_memb_type as churned_from_memb_type,
           sw.purchase_date,
           sw.wifi,
           w.wkout_count,
           row_number() over (partition by cu.website_user_id order by purchase_date DESC) as ord_events
    FROM churned_users cu 
    LEFT JOIN swn_wifi sw on cu.website_user_id = sw.website_user_id
    LEFT JOIN workouts w on cu.website_user_id = w.website_user_id
    LEFT JOIN analytics_warehouse.dim_users du on cu.website_user_id = du.website_user_id
    LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on cu.website_user_id = u._id 
    LEFT JOIN analytics_staging.staging_directorders dos on cu.website_user_id = dos.direct_order_user_id
    LEFT JOIN analytics_pii.staging_website_users_login_pii pi2 on cu.website_user_id = pi2.website_user_id
    LEFT JOIN analytics_pii.staging_website_users_pii pi on cu.website_user_id = pi.website_user_id
    WHERE du.user_country_code = 'US' 
    )
    WHERE ord_events = 1
    AND churned_from_memb_type = 'Family/Yearly'
    AND (phone_number IS NOT NULL OR email IS NOT NULL)
 )
 GROUP BY 1
