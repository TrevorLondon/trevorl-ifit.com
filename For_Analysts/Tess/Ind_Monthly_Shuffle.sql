SELECT order_date,
       category,
       count(*)
FROM (
WITH membership_start_dates AS 
    (
    --get all users and membership start dates since 2010 (first time as a paid membership type)
    --membership start date will be the first day the user becomes paid or converts from an activate trial (whichever comes first)
    --exclude anyone who was first set to paid during the 2017 Memorial Day Promo where the entire DB was updated
        select
            users_id,
            CONVERT_TIMEZONE('America/Denver',membership_start_date)::date as mst_membership_start_date
        FROM (    
                select
                    users_id,
                    MIN(date) as membership_start_date
                from
                    (select * from prodmongo.users__account_history where CONVERT_TIMEZONE('America/Denver',date)::date NOT BETWEEN '2017-05-19' and '2017-05-22') users__account_history -- memorial day promo upgraded entire database, ignore these
                left join (select distinct user_id, trial_date from activate) activate on users__account_history.users_id = activate.user_id
                WHERE
                    subscription_set_to <> 'free'
                    AND
                    payment_set_to <> 'none'
                    AND
                    (CONVERT_TIMEZONE('America/Denver',users__account_history.date)::date <> activate.trial_date or activate.user_id IS NULL)
                GROUP BY
                    users_id  
            ) membership_starts
        WHERE
            CONVERT_TIMEZONE('America/Denver',membership_start_date)::date BETWEEN '2010-06-01' AND getdate()::date
 )
select 
        fiscal_calendar.fiscal_year,
        fiscal_calendar.month_start,
        orders.*,
        membership_start_dates.mst_membership_start_date,
        orders.order_date - mst_membership_start_date as difference_days,
        CASE
            WHEN orders.order_date - mst_membership_start_date > 0 THEN 'Renewal'
            ELSE 'New'
        END AS category
from 
    (
        -- (Combines sku and order details into one record per order)
        SELECT
            a._id as orders_id,
            a.user_id,
            a.order_number as po_number,
            LISTAGG(c.sap_product_id,'+') as sku,
            CONVERT_TIMEZONE('America/Denver',a.order_date)::date as order_date,
            CASE
                WHEN a.currency_code = 'USD' THEN a.item_total
                ELSE c.prices__usd__price
            END AS item_total,
            CASE
                WHEN a.currency_code = 'USD' THEN a.currency_code
                ELSE 'USD from ' || a.currency_code 
            END AS currency_code
        FROM
            prodmongo.orders a                      
        JOIN
            prodmongo.orders__items b                                                                                     
                on a._id = b.orders_id                     
        JOIN
            prodmongo.items c                                                                           
                on b.item = c._id                     
        WHERE
            (
                a.settled = 1
                AND a.item_total > 0
            )           
            AND b.item IS NOT NULL
            AND c.category = 'Account'
            AND c.account_type = 'Premium'
            AND c.account_payment_type = 'Monthly'
            AND c.trial_membership = 0
            --AND c.sap_product_id NOT LIKE 'ifn%'                                                      
            --AND c.sap_product_id NOT LIKE 'ifaxj%'                                                     
            AND CONVERT_TIMEZONE('America/Denver',a.order_date)::date BETWEEN '2020-06-01' AND CONVERT_TIMEZONE('America/Denver',GETDATE())::DATE
        GROUP BY
            1, 2, 3, 5, 6, 7
    ) orders
left join
        membership_start_dates
            ON membership_start_dates.users_id = orders.user_id
left join
        fiscal_calendar 
                ON orders.order_date BETWEEN fiscal_calendar.month_start and fiscal_calendar.month_end
)
GROUP BY 1,2
ORDER BY 1 ASC
