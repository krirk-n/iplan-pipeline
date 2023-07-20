import pandas as pd
import warnings
warnings.filterwarnings("ignore")

df = pd.DataFrame(r['luc_changes_df'])
df['from_to'] = df['from_luc'] + ' --> ' + df['to_luc']
m = {"Commercial":0, "Conservation":1, "Cropland":2, "Industrial":3, "Limited Use":4, "Pasture":5,
     "Recreation":6, "Residential HD":7, "Residential LD":8, "Timber":9, "Wetlands": 10}
cn = list(m.keys())
cn_c = []
m2 = {}
for i in range(11):
    for j in range(11):
        a, b = cn[i], cn[j]
        st = "luc_" + str(m[a]) + '_' + str(m[b])
        cn_c.append(st)
        m2[a + ' --> ' + b]=st
col_name = ['id']
col_name.extend([m2[i] for i in m2])
df2 = pd.DataFrame(columns = col_name)
df2['id'] = range(int(r["samplesize"]))
for i in range(int(r["samplesize"])):
    sub_df = df[df['sample_id'] == i]
    for j in range(len(sub_df)):
        ft = sub_df.iloc[j]['from_to']
        df2.at[i, m2[ft]] = sub_df.iloc[j]['changed_area']
df2 = df2.fillna(0)

df = pd.DataFrame(r['luc_matrix_df'])[9:]
for i in range(int(r["samplesize"])):
    sub_df = df[df['mapid'] == i+1]
    for j in range(len(sub_df)):
        name = sub_df.iloc[j]['stakeholder']
        df2.at[i, name] = sub_df.iloc[j]['satisfied']
