-- Import Pacakages --

import pandas as pd
import os 
import numpy as np

-- Check WD location --
pwd()

-- CHange WD to my Desktop --
os.chdir('/Users/trevor.london/Desktop')

-- Import CSV File --
csv_data = pd.read_csv('BF_Users_List.csv')

-- Rename Columns --
csv_data = csv_data.rename(columns = {'previous sub typ':'previous_sub_type', 'previous pay type':'previous_pay_type'})

-- Set conditions to iterate through and identify Ind Yearly and Fam Yearly Users -- 
conditions = [
    (csv_data['previous_sub_type'] == 'premium') & (csv_data['previous_pay_type'] == 'yearly'),
    (csv_data['previous_sub_type'] == 'coach-plus') & (csv_data['previous_pay_type'] == 'yearly')
]

-- Set Values that'll be used below to identify my subset of Fam Yearly and Ind Yearly --
values = ['PY', 'FY']

-- Build a New Column in my DF (csv) --
csv_data['static'] = np.select(conditions, values)

-- Run the iteration using my conditions and values and populate my new column above --
csv_data[csv_data['static'].isin(['PY', 'FY'])]

-- Assign this subset to a variable and then print it out to a .xlsx file on my desktop --
BF_CM_Static_Users = csv_data[csv_data['static'].isin(['PY', 'FY'])]
BF_CM_Static_Users.to_excel('BF_CM_Static_Users.xlsx',sheet_name='Users')
