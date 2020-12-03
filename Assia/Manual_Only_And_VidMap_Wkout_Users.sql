--She wanted Users that have done a workout in the last 90 days on a Tread or a Bike that eithe 1- have done both manual/map workouts and library/video AND
-- 2- have ONLY done map/manual. SHe wanted 100 total so dataset split was: 25% for manual and video and 75% for just manual

SELECT u._id as user_id,
       personal__firstname,
       personal__lastname,
       login__ifit__email
FROM prodmongo.users u
JOIN (
    SELECT *
        FROM (
             SELECT *,
                    CASE
                        WHEN equip_list = 'MAP' THEN 'MAP-ONLY'
                        WHEN equip_list = 'VIDEO' THEN 'VIDEO-ONLY'
                        WHEN equip_list = 'MANUAL' THEN 'MANUAL-ONLY'
                        WHEN equip_list = 'OTHER' THEN 'OTHER-ONLY'
                        WHEN equip_list IN ('MANUALMAP') THEN 'MANUAL_AND_MAP'
                        WHEN equip_list IN ('MANUALMAPVIDEO', 'MANUALVIDEO', 'MAPVIDEO') THEN 'MAN_MAP_AND_VIDEO'
                        ELSE 'OTHER'
                        END AS equip_list_groups
                    --count(DISTINCT user_id)
             FROM (
                      SELECT DISTINCT(user_id),
                                     equipment_type,
                                     LISTAGG(distinct (wkout_type)) WITHIN GROUP (ORDER BY wkout_type)
                                     OVER (PARTITION BY user_id) AS equip_list
                      FROM (
                               SELECT ul.user_id,
                                      ul.software_number,
                                      ul.workout_id,
                                      sc.equipment_type,
                                      CASE
                                          WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
                                          WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
                                          WHEN al.duration > 0 AND ws.target_value IS NULL THEN 'MANUAL'
                                          ELSE 'OTHER'
                                          END AS wkout_type
                               FROM unique_logs ul
                                        JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
                                        JOIN prodmongo.activitylogs al on ul._id = al._id
                                        JOIN workout_store.workouts ws on ul.workout_id = ws._id
                               WHERE CONVERT_TIMEZONE('AMERICA/DENVER', ul."start") >=
                                     CONVERT_TIMEZONE('AMERICA/DENVER', GETDATE()) - 90
                                 AND sc.equipment_type IN ('Treadmill', 'Bike')
                           )
                  )
            WHERE equip_list_groups IN ('MAP-ONLY', 'MAN_MAP_AND_VIDEO')
         )
    WHERE equip_list_groups IN ('MAP-ONLY', 'MANUAL-ONLY', 'MANUAL_AND_MAP')
) sub_set
ON u._id = sub_set.user_id
WHERE COALESCE(u.personal__country, u.shipping__country, u.billing__country) IN ('US','USA')
ORDER BY random()
LIMIT 75

                    
                    
 -- Used this a check on specific Users --
SELECT ul.user_id,
       ul.start,
       sc.equipment_type,
       CASE WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
            WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
            WHEN al.duration > 0 AND ws.target_value IS NULL THEN 'MANUAL'
            ELSE 'OTHER'
            END AS wkout_type
from unique_logs ul
JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
JOIN prodmongo.activitylogs al on ul._id = al._id
JOIN workout_store.workouts ws on ul.workout_id = ws._id
where ul.user_id = '50b4c8509371afe65d00596f'
AND CONVERT_TIMEZONE('AMERICA/DENVER',ul."start") >= CONVERT_TIMEZONE('AMERICA/DENVER',GETDATE()) - 90
