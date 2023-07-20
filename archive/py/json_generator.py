import sys
sys.path.insert(0, 'D:\Projects\Epistemic Learning\iPlan\lem-analysis\py')

import lem_functions_2 as lf
import lem_classes as lc
import arango
import sys
import os
import json,ast
from pandas import DataFrame
import itertools
import math
import numpy as np
import random
import json
import pandas as pd
import warnings
import csv

mapid = r["mapid"]
samplesize = r["samplesize"]

# connect to db
user_db = arango.UserDB()
user_db.connect()
map_by_id = user_db.get_map(mapid, rawResults=True)
submissions = user_db.get_submissions_collection()
example = { 'mapKey': mapid }
submissions_by_mapid = submissions.fetchByExample(example, batchSize = 40, count = True)

# get map by id
map_json=user_db.get_map(mapid,rawResults=True)
init_map=map_json

map_id_json = mapid + ".json"
with open(map_id_json, 'w') as f:
    json.dump(map_json, f)
    
d = json.dumps(init_map)
init_map_name = mapid + "_init_map.json"
with open(init_map_name, "w") as c:
    c.write(d)
    c.close()

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

j = json.dumps(reps)
reps_map_name = mapid + "_reps.json"
with open(reps_map_name, 'w') as f:
    f.write(j)
    f.close()