
# coding: utf-8

# In[5]:

import pandas as pd
import numpy as np
import datetime as dt
from IPython.display import Image
import sys, argparse
import csv
from datetime import datetime
import warnings
warnings.filterwarnings("ignore")


# In[2]:

def clean_data(path):
    '''Takes a path to household_journal.csv and return a cleaned df'''
    df = pd.read_csv(path)
    #df.drop('Unnamed: 0', inplace=True, axis=1)
    df['JournalDate'] = pd.to_datetime(df.JournalDate)
    numerics = ['int16', 'int32', 'int64', 'float16', 'float32', 'float64', 'datetime64']
    df2 = df.select_dtypes(include=numerics)
    df2['JournalMonth'] = df2.loc[:,'JournalDate'].map(lambda x: x.month)
    df2['JournalYear'] = df2['JournalDate'].map(lambda x: x.year)
    return df2


# In[3]:

def get_current_families(df, date):
    '''Takes a df and returns a df filtered to FamilyId's with JournalDate entries for the current month
    Can also filter to families with JournalDate in the current year'''
    if date == None:
        today = dt.date.today()
    else:
        today = datetime.strptime(date, '%Y-%m-%d')
        
    cur_month = today.month
    cur_year = today.year
        
    current_families = df.loc[(df.JournalMonth == cur_month) & (df.JournalYear == cur_year), 'FamilyId']
    curr_families_df = df[df.FamilyId.isin(current_families)]
    return curr_families_df


# In[12]:

def ffill(df):
    '''Accepts a df and returns df with 0.0 values forward filled, except for 
    the most recent month's data. The df must have 0 values converted to np.nan, only first
    five columns are returned'''
    families = df.FamilyId.unique()
    cleaned_df = pd.DataFrame()
    for family in families:
        temp = df.loc[df['FamilyId'] == family]
        temp = temp[['FamilyId', 'JournalDate', 'month_in_fii', 'months_in_between', 'TotalIncome']]
        #temp = temp.iloc[:, :5]
        temp = temp.replace(0, np.nan)
        temp.iloc[:-1].fillna(method='ffill', inplace=True) 
        cleaned_df = cleaned_df.append(temp, ignore_index=True)
    return cleaned_df


# In[53]:

def get_stats(df):
    '''takes a dataframe and adds a rolling mean and std column for each family with enough history. If 
    there is not more than 3 rows of history, the familyId is written to a list and not included
    in output df. Returns a df and list'''
    
    fam_no_hist = []
    families = df.FamilyId.unique()
    main = pd.DataFrame()
    for f in families:
        temp = df.loc[df.FamilyId == f]
        if len(temp) > 3:
            temp = temp.sort_values(by='JournalDate')
            temp['rolling_mean'] = temp.TotalIncome.rolling(window=3).mean()
            temp['std'] = round(np.std(temp.TotalIncome))
            main = main.append(temp)
        else:
            fam_no_hist.append(f)
    return main, fam_no_hist
            


# In[10]:

def anomalous(df):
    '''takes a df of failies with more than 3 months of history and returns a list of FamilyIds where the 
    difference between the current months TotalIncome number and the rolling mean of the FamilyId's 
    TotalIncome history is larger than the std of the history of TotalIncome'''
    anomalous = []
    families = df.FamilyId.unique()
    main = pd.DataFrame()
    for f in families:
        temp = df.loc[df.FamilyId == f]
        if abs(temp.iloc[-1][4] - temp.iloc[-2][4]) > temp.iloc[-1,-1]:
            temp_list = [f, max(temp.month_in_fii), temp.iloc[-1][4], temp.iloc[-2][4] ,temp.iloc[-1,-1]]
            anomalous.append(temp_list)
        else:
            continue
    return anomalous
        


# In[43]:

def stats_all_fam(df):
    # not using this, we should add families with not enough history to anomalous list
    '''takes a df of all current families and calculates the mean and std of TotalIncome using only the 
    most recent month of financial data
     '''
    families = df.FamilyId.unique()
    main = pd.DataFrame()
    for f in families:
        temp = df.loc[df.FamilyId == f]
        temp = temp.sort_values(by='JournalDate')
        temp2 = temp.iloc[-1,:]
        main = main.append(temp2)
    
    mean = round(np.mean(main.TotalIncome))
    std = round(np.std(main.TotalIncome))
       
    return mean,std


# In[11]:

def no_hist_anomalous(df, lst):
    # not using this
    stats = stats_all_fam(df)
    anomalous = []
    for f in lst:
        temp = df.loc[df.FamilyId == f]
        #if abs(temp.iloc[-1,4] - stats[0]) > stats[1]:
        #print ("familyID = %s, months in FII %s, current = %s, mean = %s, std = %s" % 
        #(f, max(temp.month_in_fii), temp.iloc[-1][4], stats[0] ,stats[1]))
        temp_list = [f, max(temp.month_in_fii), temp.iloc[-1][4], stats[0] ,stats[1]]
        anomalous.append(temp_list)
           
    return anomalous


# In[ ]:

def parse_args():
    parser = argparse.ArgumentParser(description="An audit program for finding anamalous total income changes.             Please enter the file household_journal.csv and the date to be audited. If household_journal.csv             is not in the directory where the script is executing, pls enter the absoluted path of the file.")
    
    
    parser.add_argument("data", help = "Include the full path to household_journal.csv ")
    parser.add_argument("date", help = "Enter the month in the format yyyy-mm-01, day should always be entered as 01",                         nargs='?', default=None)
    args = parser.parse_args()
    
    return args


# In[45]:

def main(data, date):
    df = get_current_families(clean_data(data), date)
    if len(df) == 0:
        print "There is no data available for the month entered."
        quit()
    df = ffill(df)
    df2, fam_no_hist_list = get_stats(df)
    fam_list = anomalous(df2)
    fam_list2 = no_hist_anomalous(df, fam_no_hist_list)
    fam_list.extend(fam_list2)
  
    output = 'anomalous.csv'
    with open(output, 'wb') as f:
        wr = csv.writer(f, delimiter=',')
        wr.writerow(['FamilyID', 'MonthsInFII', 'TotalIncome', 'Mean', 'STD'])
        for f in fam_list:
            wr.writerow([f[0], f[1], f[2], f[3], f[4]])
            
    print "Done! %s has been created and is in the current directory." %output
            
if __name__ == "__main__":
    args = parse_args()
    print args.data, args.date
    main(args.data, args.date)


# In[ ]:




# In[ ]:



