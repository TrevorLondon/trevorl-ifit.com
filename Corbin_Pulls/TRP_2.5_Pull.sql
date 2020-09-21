-- Just needed distinct User that completed at 1 or more in ANY of these programs. 

SELECT login__ifit__email 
FROM prodmongo.users
JOIN (
        SELECT distinct(user_id) FROM (
        SELECT ul.user_id, ws."title",
            ROUND((duration / 1000) / ws.target_value,2) as percent_complete
        FROM unique_logs ul
        JOIN prodmongo.programs__workouts pw on ul.workout_id = pw.workouts
        JOIN workout_store.workouts ws on pw.workouts = ws._id
        WHERE pw.programs_id IN ('5ea9ffb330af45003111234e',
        '5e2233a6c6bd23047e282762',
        '5deed71994c3190034b48f81',
        '5dc30b39f1863b00763ce428',
        '5d60638cc27f4e00ac8fac1d',
        '5d01851a7e42d70029f5427c',
        '5cb8ff27db1d1200290b6ff0',
        '5bb65fa6b379810027d52598',
        '5dc47d1ecc4d38015438da07',
        '5da638f4b7014c1933deb9a3',
        '5cfee538845389002a443bee',
        '5e22378ebce0c306259256a1')
        )
        WHERE percent_complete >= 0.70
        ) user_set
ON user_set.user_id = users._id
