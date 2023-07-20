import sys
import os
import json
import rpy2.robjects as robjects


user_db = UserDB()
user_db.connect()
robjects.r["map_by_id"]=user_db.get_map(robjects.r["mapid"],rawResults=True)
# r["submission_by_id"]=user_db.get_submissions_collection()
robjects.r["submissions"] = user_db.get_submissions_collection()
#r["submission_by_id"] = user_db.get_submissions_collection().simpleQuery('all', "mapKey" == '41316309')

example = { 'mapKey': robjects.r["mapid"] }
robjects.r["submissions_by_mapid"] = robjects.r["submissions"].fetchByExample(example, batchSize = 40, count = True)
