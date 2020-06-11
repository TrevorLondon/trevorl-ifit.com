*** EQUIPMENT TABLE ***
/**** UPDATING EQUIPMENT TABLE FROM ^^^ ***/
drop table acq_20_q4_base_equip
create table public.acq_20_q4_base_equip as
SELECT distinct(user_id), week_start, name from (
SELECT a.*, name 
from acq_20_q4_base_2 a
left join unique_logs on a.user_id = unique_logs.user_id
left join prodmongo.softwarenumbergroups__software_numbers b on unique_logs.software_number = b.software_numbers
left join prodmongo.softwarenumbergroups c on b.softwarenumbergroups_id = c._id
)
