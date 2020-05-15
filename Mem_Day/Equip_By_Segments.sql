select login__ifit__email, equip_master_segment from (
SELECT login__ifit__email,
  CASE WHEN (account__subscription_type = 'coach-plus' and account__payment_type = 'monthly') 
    THEN 'FM Bike'
  CASE WHEN (account__subscription_type = 'coach-plus' and account__payment_type = 'yearly')
    THEN 'FY Bike'
  CASE WHEN (account__subscription_type = 'premium' and account__payment_type = 'yearly') 
    THEN 'INDY Bike'
  CASE WHEN (account__subscription_type = 'premium' and account__payment_type = 'monthly') 
    THEN 'INDM Bike'
  END as "Equip_Master_Segment"
FROM mem_day_segments_final
WHERE segment = 'Paid' AND equipment LIKE '%Bike%')

/* Getting PAID equipment segments */
SELECT login__ifit__email FROM (
SELECT login__ifit__email, 
        CASE WHEN account__payment_type = 'yearly' AND account__subscription_type = 'coach-plus' THEN 'FMY_Unk'
        WHEN account__payment_type = 'monthly' AND account__subscription_type = 'coach-plus' THEN 'FM_Unk'
        WHEN account__payment_type = 'yearly' AND account__subscription_type = 'premium' THEN 'INDY_Unk'
        WHEN account__payment_type = 'monthly' AND account__subscription_type = 'premium' THEN 'INDM_Unk'
        END as Equip_Master_Segment
FROM (
        SELECT * FROM mem_day_segments_final
        WHERE segment= 'Paid' AND equipment IS NULL AND churned_user = 'F' --LIKE '%Stride%'
) )
WHERE equip_master_segment = 'FMY_Unk'

/* Amazon equipment Segments */
SELECT * FROM (
SELECT login__ifit__email, segment,
        CASE WHEN equipment LIKE '%Bike%' THEN 'Bike'
        WHEN equipment LIKE '%Tread%' THEN 'Treadmill'
        WHEN equipment LIKE '%Ellip%' THEN 'Elliptical'
        WHEN equipment LIKE '%Row%' THEN 'Rower'
        WHEN equipment LIKE '%Streng%' THEN 'Strength'
        WHEN equipment LIKE '%Fusio%' THEN 'Fusion'
        WHEN equipment LIKE '%HIIT%' THEN 'HIIT'
        WHEN equipment LIKE '%Stride%' THEN 'Strider'
        WHEN equipment IS NULL THEN 'UNKNOWN'
        END as Equip_Master_Segment
FROM mem_day_segments_final)
WHERE segment = 'Amazon'

/*FM Equip Segments */
SELECT login__ifit__email FROM (
SELECT login__ifit__email, segment,
        CASE WHEN equipment LIKE '%Bike%' THEN 'Bike'
        WHEN equipment LIKE '%Tread%' THEN 'Treadmill'
        WHEN equipment LIKE '%Ellip%' THEN 'Elliptical'
        WHEN equipment LIKE '%Row%' THEN 'Rower'
        WHEN equipment LIKE '%Streng%' THEN 'Strength'
        WHEN equipment LIKE '%Fusio%' THEN 'Fusion'
        WHEN equipment LIKE '%HIIT%' THEN 'HIIT'
        WHEN equipment LIKE '%Stride%' THEN 'Strider'
        WHEN equipment IS NULL THEN 'UNKNOWN'
        END as Equip_Master_Segment
FROM mem_day_segments_final)
WHERE segment = 'Freemotion' AND equip_master_segment = 'UNKNOWN'

/* PF Equipment Segments */ 
SELECT login__ifit__email FROM (
SELECT login__ifit__email, segment,
        CASE WHEN equipment LIKE '%Bike%' THEN 'Bike'
        WHEN equipment LIKE '%Tread%' THEN 'Treadmill'
        WHEN equipment LIKE '%Ellip%' THEN 'Elliptical'
        WHEN equipment LIKE '%Row%' THEN 'Rower'
        WHEN equipment LIKE '%Streng%' THEN 'Strength'
        WHEN equipment LIKE '%Fusio%' THEN 'Fusion'
        WHEN equipment LIKE '%HIIT%' THEN 'HIIT'
        WHEN equipment LIKE '%Stride%' THEN 'Strider'
        WHEN equipment IS NULL THEN 'UNKNOWN'
        END as Equip_Master_Segment
FROM mem_day_segments_final)
WHERE segment = 'Planet Fitness' AND equip_master_segment = 'Treadmill'

/* Activate Equipment Segment */
SELECT login__ifit__email FROM (
SELECT login__ifit__email, segment, churned_user,
        CASE WHEN equipment LIKE '%Bike%' THEN 'Bike'
        WHEN equipment LIKE '%Tread%' THEN 'Treadmill'
        WHEN equipment LIKE '%Ellip%' THEN 'Elliptical'
        WHEN equipment LIKE '%Row%' THEN 'Rower'
        WHEN equipment LIKE '%Streng%' THEN 'Strength'
        WHEN equipment LIKE '%Fusio%' THEN 'Fusion'
        WHEN equipment LIKE '%HIIT%' THEN 'HIIT'
        WHEN equipment LIKE '%Stride%' THEN 'Strider'
        WHEN equipment IS NULL THEN 'UNKNOWN'
        END as Equip_Master_Segment
FROM mem_day_segments_final)
WHERE segment = 'Activate Trial' AND equip_master_segment = 'UNKNOWN' AND churned_user = 'F'

/*FREE30ISO Equipment Segment */
SELECT login__ifit__email, segment, churned_user, equipment FROM mem_day_segments_final WHERE segment = 'FREE30ISO' and churned_user = 'F'

select * from mem_day_segments_final where segment = 'Activate Trial' and churned_user = 'T'

/* all churned users with equipment types */
SELECT login__ifit__email FROM (
SELECT login__ifit__email, segment, churned_user,
        CASE WHEN equipment LIKE '%Bike%' THEN 'Bike'
        WHEN equipment LIKE '%Tread%' THEN 'Treadmill'
        WHEN equipment LIKE '%Ellip%' THEN 'Elliptical'
        WHEN equipment LIKE '%Row%' THEN 'Rower'
        WHEN equipment LIKE '%Streng%' THEN 'Strength'
        WHEN equipment LIKE '%Fusio%' THEN 'Fusion'
        WHEN equipment LIKE '%HIIT%' THEN 'HIIT'
        WHEN equipment LIKE '%Stride%' THEN 'Strider'
        WHEN equipment IS NULL THEN 'UNKNOWN'
        END as Equip_Master_Segment
FROM mem_day_segments_final)
WHERE segment = 'Other' AND equip_master_segment = 'Bike' AND churned_user = 'T'

SELECT login__ifit__email 
FROM mem_day_segments_final
WHERE (segment = 'Other' or segment = 'Freemotion' or segment = 'FREE30ISO')
AND churned_user = 'T'   
