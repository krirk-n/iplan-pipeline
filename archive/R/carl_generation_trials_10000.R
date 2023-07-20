library(dplyr)
# library(rENA)
# library(plotly)
# library(directedENA)

# setwd("~/Documents/lem-analysis-pipeline")

# mapid <- "41316079"
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
# delete this 

# Q for carl or cody: failed to reticulate luc_simulation.py when using arangoURL="http://44.231.24.74:8529"

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

#mapid <- "41316079" # 03/04 jais map id # Olivia always Yes, Kady always No
# mapid <- "33432648" # 03/06 yuanru map

# Jais mapid needs Json and submission 
#mapid <- "44138061" # is one of the high population maps we've been using but with the ag indicators noted above
#mapid <- "44137871" # is a rural low population map with ag indicators 

length(submissions_by_mapid$response$result)

submissions_by_mapid$response$result[[1]]$name
submissions_by_mapid$response$result[[8]]$name
submissions_by_mapid$response$result[[8]]$indicatorValues
submissions_by_mapid$response$result[[8]]$stakeholderApproval

# 0415 Jais map
#mapid <- "44137975" 
# is the same rural low population map with the jobs/pop indicators we've been using



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

# have to run this before the sh_freq table
reticulate::source_python('py/proc_ZH.py')
Carl_trials <- py$df2

# New: pick 50 most satisfied and 50 most unsatisfied for each stakeholder 

reticulate::source_python("py/extreme_case.py")
# mapid of those maps for each SH

most_satisfied = py$most_satisfied
most_unsatisfied = py$most_unsatisfied

# get luc change info based on those mapid

###
map_area <- py$Allocation$total_area
map_area

# Carl_trials <- read.csv(paste0(map_id,"/",map_id,".csv"))
# Carl_trials
# 
# setwd("~/Documents/lem-analysis-pipeline")
# saveRDS(Carl_trials_three_results, "Carl_trials_three_results.rds")
# saveRDS(Carl_trials, "Carl_trials.rds")
# saveRDS(mapid, "mapid.rds")
# saveRDS(map_area, "map_area.rds")
# saveRDS(most_satisfied, "most_satisfied.rds")
# saveRDS(most_unsatisfied, "most_unsatisfied.rds")

# rmd
Carl_trials_sh_freq <- as.data.frame(apply(Carl_trials[,-c(1:122)], 2, table)) 
# Carl_trials_sh_freq


# check luc change. check if Timber, Wetlands, and Conservation have zero rows
for (i in luc_list){
  print(i)
  luc_from_to_same = subset(luc_changes_df, from_luc == i & to_luc == i)
  print(head(luc_from_to_same,10))
}

changed_area_zero = subset(luc_changes_df, changed_area == 0)
changed_area_zero

# luc naming used in py/proc_ZH.py
luc_0 = "Commercial"
luc_1 = "Conservation"
luc_2 = "Cropland" 
luc_3 = "Industrial" 
luc_4 = "Limited Use"
luc_5 = "Pasture"
luc_6 = "Recreation"
luc_7 = "Residential HD" 
luc_8 = "Residential LD" 
luc_9 = "Timber" 
luc_10 = "Wetlands"

# everything below is same as in RMD

# sample 100 ----

# Random sample from the whole set: for each stakeholder, sample 100 map trials for satisfaction and 100 for unsatisfaction.

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

# check if there are any < 50 value
Carl_trials_sampled_sh_freq<- as.data.frame(apply(Carl_trials_sampled[,-c(1:122)], 2, table)) 
Carl_trials_sampled_sh_freq


rownames(Carl_trials_sampled) <- 1:nrow(Carl_trials_sampled)
names(Carl_trials_sampled)[2:122] <- paste0("V",seq(1:121))
# # should i turn luc_i_i (i=0:10) to Zero here. 
# Carl_trials_sampled[seq(2, length(Carl_trials_sampled_t), 12)] = 0

Carl_trials_sampled

# this was just trying to rearrange individual SH column Yes/No to a centralized Stakeholder column
ncol(Carl_trials_sampled)
Carl_trials_sampled$stakeholder <- rep(colnames(Carl_trials)[123:131], each=100)
Carl_trials_sampled$value <- rep(rep(c("Yes", "NO"), each=sample.size),times=9)
ncol(Carl_trials_sampled)
Carl_trials_sampled
View(Carl_trials_sampled)

# percentage
Carl_trials_sampled[,c(2:122)] <- Carl_trials_sampled[,c(2:122)]/map_area
head(Carl_trials_sampled,3)


