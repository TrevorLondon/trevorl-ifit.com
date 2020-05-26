/* Getting BLE and EMbedded info for above user sets*/

SELECT distinct(_id), week_start, name from (
SELECT a.*, name 
from acq_20_q4_okr_base a
left join unique_logs on a._id = unique_logs.user_id
join prodmongo.softwarenumbergroups__software_numbers b on unique_logs.software_number = b.software_numbers
join prodmongo.softwarenumbergroups c on b.softwarenumbergroups_id = c._id
)
