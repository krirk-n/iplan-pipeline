# DocumentNotFoundError. Cannot find these id in arangoURL="http://52.40.108.10:8529" (arango.py)
# mapid <- "17157832" # 10/4 
# mapid <- "28357211" # 10/4 
# mapid <- "36380291" # 10/26 
# mapid <- "11577915"
# mapid <- "32559592"
# mapid <- 41396079

# can find these id in arangoURL="http://52.40.108.10:8529"
# mapid <- "36874297" # 11/2
# mapid <- "41313738" # 03/04 jais map id
# mapid <- "41316309" # 03/04 jais map id # Olivia always Yes, Kady always No
# mapid <- "41316079" # 03/04 jais map id # Olivia always Yes, Kady always No
# mapid <- "33432648" # 03/06 yuanru map

# 0415 Jais map
# mapid <- "44137871" # is a rural low population map with ag indicators 
# mapid <- "44137975" 
# is the same rural low population map with the jobs/pop indicators we've been using
# mapid <- "44138061"
# is one of the high population maps we've been using but with the ag indicators noted above


mapid <- "41316079"
samplesize <- 10000

reticulate::source_python("py/arango.py")
reticulate::source_python("py/lem_classes.py")
reticulate::source_python("py/lem_functions.py")
reticulate::source_python("py/luc_change_simulation.py")
source("R/luc_change_simulation.R")

Carl_trials_three_results <- get_map_input(mapid)
luc_changes_df <- Carl_trials_three_results[[1]]
luc_matrix_df <- Carl_trials_three_results[[2]]
luc_list <- Carl_trials_three_results[[3]]

reticulate::source_python('py/proc_ZH.py')
Carl_trials <- py$df2
# map_area <- py$Allocation$total_area
# map_area

Carl_trials_sh_freq <- as.data.frame(apply(Carl_trials[,-c(1:122)], 2, table)) 
Carl_trials_sh_freq

# Ziling task starts here

# This what we do now: Random sample from the whole set, for each stakeholder, sample 50 map trials for satisfied and 50 for not satisfied
stakeholders <- colnames(Carl_trials)[123:131]
stakeholders

Carl_trials_sampled <- Carl_trials[FALSE, ]
Carl_trials_sampled
sample.size <- 50
for(col.i in c(123:131)){
  stakeholder.satisfication <- Carl_trials[Carl_trials[,col.i] == "Yes", ]
  stakeholder.satisfication.sampled <- stakeholder.satisfication[sample(nrow(stakeholder.satisfication), sample.size, replace = TRUE), ]
  Carl_trials_sampled <- rbind(Carl_trials_sampled, stakeholder.satisfication.sampled)
  
  stakeholder.unsatisfication <- Carl_trials[Carl_trials[,col.i] == "NO", ]
  stakeholder.unsatisfication.sampled <- stakeholder.unsatisfication[sample(nrow(stakeholder.unsatisfication), sample.size, replace = TRUE), ]
  Carl_trials_sampled <- rbind(Carl_trials_sampled, stakeholder.unsatisfication.sampled)
}
Carl_trials_sampled

# Ziling task: instead of random sampling 50+50 for each stakeholder, find 50 most satisfied and 50 most unsatisfied maps for each stakeholder
# add your code here or edit what's above 