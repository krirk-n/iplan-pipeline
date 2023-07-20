library(reticulate)

# run python code to create database connection classes 
reticulate::source_python('py/arango.py')

# setting the map id
# mapid = '11577915'
# mapid = '41316079'
# mapid = '44138061'

# create a variable to store the map
map_by_id=NULL
submission_by_id = NULL

# run the python code to get the map
reticulate::source_python('py/get_a_map_by_id.py') 


# check the map
map_by_id
submission_by_id 
