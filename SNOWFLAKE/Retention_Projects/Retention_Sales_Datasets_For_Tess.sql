-- CHURNED and have a Glass >= 1999 cohort type and have had a 1st ann. day --

select *
from (
SELECT DISTINCT du.website_user_id,
       u.personal:firstname::varchar as first_name,
       u.personal:lastname::varchar as last_name,
       pi2.login_email,
       COALESCE(do.direct_order_request_shipping_phone, u.billing:phone, sapi.sold_to_phone, e.phone_1, e.phone_2) as phone_number,
       convert_timezone('America/Denver', dur.account_history_date)::date as churn_date,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_product_line_subtype as modality,
       row_number() over (partition by du.website_user_id order by phone_number DESC) as row_num 
FROM analytics_warehouse.dim_users du
JOIN analytics_warehouse.dim_users__reactivation dur on du.website_user_id = dur.website_user_id 
      and dur.account_history_churn_flag = 1
JOIN analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
LEFT JOIN (
    SELECT *
    from (
        SELECT website_user_id,
               login_email,
               row_number() over (partition by website_user_id order by website_user_id, login_email DESC) as row_num
        FROM analytics_pii.staging_website_users_login_pii
        WHERE is_current_version = 1
        AND login_email IS NOT NULL
        )
    WHERE row_num = 1
) pi2 on du.website_user_id = pi2.website_user_id
LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
LEFT JOIN analytics_staging.staging_directorders do on du.website_user_id = do.direct_order_user_id
LEFT JOIN analytics_pii.dim_sap_customer_basic_pii sapi on du.website_user_id = sapi.user_id
LEFT JOIN development.dbt_tlondon.email_phone e on pi2.login_email = e.email
--LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
WHERE current_account_status = 'Membership_Churned'
AND convert_timezone('America/Denver', du.first_anniversary_date)::DATE < convert_timezone('America/Denver', GETDATE())::DATE 
AND de.equipment_product_spec_wifi = 'Glass'
AND de.equipment_promo_price >= '1999'
order by churn_date DESC 
    )
WHERE row_num = 1 

-- CHURNED and have a Glass < 1999 cohort type and have had a 1st ann day --

select *
from (
SELECT DISTINCT du.website_user_id,
       u.personal:firstname::varchar as first_name,
       u.personal:lastname::varchar as last_name,
       pi2.login_email,
       COALESCE(do.direct_order_request_shipping_phone, u.billing:phone, sapi.sold_to_phone, e.phone_1, e.phone_2) as phone_number,
       convert_timezone('America/Denver', dur.account_history_date)::date as churn_date,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_product_line_subtype as modality,
       row_number() over (partition by du.website_user_id order by phone_number DESC) as row_num 
FROM analytics_warehouse.dim_users du
JOIN analytics_warehouse.dim_users__reactivation dur on du.website_user_id = dur.website_user_id 
      and dur.account_history_churn_flag = 1
JOIN analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
LEFT JOIN (
    SELECT *
    from (
        SELECT website_user_id,
               login_email,
               row_number() over (partition by website_user_id order by website_user_id, login_email DESC) as row_num
        FROM analytics_pii.staging_website_users_login_pii
        WHERE is_current_version = 1
        AND login_email IS NOT NULL
        )
    WHERE row_num = 1
) pi2 on du.website_user_id = pi2.website_user_id
LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
LEFT JOIN analytics_staging.staging_directorders do on du.website_user_id = do.direct_order_user_id
LEFT JOIN analytics_pii.dim_sap_customer_basic_pii sapi on du.website_user_id = sapi.user_id
LEFT JOIN development.dbt_tlondon.email_phone e on pi2.login_email = e.email
--LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
WHERE current_account_status = 'Membership_Churned'
AND convert_timezone('America/Denver', du.first_anniversary_date)::DATE < convert_timezone('America/Denver', GETDATE())::DATE 
AND de.equipment_product_spec_wifi = 'Glass'
AND de.equipment_promo_price < '1999'
order by churn_date DESC 
    )
WHERE row_num = 1 


-- Churned and came from <> Glass equip cohort and have had a 1st ann day --

