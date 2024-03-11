'''
authors: Binrui Yang, Krirk Nirunwiroj
'''

import sys
import json
import pandas as pd 
import numpy as np
import random
from collections import OrderedDict
import itertools 
from random import choices
import copy
import time
from random import randint

mapid = r["mapid"] # set your mapid here or you can pass it in the command line argument: "python3 preABCgenerator 12345678"

if len(sys.argv) == 2 and len(sys.argv[1]) == 8:
    mapid = sys.argv[1]
    
with open(r["wd"] + "/data/" + mapid + "_init_map.json") as f:
    init = json.load(f)

# Assuming 'multipliers.json' is needed, uncomment and use as needed
# with open(r["wd"] + "/data/" + 'multipliers.json') as f:
#     multiplier = json.load(f)

with open(r["wd"] + "/data/" + mapid + "_reps.json") as f:
    reps = json.load(f)

# Building the indicators keys multiplier table
indicator_keys_mult_table = {
    rep["Indicator"]: {init_luc["zone"]: init_luc["multipliers"][rep["Indicator"]] 
                       for init_luc in init["lucs"]} 
    for rep in reps
}

# Initializing dictionaries for significant and insignificant multipliers
sign_multiplier_dict = {key: {} for key in indicator_keys_mult_table.keys()}
insign_multiplier_dict = copy.deepcopy(sign_multiplier_dict)  # Deep copy to avoid reference issues

# Applying modified MAD method
threshold_multiplier = 5  # you can change it as appropriate  
for key in indicator_keys_mult_table.keys():
    values = np.array(list(indicator_keys_mult_table[key].values()))
    median = np.median(values)
    mad = np.median(np.abs(values - median))
    threshold_value = int(median + (threshold_multiplier * mad))
    sign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] >= threshold_value, indicator_keys_mult_table[key].items()))
    insign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] < threshold_value, indicator_keys_mult_table[key].items()))
    if len(insign_multiplier_dict[key]) == 0: # handle empty dict
        min_value = min(indicator_keys_mult_table[key].values())
        sign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] > min_value, indicator_keys_mult_table[key].items()))
        insign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] == min_value, indicator_keys_mult_table[key].items()))
    elif len(sign_multiplier_dict[key]) == 0: # handle empty dict
        max_value = max(indicator_keys_mult_table[key].values())
        insign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] < max_value, indicator_keys_mult_table[key].items()))
        sign_multiplier_dict[key] = dict(filter(lambda elem: elem[1] == max_value, indicator_keys_mult_table[key].items()))

# Parcel processing
parcels = {l["zone"]: {'area': 0, 'parcels': 0, 'name': l["name"]} for l in init["lucs"]}
matrix = {l['zone']: l['multipliers'] for l in init["lucs"]}

for p in init['parcels']:
    pKey = p['properties']['LUC']
    parcel_area = float(p['properties']['Area'])
    parcels[pKey]['area'] += parcel_area
    parcels[pKey]['parcels'] += 1

parcel_list = list(parcels.keys())
_list = [f"{i}_{j}" for i in parcel_list for j in parcel_list]

for i in range(len(parcel_list)):
    for j in range(len(parcel_list)): 
        _list.append(str(parcel_list[i]) + "_" + str(parcel_list[j]))
        
luc_list = list()
modify_list = list()
for i in range(len(init["parcels"])):
    luc_list.append(init["parcels"][i]["properties"])
    modify_list.append(init["parcels"][i]["properties"])
    
sh_list = list()
for i in range(len(reps)):
    sh_list.append(reps[i]["Name"])

original_luc_list = list()
for i in range(len(luc_list)):
    original_luc_list.append(luc_list[i]["LUC"])
    
end_luc_list = list()

a = time.time()
overall_iteration = 0


d = dict()
for i in range(len(sh_list)):
    d[sh_list[i]] = dict()
    d[sh_list[i]]["Yes"] = dict()
    d[sh_list[i]]["No"] = dict()
    for j in range(50): 
        d[sh_list[i]]["Yes"][j] = dict()
        d[sh_list[i]]["No"][j] = dict()
        
