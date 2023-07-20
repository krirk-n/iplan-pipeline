import pandas as pd
# warnings.filterwarnings("ignore")

df = pd.DataFrame(r['luc_matrix_df'])

stakeholder_name = list(df[df['mapid']==0]['stakeholder'])

most_satisfied={}
most_unsatisfied={}

for name in stakeholder_name:
    most_satisfied[name]=[]
    most_unsatisfied[name]=[]

for i in range(len(df)):
    info = df.iloc[i]
    mapid, name, val, direction = info['mapid'], info['stakeholder'], info['indicator_value'], info['direction']
    
    most_satisfied[name].append((mapid,val))
    most_satisfied[name] = sorted(most_satisfied[name], key=lambda x: x[1], reverse=direction=='Higher')

    most_unsatisfied[name].append((mapid,val))
    most_unsatisfied[name] = sorted(most_unsatisfied[name], key=lambda x: x[1], reverse=direction=='Lower')
    
for name in most_satisfied:
    most_satisfied[name] = [i[0] for i in most_satisfied[name][:50]]
    most_unsatisfied[name] = [i[0] for i in most_unsatisfied[name][:50]]

# for name in most_satisfied:
#   print(name, most_satisfied[name])
