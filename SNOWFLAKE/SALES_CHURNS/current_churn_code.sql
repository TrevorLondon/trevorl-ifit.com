select 
    first_name,
    last_name,
    phone_number,
    email,
    wkout_count,
    personal_timezone,
    email_consent,
    churned_date
from 
    (
        WITH churned_users AS (
            SELECT *
            FROM 
                (
                    select website_user_id, 
                        (PREVIOUS_SUBSCRIPTION_TYPE || '/' || PREVIOUS_PAYMENT_INTERVAL) AS PREV_MEMB_TYPE,
                        CONVERT_TIMEZONE('America/Denver', account_history_date)::DATE as churned_date,
                        account_history_churn_flag,
                        trial_churn_to_free_flag,
                        row_number() over (partition by website_user_id order by account_history_date DESC) as ord_events
                    from analytics_revenue_mart.fact_membership_mobility
                )
            WHERE 
                ord_events = 1
                AND ACCOUNT_HISTORY_CHURN_FLAG = 1
                AND churned_date BETWEEN '2021-07-02' AND '2021-07-05'
                --AND churned_date = DATEADD('week', -2, CONVERT_TIMEZONE('America/Denver', GETDATE()::DATE))
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
        ),
        user_pii as (
            select login_email, website_user_id, row_number() over (partition by website_user_id order by website_user_id, login_email desc) as row_num
            from analytics_pii.staging_website_users_login_pii
            where is_current_version = true and login_email is not null
        )
        SELECT DISTINCT cu.website_user_id,
            u.personal:firstname::varchar as first_name,
            u.personal:lastname::varchar as last_name,
            COALESCE(u.login:ifit:email::varchar, pi2.login_email) as email,
            COALESCE(COALESCE(COALESCE(dos.direct_order_request_shipping_phone, u.billing:phone, sapi.sold_to_phone, sify1.phone, sify2.billing_address_phone), e.phone_1), e.phone_2) as phone_number,
            pi.personal_timezone,
            du.user_cohort_date as first_paid_date,
            (du.cohort_subscription_type || '/' || du.cohort_payment_interval) as cohort_memb_type,
            cu.churned_date,
            cu.prev_memb_type as churned_from_memb_type,
            sw.purchase_date,
            sw.wifi,
            w.wkout_count,
            du.user_marketing_email_consent as email_consent,
            row_number() over (partition by cu.website_user_id order by sw.purchase_date DESC) as ord_events
        FROM churned_users cu 
            LEFT JOIN swn_wifi sw on cu.website_user_id = sw.website_user_id
            LEFT JOIN workouts w on cu.website_user_id = w.website_user_id
            LEFT JOIN analytics_warehouse.dim_users du on cu.website_user_id = du.website_user_id
            LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on cu.website_user_id = u._id 
            LEFT JOIN analytics_staging.staging_directorders dos on cu.website_user_id = dos.direct_order_user_id
            LEFT JOIN user_pii pi2 on cu.website_user_id = pi2.website_user_id
            LEFT JOIN analytics_pii.staging_website_users_pii pi on cu.website_user_id = pi.website_user_id
            LEFT JOIN development.dbt_tlondon.email_phone e on pi2.login_email = e.email
            LEFT JOIN analytics_pii.dim_sap_customer_basic_pii sapi on cu.website_user_id = sapi.user_id
            LEFT JOIN analytics.stg_shopify__customer sify1 on cu.website_user_id = sify1.customer_id::varchar
            LEFT JOIN analytics.stg_shopify__order sify2 on cu.website_user_id = sify2.customer_id::varchar
        WHERE du.user_country_code = 'US' and pi2.row_num = 1
    )
WHERE ord_events = 1
    AND churned_from_memb_type = 'Family/Yearly'
    AND (phone_number IS NOT NULL OR email IS NOT NULL)
ORDER BY churned_date, phone_number
