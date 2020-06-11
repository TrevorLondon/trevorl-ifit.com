**** BASE TABLE 2 FINAL CODE ***8
DROP TABLE public.acq_20_q4_base_2
CREATE TABLE public.acq_20_q4_base_2 AS
SELECT _id as User_ID, created, week_start, wkout_count, oldstartdate as Memb_Start_Date_1, oldend as Memb_End_Date_1, oldsub || ' ' || oldpaytype as Memb_Type_1, oldusertype as User_Type_1,
    newstartdate as Memb_Start_Date_2, newend as Memb_End_Date_2, newsub || ' ' || newpaytype as Memb_Type_2, newusertype as User_Type_2
FROM acq_20_q4_okr_base q4 
LEFT JOIN ( 
  SELECT * FROM (
  SELECT *, row_number() over (partition by u1 order by oldstartdate ASC) as Events 
  FROM ( 
    SELECT uah1.users_id as u1, uah1.start_date as OldStartDate, coalesce(uah1.end_date, getdate()) as OldEnd, uah1.subscription_set_to as OldSub, uah1.payment_set_to as OldPayType, uah1.user_type as OldUserType,
           uah2.users_id as u2, uah2.start_date as NewStartDate, coalesce(uah2.end_date, getdate()) as NewEnd, uah2.subscription_set_to as NewSub, uah2.payment_set_to as NewPayType, uah2.user_type as NewUserType
    FROM users__account_history uah1
    LEFT JOIN users__account_history uah2 on uah1.users_id = uah2.users_id
      AND uah1.end_date = uah2.start_date
    ORDER BY uah1.start_date ASC
      )
      WHERE datediff('second', oldstartdate, oldend) > 5
        ) Events_Table
      WHERE Events = 1
      ) Earliest_Events
on Earliest_Events.u1 = q4._id
