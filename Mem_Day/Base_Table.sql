CREATE TABLE public.Mem_Day_Users AS 
SELECT * FROM (
SELECT users._id, software_number, machine_id, "type", account__subscription_type, account__payment_type, B."name" as Equipment,
  ROW_NUMBER() OVER (PARTITION BY users._id ORDER BY purchase_date DESC) as MR_Equip
FROM prodmongo.users
LEFT JOIN prodmongo.userequipments on users._id = userequipments."user"
  AND software_number < 700000
LEFT JOIN prodmongo.softwarenumbergroups__software_numbers A on userequipments.software_number = A.software_numbers
LEFT JOIN prodmongo.softwarenumbergroups B on A.softwarenumbergroups_id = B._id
WHERE users._id NOT IN (
  SELECT users._id
  FROM prodmongo.users
  WHERE app_billing_token IS NOT NULL 
  AND account__source IN ('android', 'ios')
  AND account__subscription_type <> 'free'
  )
AND CONVERT_TIMEZONE('America/Denver',users."created")::date > CONVERT_TIMEZONE('America/Denver',GETDATE())::date - 91)
WHERE MR_Equip = 1
