SELECT count(users_id) as User_Count, SUM(wkout_count) as Wkout_Count, membership_type, user_type, memb_status FROM (
SELECT users_id, user_type, membership_type,
  CASE WHEN CONVERT_TIMEZONE('America/Denver',users."created")::date >= '2019-03-01' THEN 'New'
     WHEN CONVERT_TIMEZONE('America/Denver',users."created")::date <  '2019-03-01' THEN 'Old'
     END as Memb_Status,
  SUM (CASE WHEN CONVERT_TIMEZONE('America/Denver',unique_logs."start")::date is NOT NULL THEN 1
        WHEN CONVERT_TIMEZONE('America/Denver',unique_logs."start")::date is NULL THEN 0
        END) as Wkout_Count
FROM unique_logs 
JOIN prodmongo.users on unique_logs.user_id = users._id
JOIN (
      SELECT
                        	--CONVERT_TIMEZONE('America/Denver',"date")::date as "Date",
                        	user_snapshot.user_type,
                        	user_snapshot.membership_type,
                        	--count(*) as user_qty, 
                        	user_snapshot.users_id
                        	--"created"
                        	/*CASE WHEN CONVERT_TIMEZONE('America/Denver',"created")::date >= '2019-03-01' THEN 'New'
                            WHEN CONVERT_TIMEZONE('America/Denver',"created")::date <  '2019-03-01' THEN 'Old'
                            END as Memb_Status */
                        FROM
                        (
                        	SELECT
                        		*,
                        		CASE 
                        			WHEN trial_membership = 1 AND item_total = 0 AND subscription_set_to <> 'free' THEN 'Trial'
                        			WHEN subscription_set_to <> 'free' THEN 'Paid'
                        			WHEN subscription_set_to = 'free' THEN 'Free'
                        			ELSE NULL
                        		END AS user_type,
                        		CASE 
                        			WHEN subscription_set_to = 'coach-plus' and payment_set_to IN ('monthly','none') THEN 'FAMILY MONTHLY'
                        			WHEN subscription_set_to = 'coach-plus' and payment_set_to IN ('yearly','two-year') THEN 'FAMILY YEARLY'
                        			WHEN subscription_set_to = 'premium' and payment_set_to IN ('monthly','none') THEN 'INDIVIDUAL MONTHLY'
                        			WHEN subscription_set_to = 'premium' and payment_set_to IN ('yearly','two-year') THEN 'INDIVIDUAL YEARLY'
                        			WHEN subscription_set_to = 'premium-non-equipment' and payment_set_to IN ('monthly','none') THEN 'NON-EQ MONTHLY'
                        			WHEN subscription_set_to = 'premium-non-equipment' and payment_set_to IN ('yearly','two-year') THEN 'NON-EQ YEARLY'
                        			WHEN subscription_set_to = 'free' THEN 'FREE'
                        			ELSE NULL
                        		END AS membership_type
                        	FROM
                        	(
                        		--trial memberships
                        		SELECT
                        			uah.*,
                        			ua.type,
                        			ua.readable,
                        			orders.po_number,
                        			orders.sku,
                        			orders.promo_code,
                        			orders.order_complete,
                        			orders.item_total,
                        			orders.trial_membership,
                        			--orders."created",
                        			--users_id,
                        			ROW_NUMBER() OVER(PARTITION BY uah.users_id ORDER BY uah.date DESC, uah.expiration_date_set_to DESC) as row_number
                        		FROM
                        			prodmongo.users__account_history uah
                        		LEFT JOIN
                        			prodmongo.useractivities ua 
                        				ON uah.users_id = ua.user_id AND uah.date BETWEEN ua.created - INTERVAL '30 second' AND ua.created + INTERVAL '30 second'
                        		LEFT JOIN
                        		(
                        			--ORDERS
                        			SELECT
                        			    a._id as orders_id,
                        			    a.user_id,
                        			    a.order_number as po_number,
                        			    a.promo_code,
                        			    c.sap_product_id as sku,
                        			    a.order_date,
                        			    a.order_complete,
                        			    a.settled,
                        			    a.item_total,
                        			    a.currency_code,
                        			    c.trial_membership
                        			    --users."created"
                        			FROM
                        			    prodmongo.orders a                      
                        			JOIN
                        			    prodmongo.orders__items b                                                                                     
                        			        on a._id = b.orders_id                     
                        			JOIN
                        			    prodmongo.items c                                                                           
                        			        on b.item = c._id       
                        			LEFT JOIN
                        			    prodmongo.users
                        			        on a.user_id = users._id        
                        			WHERE
                        				c.category = 'Account'
                        		) orders 	
                        			ON uah.users_id = orders.user_id AND uah.date BETWEEN orders.order_date - INTERVAL '30 second' AND orders.order_date + INTERVAL '30 second'	
                        		WHERE
                        			CONVERT_TIMEZONE('America/Denver',uah.date)::date < '2019-04-17'
                        			AND (
                        					ua.type NOT IN ('oneHundredWorkoutsFreeMonthExten','nourishActivate','nourishExtend','cybersourceToStripeMigration')
                        					OR ua.type IS NULL
                        				)
                        			AND CONVERT_TIMEZONE('America/Denver',uah.date)::date NOT BETWEEN '2017-05-19' and '2017-05-22' --memorial day promo 2017
                        			--AND uah.users_id = '5e9091080bf6e5002e7d0cba'	
                        	) ordered_account_changes
                        	WHERE
                        		row_number = 1
                        ) user_snapshot )
                           Pre_Final
on users._id = Pre_Final.users_id
WHERE CONVERT_TIMEZONE('America/Denver',unique_logs."start")::date BETWEEN '2019-03-03' AND '2019-04-17'
group by users_id, membership_type, user_type, "created")
GROUP BY membership_type, user_type, memb_status
