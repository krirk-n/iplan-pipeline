mapid <- "41316079"
samplesize <- 1000

reticulate::source_python("py/arango.py")
reticulate::source_python("py/lem_classes.py")
reticulate::source_python("py/lem_functions.py")
reticulate::source_python("py/luc_change_simulation.py")
source("R/luc_change_simulation.R")

Carl_trials_three_results <- get_map_input(mapid)
luc_changes_df <- Carl_trials_three_results[[1]]
luc_matrix_df <- Carl_trials_three_results[[2]]
luc_list <- Carl_trials_three_results[[3]]

###
reticulate::source_python("py/extreme_case.py")
###

most_satisfied = py$most_satisfied
most_unsatisfied = py$most_unsatisfied