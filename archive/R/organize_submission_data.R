# Remember to change the mapid in the following scripts: 
# luc_change_simulation.py
# carl_generation_trials_10000.R
# get_map_by_id.R
# luc_change_simulation.R

rm(list = ls())
setwd("~/Documents/GitHub/iplan/lem-analysis-pipeline")

library(dplyr)
library(tidyverse)
library(rENA)
library(plotly)
#library(directedENA)


### Yuanru's Mapid: 

mapid = "30176134"

# mapid = "53517894"
# mapid = "53311543"
# mapid = "51482082"

# mapid = "51481397"
# mapid = "54088862"

# mapid = "54089601"
# mapid = "54131974" 
# mapid = "54132850" 
# mapid = "53998196"
# mapid = "53998818"
# mapid = "54082538"
# mapid = "54083201"
# mapid = "54086166"
# mapid = "54086920"
# mapid = "54229750"
# mapid = "54230900"
# mapid = "54232933"
# mapid = "54234175"


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

sub_result = submissions_by_mapid$response$result

name1 = names(sub_result[[1]])
name2 = names(sub_result[[1]]$stakeholderApproval)
name = append(name1, name2)


df = data.frame(matrix(ncol = length(name), nrow = length(sub_result)))
colnames(df) = name


df = df %>% 
  select(-c(indicatorValues, LUCStates, lucs, stakeholders, stakeholderApproval))


for (i in 1:length(sub_result)){
  df$`_key`[i] = sub_result[[i]]$`_key`
  df$`_id`[i] = sub_result[[i]]$`_id`
  df$`_rev`[i] = sub_result[[i]]$`_rev`
  df$name[i] = sub_result[[i]]$name
  df$mapKey[i] = sub_result[[i]]$mapKey
  df$date[i] = sub_result[[i]]$date
  df$final[i] = sub_result[[i]]$final
  df$submissionCount[i] = sub_result[[i]]$submissionCount
  df$parcelsChanged[i] = sub_result[[i]]$parcelsChanged
  df$areaChanged[i] = sub_result[[i]]$areaChanged
  df$percentChanged[i] = sub_result[[i]]$percentChanged
  df$approvalCount[i] = sub_result[[i]]$approvalCount
  df$requestsUsed[i] = sub_result[[i]]$requestsUsed
  df$userKey[i] = sub_result[[i]]$userKey
  
  
  for (j in 1:length(names(sub_result[[i]]$stakeholderApproval))){
    
    
    if (sub_result[[i]]$stakeholderApproval[[j]] == TRUE){
      df[colnames(df) == names(sub_result[[i]]$stakeholderApproval[j])][i,] = "TRUE"
      
    }else{
      df[colnames(df) == names(sub_result[[i]]$stakeholderApproval[j])][i,] = "FALSE"
      
    }
    
  }
  
}



# path = "/Users/yang/Desktop/Yuanru_task/"
# filename = paste0(path, mapid, ".csv")

# write.csv(df, filename)

write.csv(df, "30176134_all_submissions.csv")


# write.csv(submissions_by_mapid$response$result[[length(submissions_by_mapid$response$result)]]$lucs, "last_sub_lucs.csv")


# bind all csv together 
library(data.table)
setwd("~/Documents/hci")
df2 <-
  list.files(path = "~/Documents/hci", pattern = "*.csv") %>%
  map_df(~fread(.))
df2

View(df2)
df2 <- select(df2, -c("V1", "_key", "_rev","date"))

write.csv(df2, "df.csv")