Carl_trials_sampled <- Carl_trials_sampled[,-c(123:131)]
Carl_trials_sampled
# write.csv(Carl_trials_sampled, paste0(mapid,"/ori_sampled.csv"))
Carl_trials_sampled_t <- Carl_trials_sampled


Carl_trials_sampled_connection = Carl_trials_sampled[,c(2:122)]

for(i in (1:nrow(Carl_trials_sampled_connection))){
  Carl_trials_sampled_connection[i,] <- lapply(matrix(as.vector(Carl_trials_sampled[i,c(2:122)]), byrow=TRUE, nrow=11),c)
}

Carl_trials_sampled_t[,c(2:122)] <- Carl_trials_sampled_connection

Carl_trials_sampled_t[seq(2, length(Carl_trials_sampled_t), 12)] = 0
Carl_trials_sampled_t

# write.csv(Carl_trials_sampled_t, paste0(map_id,"/transpose_sampled.csv"))

##### self-connection test ####
# self_connection_test <- read_csv("self-connection-test.csv")
# 
# self_connection_test_codes <- c("c1", "c2", "c3", "c4")
# 
# unit.col = self_connection_test[,c("unit")]
# meta.col = self_connection_test[,c("meta")]
# 
# self_connection_test_dENA<- generate.dena.object.test (self_connection_test,
#                                                  as.data.frame(self_connection_test[,c("unit")]),
#                                                  as.data.frame(self_connection_test[,c("meta")]),
#                                                  self_connection_test_codes)
# self_connection_test_set <- directed_model(self_connection_test_dENA,
#                                            rotation_on='response',
#                                            optimize_on = 'response',
#                                            norm.by = rENA::fun_sphere_norm)
# 
# diag(as.matrix(self_connection_test_set$line.weights))
# 
# plot_(self_connection_test_set, 
#       title = "self connection test plot",
#       point_position_multiplier = 3,
#       node_size_multiplier = 0.4,
#       edge_size_multiplier = 0.8,
#       edge_arrow_saturation_multiplier = 2.0,
#       with_points = TRUE,
#       with_lines = FALSE,
#       show_mean = TRUE,
#       colors = c("#FFFFFF"),
#       edge_color = c("#0000FF"),
#       units_as_vectors = FALSE)
# 
# generate.dena.object.test <- function(self_connection_test, unit.col, meta.col, self_connection_test_codes){
#   output <- list()
#   f.units <- unit.col
#   f.units
#   ENA_UNIT <- rENA::merge_columns_c(f.units, cols = colnames(f.units));
#   f.raw <- self_connection_test
#   f.codes <- self_connection_test_codes
#   dena_data = directedENA:::ena.set.directed(f.raw, f.units, NA, f.codes)
#   output.meta.data <- meta.col
#   dena_data$meta.data <- data.table::as.data.table(cbind(ENA_UNIT, output.meta.data))
#   for( i in colnames(dena_data$meta.data) ) {
#     set(dena_data$meta.data, j = i, value = rENA::as.ena.metadata(dena_data$meta.data[[i]]))
#   }
#   code_length <- length(dena_data$rotation$codes);
#   dena_data$rotation$adjacency.key <- data.table::data.table(matrix(c(
#     rep(1:code_length, code_length),
#     rep(1:code_length, each = code_length)),
#     byrow = TRUE, nrow = 2
#   ))
#   
#   # browser()
#   # directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(TP_43[,which(!paste("V", 1:64, sep = "") %in% paste("V", c(1:8, seq(2, by = 8, length.out = 8)), sep = ""))]), "ena.connections")
#   directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(self_connection_test[,3:18]), "ena.connections")
#   dena_data$connection.counts <- data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
#   dena_data$connection.counts = rENA::as.ena.matrix(x = dena_data$connection.counts, "ena.connections")
#   
#   # browser()
#   for (i in which(!rENA::find_meta_cols(dena_data$connection.counts)))
#     set(dena_data$connection.counts, j = i, value = as.ena.co.occurrence(as.double(dena_data$connection.counts[[i]])))
#   
#   dena_data$model$row.connection.counts = data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
#   dena_data$model$row.connection.counts <- rENA::as.ena.matrix(dena_data$model$row.connection.counts, "row.connections")
#   
#   output = dena_data;
#   
#   return(output)
# }
# 
# 
# #### set.norm ####
# 
# unit.col = Carl_trials_sampled_t[,c("id")]
# meta.col = Carl_trials_sampled_t[,c("id", "stakeholder", "value")]
# luc_name_codes <- luc_list
# 
# # source("R/generate.dena.object.R")
# 
# # please don't hard code stuff in your function, Yuanru!!! so mad! 
# generate.dena.object <- function(Carl_trials_sampled_t, unit.col, meta.col, luc_name_codes){
#   output <- list()
#   f.units <- unit.col
#   f.units
#   ENA_UNIT <- rENA::merge_columns_c(f.units, cols = colnames(f.units));
#   f.raw <- Carl_trials_sampled_t
#   f.codes <- luc_name_codes
#   dena_data = directedENA:::ena.set.directed(f.raw, f.units, NA, f.codes)
#   output.meta.data <- meta.col
#   dena_data$meta.data <- data.table::as.data.table(cbind(ENA_UNIT, output.meta.data))
#   for( i in colnames(dena_data$meta.data) ) {
#     set(dena_data$meta.data, j = i, value = rENA::as.ena.metadata(dena_data$meta.data[[i]]))
#   }
#   code_length <- length(dena_data$rotation$codes);
#   dena_data$rotation$adjacency.key <- data.table::data.table(matrix(c(
#     rep(1:code_length, code_length),
#     rep(1:code_length, each = code_length)),
#     byrow = TRUE, nrow = 2
#   ))
#   
#   # browser()
#   # directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(TP_43[,which(!paste("V", 1:64, sep = "") %in% paste("V", c(1:8, seq(2, by = 8, length.out = 8)), sep = ""))]), "ena.connections")
#   directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(Carl_trials_sampled_t[,2:122]), "ena.connections")
#   dena_data$connection.counts <- data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
#   dena_data$connection.counts = rENA::as.ena.matrix(x = dena_data$connection.counts, "ena.connections")
#   
#   # browser()
#   for (i in which(!rENA::find_meta_cols(dena_data$connection.counts)))
#     set(dena_data$connection.counts, j = i, value = as.ena.co.occurrence(as.double(dena_data$connection.counts[[i]])))
#   
#   dena_data$model$row.connection.counts = data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
#   dena_data$model$row.connection.counts <- rENA::as.ena.matrix(dena_data$model$row.connection.counts, "row.connections")
#   
#   output = dena_data;
#   
#   return(output)
# }
# 
# Carl_trials_long_dENA <- generate.dena.object(Carl_trials_sampled_t,
#                                               as.data.frame(Carl_trials_sampled_t[,c("id")]),
#                                               Carl_trials_sampled_t[,c("id", "stakeholder", "value")],
#                                               luc_name_codes)
# 
# 
# head(as.matrix(Carl_trials_long_dENA$connection.counts))
# 
# colSums(as.matrix(set.norm$line.weights))
# # V1, V12, V23, V34... V121 should be 0 
# 
# set.norm <- directed_model(Carl_trials_long_dENA,
#                            rotation_on='response',
#                            optimize_on = 'response',
#                            center_individually = TRUE,
#                            norm.by = rENA::fun_sphere_norm)
# 
# correlations <- function(enaset, pts = NULL, cts = NULL, dims = c(1:2), direction = "response") {
#   if(is.null(pts) || is.null(cts)) {
#     rows <- enaset$points$ENA_DIRECTION %in% direction
#     pts <- enaset$points[rows, ]
#     cts <- enaset$model$centroids[, ]
#   }
#   
#   pComb = combn(nrow(pts), 2)
#   point1 = pComb[1,]
#   point2 = pComb[2,]
#   
#   points = as.matrix(pts)
#   centroids = as.matrix(cts)
#   svdDiff = matrix(points[point1, dims] - points[point2, dims], ncol=length(dims), nrow=length(point1))
#   optDiff = matrix(centroids[point1, dims] - centroids[point2, dims], ncol=length(dims), nrow=length(point1))
#   
#   corrs = as.data.frame(mapply(function(method) {
#     sapply(dims, function(dim) {
#       cor(as.numeric(svdDiff[,dim]), as.numeric(optDiff[,dim]), method=method)
#     });
#   }, c("pearson","spearman")))
#   
#   return(corrs);
# }
# 
# correlations(set.norm, dims = c(1:2), direction = "response")
# 
# set.norm$model$variance[1:5]
# 
# saveRDS(set.norm, "set.norm.RDS")
# 
# # plot 9 SH 
# stakeholder.name <- as.list(unique(Carl_trials_sampled_t$stakeholder))
# stakeholder.name
# 
# for(i in stakeholder.name){
#   print(i)
#   a <- (plot_(set.norm, 
#        title = paste0(i," satisfied"),
#        weights = colMeans(as.matrix(set.norm$line.weights[stakeholder == i & value == 'Yes' & ENA_DIRECTION == 'response'])), 
#        points = set.norm$points[stakeholder == i & value == 'Yes'],
#        sender_direction = 2,
#        node_direction = 1,
#        point_position_multiplier = 1,
#        node_size_multiplier = 0.2,
#        edge_size_multiplier = 0.8,
#        edge_arrow_saturation_multiplier = 1.5,
#        show_points = FALSE,
#        with_lines = FALSE,
#        show_mean = TRUE,
#        colors = c("#0000FF"), # points color 
#        edge_color = c("#0000FF"),
#        units_as_vectors = FALSE))
#   print(a)
# }
# 
# for(i in stakeholder.name){
#   print(i)
#   b <- (plot_(set.norm, 
#               title = paste0(i," unsatisfied"),
#               weights = colMeans(as.matrix(set.norm$line.weights[stakeholder == i & value == 'NO' & ENA_DIRECTION == 'response'])), 
#               points = set.norm$points[stakeholder == i & value == 'NO'],
#               point_position_multiplier = 1,
#               node_size_multiplier = 0.4,
#               edge_size_multiplier = 0.8,
#               edge_arrow_saturation_multiplier = 1.5,
#               show_points = FALSE,
#               with_lines = FALSE,
#               show_mean = TRUE,
#               colors = c("#FF0000"), # points color 
#               edge_color = c("#FF0000"),
#               units_as_vectors = FALSE))
#   print(b)
# }
# 
# for(i in stakeholder.name){
#   print(i)
#   c <- (plot_(set.norm, 
#               title = paste0(i," difference"),
#               weights = colMeans(as.matrix(set.norm$line.weights[stakeholder == i & value == 'Yes' & ENA_DIRECTION == 'response'])) - 
#                 colMeans(as.matrix(set.norm$line.weights[stakeholder == i & value == 'NO' & ENA_DIRECTION == 'response'])), 
#               points = list(set.norm$points[stakeholder == i & value == 'Yes'],
#                             set.norm$points[stakeholder == i & value == 'NO']),
#               point_position_multiplier = 1,
#               node_size_multiplier = 0.4,
#               edge_size_multiplier = 0.8,
#               edge_arrow_saturation_multiplier = 1.5,
#               show_points = FALSE,
#               with_lines = FALSE,
#               show_mean = TRUE,
#               colors = c("#0000FF", "#FF0000"), # points color
#               edge_color = c("#0000FF","#FF0000"),
#               units_as_vectors = FALSE))
#   print(c)
# }
# 
# 
# 
# #### previous  #### 
# for(skakeholder.name in skakeholder.names){
#   print(skakeholder.name)
#   set <- set.norm.rotate.response
#   stakeholder.satisfy <- paste0(skakeholder.name,"_satisfied")
#   stakeholder.satisfy
#   normalization.rotation.info <- "(norm, rotate on response)"
#   
#   to.plot.unstatisfied <- list(
#     "satisfied" = set$line.weights$stakeholder == stakeholder.satisfy & set$line.weights$value == "Yes",
#     "unsatisfied" = set$line.weights$stakeholder == stakeholder.satisfy & set$line.weights$value == "NO"
#   )
#   
#   orca(plot(set, 
#             units = to.plot.unstatisfied[1], 
#             multiplier = 200, 
#             multiplier_nodes = 20, 
#             with_points = FALSE, 
#             with_mean = TRUE, 
#             colors = "blue", 
#             node_size_dynamic = TRUE, 
#             title = paste0(skakeholder.name," satisfied",normalization.rotation.info), 
#             with_ci = FALSE), 
#        file=paste0(map_id,"/plots/",skakeholder.name,"_satisfied_transposed.jpeg"))
#   orca(plot(set, 
#             units = to.plot.unstatisfied[2], 
#             multiplier = 200, 
#             multiplier_nodes = 20, 
#             with_points = FALSE, 
#             with_mean = TRUE, 
#             colors = "red", 
#             node_size_dynamic = TRUE, 
#             title = paste0(skakeholder.name," unsatisfied",normalization.rotation.info), 
#             with_ci = FALSE), 
#        file=paste0(map_id,"/plots/",skakeholder.name,"_unsatisfied_transposed.jpeg"))
#   orca(plot(set, 
#             units = to.plot.unstatisfied, 
#             colors=c("blue","red"), 
#             multiplier = 200, 
#             multiplier_nodes = 20, 
#             with_points = FALSE, 
#             with_mean = TRUE,  
#             node_size_dynamic = TRUE, 
#             title = paste0(skakeholder.name," subtracted",normalization.rotation.info), 
#             with_ci = FALSE), 
#        file=paste0(map_id,"/plots/",skakeholder.name,"_subtracted_transposed.jpeg"))
# }