threshold_dict = dict()
for i in range(len(sh_list)):
    threshold_dict[sh_list[i]] = dict()
    threshold_dict[sh_list[i]]["Yes"] = dict()
    threshold_dict[sh_list[i]]["No"] = dict()
    for j in range(50):
        threshold_dict[sh_list[i]]["Yes"][j] = dict()
        threshold_dict[sh_list[i]]["No"][j] = dict()
        
# Processing each 'rep' for the satisfaction conditions
for i in sh_list:
    sh = i
    for j in reps:
        if j["Name"] == sh:
            sh_name = j["Name"]
            sh_indicator = j["Indicator"]
            sh_direction = j["Direction"]
            sh_initial_value = init["initialValues"][j["Indicator"]]
            sh_indicator_threshold = j["Threshold"]
            
    original_luc_list = list() # record 200 original parcels
    for k in range(len(luc_list)):
        original_luc_list.append(luc_list[k]["LUC"])
        
    
    if sh_direction == "Higher": 
            
        parcel_already_satisfied_index = list() 
        parcel_already_unsatisfied_index = list()
        for p in range(len(original_luc_list)):
            if original_luc_list[p] in sign_multiplier_dict[sh_indicator].keys():
                parcel_already_satisfied_index.append(p)
            if original_luc_list[p] in insign_multiplier_dict[sh_indicator].keys():
                parcel_already_unsatisfied_index.append(p)

            

    if sh_direction == "Lower":
        
        parcel_already_satisfied_index = list() 
        parcel_already_unsatisfied_index = list() 
        for q in range(len(original_luc_list)):
            if original_luc_list[q] in insign_multiplier_dict[sh_indicator].keys():
                parcel_already_satisfied_index.append(q)
            if original_luc_list[q] in sign_multiplier_dict[sh_indicator].keys():
                parcel_already_unsatisfied_index.append(q)
                
                
                
    satisfy_count = 0
    unsatisfy_count = 0
    bad_satisfy_iteration = 0
    bad_unsatisfy_iteration = 0
    
    
    while satisfy_count < 50: 
        temp_list = list(range(len(original_luc_list)))

        if len(parcel_already_satisfied_index) != 0 : 
            for idx in parcel_already_satisfied_index: 
                temp_list.remove(idx)

        index_list = random.sample(temp_list, len(temp_list))
        
        # calculate_threshold = sh_initial_value
        if sh_direction == "Higher":
            if sh_initial_value >= sh_indicator_threshold: 
                sh_initial_value = sh_indicator_threshold - 1
            calculate_threshold = sh_initial_value
            
                        
            area_change_list = list()
            luc_change_list = list()
            change_to_list = list()
            change_index_list = list()
            merged_list = list()
            for index in index_list:
                area = luc_list[index]["Area"]
                luc = luc_list[index]["LUC"]
                value = randint(0, len(sign_multiplier_dict[sh_indicator])-1)
                mult_value = sign_multiplier_dict[sh_indicator][list(sign_multiplier_dict[sh_indicator].keys())[value]]
                change_to_luc = list(sign_multiplier_dict[sh_indicator].keys())[value]
                calculate_threshold += (mult_value * area - insign_multiplier_dict[sh_indicator][luc]*area)
                area_change_list.append(area)
                luc_change_list.append(luc)
                change_to_list.append(change_to_luc)
                change_index_list.append(index)
                if calculate_threshold >= sh_indicator_threshold: 
                    break
                
            d[i]["Yes"][satisfy_count] = [luc_change_list, change_to_list, area_change_list, change_index_list]
            satisfy_count +=1
            overall_iteration+=1

        if sh_direction == "Lower":
            
            if sh_initial_value <= sh_indicator_threshold: 
                sh_initial_value = sh_indicator_threshold + 1
            calculate_threshold = sh_initial_value            
            area_change_list = list()
            luc_change_list = list()
            change_to_list = list()
            change_index_list = list()
            for index in index_list:
                area = luc_list[index]["Area"]
                luc = luc_list[index]["LUC"]
                value = randint(0, len(insign_multiplier_dict[sh_indicator])-1)
                mult_value = insign_multiplier_dict[sh_indicator][list(insign_multiplier_dict[sh_indicator].keys())[value]]
                change_to_luc = list(insign_multiplier_dict[sh_indicator].keys())[value]
                calculate_threshold += (mult_value * area - sign_multiplier_dict[sh_indicator][luc]*area)
                area_change_list.append(area)
                luc_change_list.append(luc)
                change_to_list.append(change_to_luc)
                change_index_list.append(index)
                if calculate_threshold <= sh_indicator_threshold: 
                    break

            d[i]["Yes"][satisfy_count] = [luc_change_list, change_to_list, area_change_list, change_index_list]
            satisfy_count +=1
            overall_iteration+=1

    while unsatisfy_count < 50: 
        temp_list = list(range(len(original_luc_list)))

        if len(parcel_already_unsatisfied_index) != 0 : 
            for idx in parcel_already_unsatisfied_index: 
                temp_list.remove(idx)

        index_list = random.sample(temp_list, len(temp_list))


        calculate_threshold = 0

        if sh_direction == "Higher":
            if sh_initial_value <= sh_indicator_threshold: 
                sh_initial_value = sh_indicator_threshold + 1
            calculate_threshold = sh_initial_value
            
                        
            area_change_list = list()
            luc_change_list = list()
            change_to_list = list()
            change_index_list = list()
            merged_list = list()
            for index in index_list:
                area = luc_list[index]["Area"]
                luc = luc_list[index]["LUC"]
                value = randint(0, len(insign_multiplier_dict[sh_indicator])-1)
                mult_value = insign_multiplier_dict[sh_indicator][list(insign_multiplier_dict[sh_indicator].keys())[value]]
                change_to_luc = list(insign_multiplier_dict[sh_indicator].keys())[value]
                calculate_threshold += (mult_value * area - sign_multiplier_dict[sh_indicator][luc]*area)
                area_change_list.append(area)
                luc_change_list.append(luc)
                change_to_list.append(change_to_luc)
                change_index_list.append(index)
                if calculate_threshold <= sh_indicator_threshold: 
                    break
            d[i]["No"][unsatisfy_count] = [luc_change_list, change_to_list, area_change_list, change_index_list]
            unsatisfy_count +=1
            overall_iteration+=1


        if sh_direction == "Lower":
            
            if sh_initial_value >= sh_indicator_threshold: 
                sh_initial_value = sh_indicator_threshold - 1
            calculate_threshold = sh_initial_value            
            area_change_list = list()
            luc_change_list = list()
            change_to_list = list()
            change_index_list = list()
            for index in index_list:
                area = luc_list[index]["Area"]
                luc = luc_list[index]["LUC"]
                value = randint(0, len(sign_multiplier_dict[sh_indicator])-1)
                mult_value = sign_multiplier_dict[sh_indicator][list(sign_multiplier_dict[sh_indicator].keys())[value]]
                change_to_luc = list(sign_multiplier_dict[sh_indicator].keys())[value]
                calculate_threshold += (mult_value * area - insign_multiplier_dict[sh_indicator][luc]*area)
                area_change_list.append(area)
                luc_change_list.append(luc)
                change_to_list.append(change_to_luc)
                change_index_list.append(index)
                if calculate_threshold >= sh_indicator_threshold: 
                    break

            d[i]["No"][unsatisfy_count] = [luc_change_list, change_to_list, area_change_list, change_index_list]
            unsatisfy_count +=1
            overall_iteration+=1


# Final DataFrame preparation and saving

df = pd.json_normalize(d, sep='_')
e = df.to_dict(orient='records')[0]
f = dict()

for i in e.keys():
    f[i] = dict.fromkeys(_list, 0)
for i in e.keys():
    change_from_l = e[i][0]
    change_to_l = e[i][1]
    area_l = e[i][2]
    
    for j in range(len(change_from_l)):
        change_from = e[i][0][j]
        change_to = e[i][1][j]
        area = e[i][2][j]
        
        for k in f[i].keys():
            if k.startswith(str(change_from)):
                if k.endswith(str(change_to)):
                    f[i][k] += area

final_df = pd.DataFrame(f).T

final_df.reset_index(inplace=True)
final_df[final_df.columns[1:]] = final_df[final_df.columns[1:]]/init['area']
df_name = "new_final_result_" + init["_key"] + ".csv"
final_df.to_csv(r['wd'] + "/data/" + df_name, index=False)
