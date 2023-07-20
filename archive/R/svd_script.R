# Remember to change the mapid in the following scripts: 
# luc_change_simulation.py
# carl_generation_trials_10000.R
# get_map_by_id.R
# luc_change_simulation.R


rm(list = ls())
setwd("~/Desktop/a")

library(dplyr)
library(tidyverse)
library(rENA)
library(plotly)
# library(directedENA)

### mapids we have been using for testing ####

#Binrui's Map
# mapid = "48008733" # change residential to wetland (19 parcel)
# mapid = "48008333" #change residential and biofuel to wetland
# mapid = "47973057"
# 

# Jais mapid （OLD)
#mapid = "44137975" # is the same rural low population map with the jobs/pop indicators we've been using 
#mapid <- "44138061" # is one of the high population maps we've been using but with the ag indicators noted above
# mapid <- "44137871" # is a rural low population map with ag indicators

# Jais mapid (NEW 7/14/2022)
# mapid = "44707213"
# mapid = "44707151"
# mapid = "44706415"
# source py files we will need. Run simulation.
samplesize <- 10000
reticulate::source_python("py/arango.py")
reticulate::source_python("py/lem_classes.py")
reticulate::source_python("py/lem_functions.py")
reticulate::source_python("py/luc_change_simulation.py")
source("R/luc_change_simulation.R")
reticulate::source_python("py/get_a_map_by_id.py")

init_map = py$init_map # is this the initial organic base map?

# get simulated results in luc_x_y format. 
reticulate::source_python('py/proc_ZH.py')
sim_areachange_vote <- py$df2
# sim_areachange_vote

# we use this to check if there are any SHs always satisfy or always not satisfy, which we don't want it to happen. 
# because if this happens we won't be able to sample 50 maps for each SH yes and no 
# if this happens, we need to check luc_change_simulation.py to see what's wrong
sim_areachange_vote_sh_freq <- as.data.frame(apply(sim_areachange_vote[,-c(1:122)], 2, table)) 
# sim_areachange_vote_sh_freq

# based on simulated results, random sample from the whole set: for each stakeholder, sample 100 map trials for satisfaction and 100 for unsatisfaction.
shs <- colnames(sim_areachange_vote)[123:131]

#shs

sim_areachange_vote_sampled <- sim_areachange_vote[FALSE, ]
# sim_areachange_vote_sampled

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

sim_areachange_vote_sampled_sh_freq<- as.data.frame(apply(sim_areachange_vote_sampled[,-c(1:122)], 2, table)) 
sim_areachange_vote_sampled_sh_freq

sim_areachange_vote_sampled = sim_areachange_vote_sampled %>% 
  pivot_longer(cols = all_of(shs), names_to = 'stakeholder', values_to = 'value')

# "normalize" by dividing map area
map_area <- py$Allocation$total_area
map_area

sim_areachange_vote_sampled[,c(2:122)] <- sim_areachange_vote_sampled[,c(2:122)]/map_area
head(sim_areachange_vote_sampled,3)

sim_areachange_vote_sampled # is what we need to following analysis

# Binrui's Edit: Only Select stakeholder yes sample and calculate mean
yes_sim_areachange_vote_sampled_mean = sim_areachange_vote_sampled %>% 
  filter(value == "Yes") %>% 
  group_by(stakeholder, value) %>% 
  summarise_at(vars(luc_0_0:luc_10_10), mean)

# Binrui's Edit: Only Select stakeholder no sample and calculate mean
no_sim_areachange_vote_sampled_mean = sim_areachange_vote_sampled %>% 
  filter(value == "NO") %>% 
  group_by(stakeholder, value) %>% 
  summarise_at(vars(luc_0_0:luc_10_10), mean)


length(submissions_by_mapid$response$result)
#Last Submission's lucs:
submissions_by_mapid$response$result[[length(submissions_by_mapid$response$result)]]$lucs

write.csv(yes_sim_areachange_vote_sampled_mean, "jais_yes_mean.csv")
write.csv(no_sim_areachange_vote_sampled_mean, "jais_no_mean.csv")
write.csv(submissions_by_mapid$response$result[[length(submissions_by_mapid$response$result)]]$lucs, "last_sub_lucs.csv")