select *
from (
SELECT DISTINCT du.website_user_id,
       u.personal:firstname::varchar as first_name,
       u.personal:lastname::varchar as last_name,
       pi2.login_email,
       COALESCE(do.direct_order_request_shipping_phone, u.billing:phone, sapi.sold_to_phone, e.phone_1, e.phone_2) as phone_number,
       convert_timezone('America/Denver', dur.account_history_date)::date as churn_date,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_product_line_subtype as modality,
       row_number() over (partition by du.website_user_id order by phone_number DESC) as row_num 
FROM analytics_warehouse.dim_users du
JOIN analytics_warehouse.dim_users__reactivation dur on du.website_user_id = dur.website_user_id 
      and dur.account_history_churn_flag = 1
JOIN analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
LEFT JOIN (
    SELECT *
    from (
        SELECT website_user_id,
               login_email,
               row_number() over (partition by website_user_id order by website_user_id, login_email DESC) as row_num
        FROM analytics_pii.staging_website_users_login_pii
        WHERE is_current_version = 1
        AND login_email IS NOT NULL
        )
    WHERE row_num = 1
) pi2 on du.website_user_id = pi2.website_user_id
LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
LEFT JOIN analytics_staging.staging_directorders do on du.website_user_id = do.direct_order_user_id
LEFT JOIN analytics_pii.dim_sap_customer_basic_pii sapi on du.website_user_id = sapi.user_id
LEFT JOIN development.dbt_tlondon.email_phone e on pi2.login_email = e.email
--LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
WHERE current_account_status = 'Membership_Churned'
AND convert_timezone('America/Denver', du.first_anniversary_date)::DATE < convert_timezone('America/Denver', GETDATE())::DATE 
AND de.equipment_product_spec_wifi <> 'Glass'
--AND de.equipment_promo_price < '1999'
order by churn_date DESC 
    )
WHERE row_num = 1 

-- Churned Users with a future anniversary date --
select *
from (
SELECT DISTINCT du.website_user_id,
       u.personal:firstname::varchar as first_name,
       u.personal:lastname::varchar as last_name,
       pi2.login_email,
       COALESCE(do.direct_order_request_shipping_phone, u.billing:phone, sapi.sold_to_phone, e.phone_1, e.phone_2) as phone_number,
       convert_timezone('America/Denver', dur.account_history_date)::date as churn_date,
       de.equipment_product_spec_wifi as wifi,
       de.equipment_product_line_subtype as modality,
       row_number() over (partition by du.website_user_id order by phone_number DESC) as row_num 
FROM analytics_warehouse.dim_users du
JOIN analytics_warehouse.dim_users__reactivation dur on du.website_user_id = dur.website_user_id 
      and dur.account_history_churn_flag = 1
JOIN analytics_warehouse.dim_equipment de on du.user_equipment_cohort_software_number = de.equipment_software_number
LEFT JOIN (
    SELECT *
    from (
        SELECT website_user_id,
               login_email,
               row_number() over (partition by website_user_id order by website_user_id, login_email DESC) as row_num
        FROM analytics_pii.staging_website_users_login_pii
        WHERE is_current_version = 1
        AND login_email IS NOT NULL
        )
    WHERE row_num = 1
) pi2 on du.website_user_id = pi2.website_user_id
LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
LEFT JOIN analytics_staging.staging_directorders do on du.website_user_id = do.direct_order_user_id
LEFT JOIN analytics_pii.dim_sap_customer_basic_pii sapi on du.website_user_id = sapi.user_id
LEFT JOIN development.dbt_tlondon.email_phone e on pi2.login_email = e.email
--LEFT JOIN fivetran_database.ifit_website_atlas_website.users u on du.website_user_id = u._id
WHERE current_account_status = 'Membership_Churned'
AND convert_timezone('America/Denver', du.first_anniversary_date)::DATE >= convert_timezone('America/Denver', GETDATE())::DATE 
--AND de.equipment_product_spec_wifi <> 'Glass'
--AND de.equipment_promo_price < '1999'
order by churn_date DESC 
    )
WHERE row_num = 1 
