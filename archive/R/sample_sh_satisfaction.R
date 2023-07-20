# setwd("~/Documents/lem-analysis-pipeline")
setwd("D:/Projects/Epistemic Learning/iPlan/lem-analysis")
library(dplyr)
library(rENA)
library(plotly)
library(directedENA)

### mapids we have been using for testing ####
# if you get 'document not found' error, that usually means database in Arrango.py is not correct

# Jais Jul 14 mapid
mapid <- "44707213"
# mapid <- "44707151"
# mapid <- "44706415"
# 
# # Jais mapid
# mapid <- "44137975" # is the same rural low population map with the jobs/pop indicators we've been using 
# mapid <- "44138061" # is one of the high population maps we've been using but with the ag indicators noted above
# mapid <- "44137871" # is a rural low population map with ag indicators 
# 
# # mapid <- "17157832" 
# # mapid <- "28357211" 
# # mapid <- "36380291" 
# # mapid <- "11577915"
# # mapid <- "32559592"
# mapid <- "41396079" # the mapid i've been using to test ONA
# mapid <- "36874297" # 11/2
# mapid <- "41313738" # 03/04 
# mapid <- "41316309" # 03/04 
# mapid <- "33432648" # 03/06 
# mapid <- "41313738"

# source py files we will need. Run simulation.
samplesize <- 10000
reticulate::source_python("py/arango.py")
reticulate::source_python("py/lem_classes.py")
reticulate::source_python("py/lem_functions.py")
reticulate::source_python("py/luc_change_simulation.py")
source("R/luc_change_simulation.R")
reticulate::source_python("py/get_a_map_by_id.py")

# get simulated results
sim_results<- get_map_input(mapid)
mapid # check mapid here because sometimes we forgot to remove test mapid in where get_map_input is defined
luc_changes_df <- sim_results[[1]]
luc_matrix_df <- sim_results[[2]]
luc_list <- sim_results[[3]]
init_map = py$init_map # is this the initial organic base map?

# get simulated results in luc_x_y format. 
reticulate::source_python('py/proc_ZH.py')
sim_areachange_vote <- py$df2
sim_areachange_vote

# we use this to check if there are any SHs always satisfy or always not satisfy, which we don't want it to happen. 
# because if this happens we won't be able to sample 50 maps for each SH yes and no 
# if this happens, we need to check luc_change_simulation.py to see what's wrong
sim_areachange_vote_sh_freq <- as.data.frame(apply(sim_areachange_vote[,-c(1:122)], 2, table)) 
sim_areachange_vote_sh_freq

# based on simulated results, random sample from the whole set: for each stakeholder, sample 100 map trials for satisfaction and 100 for unsatisfaction.
shs <- colnames(sim_areachange_vote)[123:131]
shs

sim_areachange_vote_sampled <- sim_areachange_vote[FALSE, ]
sim_areachange_vote_sampled

sample.size <- 50

for(col.i in c(123:131)){
  sh.yes <- sim_areachange_vote[sim_areachange_vote[,col.i] == "Yes", ]
  sh.yes.sampled <- sh.yes[sample(nrow(sh.yes), sample.size, replace = TRUE), ]
  sim_areachange_vote_sampled <- rbind(sim_areachange_vote_sampled, sh.yes.sampled)
  
  sh.no <- sim_areachange_vote[sim_areachange_vote[,col.i] == "NO", ]
  sh.no.sampled <- sh.no[sample(nrow(sh.no), sample.size, replace = TRUE), ]
  sim_areachange_vote_sampled <- rbind(sim_areachange_vote_sampled, sh.no.sampled)
}

sim_areachange_vote_sampled

# check if any SH's yes or no has <50, which we don't want to happen
sim_areachange_vote_sampled_sh_freq<- as.data.frame(apply(sim_areachange_vote_sampled[,-c(1:122)], 2, table)) 
sim_areachange_vote_sampled_sh_freq

# this was just trying to rearrange individual SH column Yes/No to a centralized Stakeholder column
ncol(sim_areachange_vote_sampled)
sim_areachange_vote_sampled$stakeholder <- rep(colnames(sim_areachange_vote)[123:131], each=100)
sim_areachange_vote_sampled$value <- rep(rep(c("Yes", "NO"), each=sample.size),times=9)
sim_areachange_vote_sampled

# "normalize" by dividing map area
map_area <- py$Allocation$total_area
map_area

sim_areachange_vote_sampled[,c(2:122)] <- sim_areachange_vote_sampled[,c(2:122)]/map_area
head(sim_areachange_vote_sampled,3)

sim_areachange_vote_sampled # is what we need to following analysis

# save everything for markdown later
setwd("D:\Projects\Epistemic Learning\iPlan\lem-analysis")

saveRDS(sim_results, "sim_results.rds")
saveRDS(luc_changes_df, "luc_changes_df.rds")
saveRDS(luc_matrix_df, "luc_matrix_df.rds")
saveRDS(luc_list, "luc_list.rds")

saveRDS(sim_areachange_vote, "sim_areachange_vote.rds") # 10000 times
saveRDS(sim_areachange_vote_sampled, "sim_areachange_vote_sampled.rds") # 50 times 

saveRDS(mapid, "mapid.rds")
saveRDS(map_area, "map_area.rds")
saveRDS(init_map, "init_map.rds")

saveRDS(most_satisfied, "most_satisfied.rds")
# saveRDS(most_unsatisfied, "most_unsatisfied.rds")

# for a given mapid, we can get its submission data. We don't need this for simulation, I just leave them here for now. 
length(submissions_by_mapid$response$result)
submissions_by_mapid$response$result[[1]]$name
submissions_by_mapid$response$result[[2]]$name
submissions_by_mapid$response$result[[1]]$indicatorValues
submissions_by_mapid$response$result[[2]]$stakeholderApproval
submissions_by_mapid$response$result[[5]]$LUCStates

# notes to sample extreme 50 cases 
most_satisfied
most_unsatisfied

# most satisfied
ms_df = data.frame(t(data.frame(most_satisfied)))
ms_df$value = "Yes"
ms_df$stakeholder <- row.names(ms_df)
colnames(ms_df)[1] <- "id"
# ms_df$stakeholder = gsub("\\.[0-9]*$","", ms_df)
ms_df$stakeholder = rep(colnames(Carl_trials)[123:131], each=50)
head(ms_df)

# most unsatisfied
muns_df = data.frame(t(data.frame(most_unsatisfied)))
muns_df$value = "No"
muns_df$stakeholder <- row.names(muns_df)
colnames(muns_df)[1] <- "id"
muns_df$stakeholder = rep(colnames(Carl_trials)[123:131], each=50)
head(muns_df)

# combine two df
extreme_cases = rbind(ms_df, muns_df)

# merge to Carl_trials
sim_areachange_vote_sampled = merge(Carl_trials,extreme_cases, by="id")
sim_areachange_vote_sampled = na.omit(sim_areachange_vote_sampled)