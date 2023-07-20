import sys
import os
import json

user_db = UserDB()
user_db.connect()
r["map_by_id"]=user_db.get_map(r["mapid"],rawResults=True)
# r["submission_by_id"]=user_db.get_submissions_collection()
r["submissions"] = user_db.get_submissions_collection()
#r["submission_by_id"] = user_db.get_submissions_collection().simpleQuery('all', "mapKey" == '41316309')

example = { 'mapKey': r["mapid"] }
r["submissions_by_mapid"] = r["submissions"].fetchByExample(example, batchSize = 40, count = True)
