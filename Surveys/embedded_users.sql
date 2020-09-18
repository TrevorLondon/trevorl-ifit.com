--This was used to identify machine types from the list of users that filled out a survey provided by Addison. Mark wanted to know, specifically,
-- the ratings on the x32 treadmill and s22i bike. 

select login__ifit__email, ue.updated_at, ue."type", ue.purchase_date, ue.software_number, sc."name",
        CASE WHEN ue.software_number IN ('404740',
'416429',
'425703',
'425699') THEN 'x32'
        WHEN ue.software_number IN ('392570',
'412927',
'425738',
'426458') THEN 's22i'
        ELSE 'other'
        END AS equip_segment
from prodmongo.users 
join prodmongo.userequipments ue on users._id = ue."user"
join prodmongo.stationaryconsoles sc on ue.software_number = sc.software_number
WHERE login__ifit__email IN (' ')
