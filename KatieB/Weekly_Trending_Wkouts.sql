SELECT *
FROM (
         SELECT *,
                ROW_NUMBER() OVER (PARTITION BY equipment_type ORDER BY wkout_count DESC) as equip_ordered
         FROM (
                  SELECT ws.title,
                         sc.equipment_type,
                         count(ul."start") as wkout_count
                  FROM unique_logs ul
                           JOIN workout_store.workouts ws on ul.workout_id = ws._id
                           JOIN prodmongo.stationaryconsoles sc on ul.software_number = sc.software_number
                  WHERE CONVERT_TIMEZONE('AMERICA/DENVER', ul."start") BETWEEN '2020-12-04' AND '2020-12-10'
                  GROUP BY 1, 2
              )
     )
WHERE equip_ordered <= 2
LIMIT 500
