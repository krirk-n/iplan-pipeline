# -*- coding: utf-8 -*-
"""
Created on August 2021

@author: zhiqiang cai
"""
import sys
import os
import json,ast
from pandas import DataFrame
import itertools
import math
import numpy as np
import random

# This program is created to simulate users' changes to luc for a given map
# R should run the following 3 py programs first:
#   1) arango.py
#   2) lem_classes.py
#   3) lem_functions.py
# Input from R:
#     1) mapid - a mapid for an existing map
#     2) samplesize - number of maps to simulate.
# The program simulate the way how users may select a parcel and change the luc of the parcel
# The data can be found in 
#       1) luc_changes
#       2) luc_matrix

# connect to db
user_db = UserDB()
user_db.connect()

# input from R
# Get a map by id
# mapid = '44137871'
# mapid = '44138061'

#mapid = '41316079' old version
#mapid = '44137975'
#mapid = "41313738"
# mapid = "44138061"
# mapid = "44137871"
# mapid = "48008733"
# mapid = "44137871"
# mapid = "48008733"
# mapid = "44137975"
# mapid = "44707213"
mapid = "44707151"
mapid = r["mapid"]
sample_size=10000
sample_size = int(r["samplesize"])

# output to R

luc_changes=[]
luc_matrix=[]

# get map by id
map_json=user_db.get_map(mapid,rawResults=True)
init_map=map_json

import json
#j = json.dumps(reps)
map_id_json = mapid + ".json"
with open(map_id_json, 'w') as f:
    json.dump(map_json, f)
    
d = json.dumps(init_map)
init_map_name = mapid + "_init_map.json"
with open(init_map_name, "w") as c:
  c.write(d)
  c.close()
  
# map_json = map_json_list[0]
biome = map_json["biome"]
# extract information about stakeholders (representatives)
reps = []
for i in map_json['indicators']:
    iCount = 0
    for s in i['stakeholders']:
        reps.append({
            'isx': iCount,
            'Representative': len(reps),
            'Name': str(s['name']),
            "Indicator": str(i['key']),
            "Direction": str(s['direction']).capitalize(),
            "Threshold": s['threshold']
        })
        iCount += 1

# YT edits : export JSON
import json
j = json.dumps(reps)
reps_map_name = mapid + "_reps.json"
with open(reps_map_name, 'w') as f:
    f.write(j)
    f.close()

# create a list of parcels indexed by lucs
matrix = {}
parcels = {}
for l in map_json["lucs"]:
    parcels[l["zone"]] = {
        'area': 0,
        'parcels': 0,
        'name': l["name"]
    }
    matrix[l['name']] = l['multipliers']
# put parcels with the same luc together, not sure if this is necessary
parcel_set = set()
for p in map_json['parcels']:
    #pKey = p['properties'][Config.get("parcel_keys", "LUC")]
    pKey = p['properties']['LUC']
    #parcels[pKey]['area'] += float(p['properties'][Config.get("parcel_keys", "AREA")])
    #parcel_area = float(p['properties'][Config.get("parcel_keys", "AREA")])
    parcel_area = float(p['properties']['Area'])
    parcels[pKey]['area'] += parcel_area
    parcels[pKey]['parcels'] += 1
    parcel_set.add( Parcel(len(parcel_set), parcel_area ,parcels[pKey]["name"]))
parcelValues = parcels.values()
matrixA = DataFrame.from_dict(matrix).transpose()
#
stakeholders = reps
input_parcels = parcelValues
n_randomallocations = sample_size
# get reps
representatives = []
for i in range(len(stakeholders)):
    rep_json = stakeholders[i]
    rp = Representative(rep_json, matrixA, i)
    rp.threshold=rep_json['Threshold']
    representatives.append(rp)
read_map(input_parcels)

parcels0 = parcel_set
# init_map_file = open("init_map.txt","w")
# init_map_file.write ("parcle_id\tarea\tluc\n")
# for p in parcels0:
#     init_map_file.write(str(p.ix) +"\t"+str(p.area)+"\t"+p.land_use+"\n")
#  init_map_file.close()

# init map luc area
Allocation.initial_allocation = Allocation(parcels0)
Allocation.all_lucs = list(matrixA.index) 
Allocation.parcels0 = sorted(parcels0, key=lambda x: x.area)
Allocation.p_areas_prop = [p.area / Allocation.total_area for p in Allocation.parcels0]

num_of_parcels = len(parcels0)
npc_min = 5 # min number of parcel changes
npc_max = 0.2*num_of_parcels # max number of parcel changes
npc_mean = 0.1*num_of_parcels # mean number of parcel changes
npc_sd = 0.25*num_of_parcels   # standard deviation of number of parcel changes
 
# start simulation
# luc_changes will have format like luc_0_0:1;luc_0_1:2;...upto luc_10_10
allocations2 = []
allocations2.append(Allocation(parcels0))
allocations2[0].aix = itertools.count(1)
n_sample=sample_size

for i in range(n_sample): # sample n maps as variation of initial map
        # determine the number of parcles to change
    k = int(math.ceil(np.random.normal(npc_mean,npc_sd))) 
    if k<npc_min:
        k=npc_min
    if k>npc_max:
        k=npc_max
        # generate a map with k parcels LUC changed and add to the sample
    allocations2.append(Allocation.randomAllocation_2(k, 0.005, 0.0025,0.001,0.5,i,luc_changes))

    # calculate indicator values for each allocation
Allocation.n_alloc = len(allocations2)
for a in allocations2:
    a.calculate_indicators(matrixA)
    # segment indicators and compute delta sets for each rep
#Indicator.createIndicators2(allocations2)
    # compute stakeholder satisfactory
    #stakeholder_file = open("stakeholder.txt","w")
    #stakeholder_file.write("stakeholder\tindicator\tthreshold\tinit_value\tdirection\tinit_map_satisfied\n")

for k in range(len(allocations2)):
    for i in range(len(representatives)):
        rp = representatives[i]
        s = stakeholders[i]
        indicator_value = allocations2[k].indicators[s["Indicator"]]
        satisfied = "NO"
        if s["Direction"]=="Higher" and indicator_value[0]>rp.threshold:
            satisfied = "Yes"
        elif s["Direction"]=="Lower" and indicator_value[0]<rp.threshold:
            satisfied = "Yes" 
        luc_matrix.append({
            'mapid':k,
            'stakeholder':s["Name"],
            'satisfied':satisfied,
            'indicator':s["Indicator"],
            'indicator_value':indicator_value[0],
            'threshold':rp.threshold,
            'direction':s["Direction"]
        })
    #        luc_line2+="\t"+satisfied+"\t"+str(indicator_value[0])+"\t"+str(r.threshold)+"\t"+s["Direction"]
    #    luc_writer_2.write(luc_line2+"\n")
    #luc_writer_2.close()
    # for i in range(1,len(allocations)):
    #    for p in allocations[i].parcels:

    # luc = allocations[0].all_lucs.index(lucName)
    #return [{'indicator_str': ob.indicator_str, 'b': ob.threshold} for ob in representatives]



