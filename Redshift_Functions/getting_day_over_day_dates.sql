--This is a built-in Redshift function that will give you day over day, row x row output of daterange beginning with the date specified
-- and then x number of days out (1, 100, 1) -> gives you 100 days

select ('2020-08-01'::date + x)::date
from generate_series(1, 100, 1) x
