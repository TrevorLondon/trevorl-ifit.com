--Wrote this as a quick gut check on workout counts grouped by week start since beg of challenge. 
--Just need to update the user_id in row 19 when running 

SELECT mst_start_week,
       count(*)
FROM (
         SELECT ul.*,
                DATE_TRUNC('week', CONVERT_TIMEZONE('AMERICA/DENVER', ul."start"))::DATE as mst_start_week,
                CASE
                    WHEN al.workout_context IN ('scheduledPre', 'scheduledLive') THEN 'LIVE'
                    WHEN ws.geospatial__total_distance > 0 THEN 'MAP'
                    WHEN ws.brightcove_video_id IS NOT NULL THEN 'VIDEO'
                    ELSE 'MANUAL'
                    END                                                                  AS wkout_type
         FROM unique_logs ul
                  JOIN prodmongo.activitylogs al on ul.user_id = al.user_id
             AND ul._id = al._id
                  JOIN workout_store.workouts ws on ul.workout_id = ws._id
         WHERE CONVERT_TIMEZONE('AMERICA/DENVER', ul."start")::DATE >= '2020-10-12'
           AND ul.user_id = '5de573ddb508a400e744b2de'
     )
WHERE wkout_type <> 'MANUAL'
GROUP BY 1
