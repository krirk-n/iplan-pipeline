library(reticulate)
library(jsonlite)
library(tidyverse)

# run python code to create database connection classes 
reticulate::source_python('py/arango.py')
# run python code to create lem classes
reticulate::source_python('py/lem_classes.py')
# run python code to create lem functions
reticulate::source_python('py/lem_functions.py')
# setting a map id
# mapid = '41316309'#'41316079'#'41313738'
# mapid = "44707213"
# set sample size
samplesize = 10000

# run the python code to get the simulation results
reticulate::source_python('py/luc_change_simulation.py') 
# check the result
init_map = py$init_map
luc_changes = py$luc_changes
luc_matrix = py$luc_matrix
# convert data to data.frame
luc_changes_df = as.data.frame(fromJSON(jsonlite::toJSON(luc_changes)))
luc_matrix_df = as.data.frame(fromJSON(jsonlite::toJSON(luc_matrix)))

luc_list = colnames(py$matrixA)

reticulate::source_python('py/proc_ZH.py')
Carl_trials <- py$df2

table(Carl_trials$Ezra)
table(Carl_trials$Said)
table(Carl_trials$Lamont)
table(Carl_trials$Andre)
table(Carl_trials$Ed)
table(Carl_trials$Grace)
table(Carl_trials$Natalie)
table(Carl_trials$Dwayne)
table(Carl_trials$Maya)