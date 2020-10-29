-- Run this to see if you have any queries that are still trying to run

SELECT pid, user_name, starttime, query
FROM stv_recents
WHERE status='Running'
