SELECT *
fROM (
         SELECT user_id,
                personal__firstname,
                personal__lastname,
                email,
                CASE WHEN equip LIKE ('%Tread%') THEN 'Treadmill'
                     WHEN equip LIKE ('%Ellip%') OR equip LIKE ('%Stride%') THEN 'Elliptical'
                     WHEN equip LIKE ('%Bike%') THEN 'Bike'
                     WHEN equip LIKE ('%Row%') THEN 'Rower'
                     ELSE 'Other'
                END AS equip_group,
                count("start")                       as wkout_count,
                series_set_count
         FROM (
                  SELECT ul.user_id,
                         ul.software_number,
                         u.login__ifit__email as email,
                         u.personal__firstname,
                         u.personal__lastname,
                         p.title as series_name,
                         sng."name" as equip,
                         CASE
                             WHEN p._id = '5fbe9221c2b9a60040d7ee88' THEN 'Tread'
                             WHEN p._id = '5fbe94b827622c0048fd787e' THEN 'Bike'
                             WHEN p._id = '5fbe945773c19a0040a363a1' THEN 'Elliptical'
                             WHEN p._id = '5fbe950ba2103f00479a6d54' THEN 'Rower'
                             ELSE 'OTHER'
                             END as series_equip,
                         ul."start",
                         12      AS series_set_count
                  FROM unique_logs ul
                  JOIN prodmongo.softwarenumbergroups__software_numbers sngsn on ul.software_number = sngsn.software_numbers
                  JOIN prodmongo.softwarenumbergroups sng on sngsn.softwarenumbergroups_id = sng._id
                  JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
                  JOIN prodmongo.programs p on pw.programs_id = p._id
                  JOIN prodmongo.users u on ul.user_id = u._id
                  WHERE ul."start" >= '2020-12-01'
                    AND p._id IN (
                                  '5fbe9221c2b9a60040d7ee88',
                                  '5fbe94b827622c0048fd787e',
                                  '5fbe945773c19a0040a363a1',
                                  '5fbe950ba2103f00479a6d54')
                AND user_id = '5b31a4875259240028ddf74c'
              )
         WHERE user_id = '5b31a4875259240028ddf74c'
        GROUP BY 1,2,3,4,5,7
     )
WHERE wkout_count >= series_set_count
AND user_id NOT IN (
    SELECT user_id
fROM (
         SELECT user_id,
                (series_name || '-' || series_equip) as series,
                count("start")                       as wkout_count,
                series_set_count
         FROM (
                  SELECT ul.user_id,
                         p.title as series_name,
                         CASE
                             WHEN p._id = '5fbe9221c2b9a60040d7ee88' THEN 'Tread'
                             WHEN p._id = '5fbe94b827622c0048fd787e' THEN 'Bike'
                             WHEN p._id = '5fbe945773c19a0040a363a1' THEN 'Elliptical'
                             WHEN p._id = '5fbe950ba2103f00479a6d54' THEN 'Rower'
                             ELSE 'OTHER'
                             END as series_equip,
                         ul."start",
                         12      AS series_set_count
                  FROM unique_logs ul
                           JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
                           JOIN prodmongo.programs p on pw.programs_id = p._id
                  WHERE ul."start" >= '2020-12-01'
                    AND p._id IN (
                                  '5fbe9221c2b9a60040d7ee88',
                                  '5fbe94b827622c0048fd787e',
                                  '5fbe945773c19a0040a363a1',
                                  '5fbe950ba2103f00479a6d54')
              )
        GROUP BY 1,2,4
     )
WHERE wkout_count >= series_set_count
 )
