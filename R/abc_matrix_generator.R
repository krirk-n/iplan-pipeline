# author: Krirk Nirunwiroj, 2023
# Disclaimer: if you want to re-generate the C matrix, make sure to remove the current C matrix file before re-run the code
# since we are using appending method it may cause unwanted errors.
library(progress)
library(readr)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggrepel)
library(ggfortify)
library(data.table)
library(superheat)
library(rlist)

# Functions:

# a and b matrix generating function
a_b_matrix_data_processing = function(mapid, start_idx = 4, end_idx = 124){
  data = read.csv(paste0(wd, "/data/new_final_result_", mapid,".csv"), check.names = FALSE)
  data = handle_missing_luc(data)
  data_1 = separate(data, index, into = c("Name", "Satisfy", "N"))
  data_1$N = as.numeric(data_1$N)
  luc_idx_reverse = c()
  luc_idx = c()
  luc_idx_reverse = append(luc_idx_reverse, c("Name", "Satisfy", "N"))
  luc_idx = append(luc_idx, c("Name", "Satisfy", "N"))
  for (i in 0:10){
    for (j in 0:10){
      v = paste("luc_", i, "_", j, sep = "")
      v1 = paste("luc_", j, "_", i, sep = "")
      luc_idx_reverse = append(luc_idx_reverse, v)
      luc_idx = append(luc_idx, v1)
    }
  }
  colnames(data_1) = luc_idx_reverse
  data_1 = data_1[,luc_idx]
  yes_mean = data_1 %>% 
    filter(Satisfy == "Yes") %>% 
    group_by(Name, Satisfy) %>% 
    summarise_at(vars(luc_0_0:luc_10_10), mean)
  no_mean = data_1 %>% 
    filter(Satisfy == "No") %>% 
    group_by(Name, Satisfy) %>% 
    summarise_at(vars(luc_0_0:luc_10_10), mean)
  yes_mean$X = seq.int(nrow(yes_mean))
  no_mean$X = seq.int(nrow(no_mean))
  all_mean = rbind(yes_mean, no_mean)
  all_mean = all_mean %>% 
    relocate(X, .before = luc_0_0)
  filename_a_matrix = paste0(mapid, "_a_matrix.csv")
  filename_b_matrix = paste0(mapid, "_b_matrix.csv")
  write.csv(data_1, file = paste0(wd, "/data/", filename_a_matrix))
  write.csv(all_mean, file = paste0(wd, "/data/", filename_b_matrix))
  return(data_1)
}

handle_missing_luc = function(data){
  
  # Vector of desired column names in the specific order
  desired_columns <- c("index",
    "20_20", "20_31", "20_50", "20_21", "20_30", "20_60", "20_22", "20_23", "20_24", "20_40", "20_10",
    "31_20", "31_31", "31_50", "31_21", "31_30", "31_60", "31_22", "31_23", "31_24", "31_40", "31_10",
    "50_20", "50_31", "50_50", "50_21", "50_30", "50_60", "50_22", "50_23", "50_24", "50_40", "50_10",
    "21_20", "21_31", "21_50", "21_21", "21_30", "21_60", "21_22", "21_23", "21_24", "21_40", "21_10",
    "30_20", "30_31", "30_50", "30_21", "30_30", "30_60", "30_22", "30_23", "30_24", "30_40", "30_10",
    "60_20", "60_31", "60_50", "60_21", "60_30", "60_60", "60_22", "60_23", "60_24", "60_40", "60_10",
    "22_20", "22_31", "22_50", "22_21", "22_30", "22_60", "22_22", "22_23", "22_24", "22_40", "22_10",
    "23_20", "23_31", "23_50", "23_21", "23_30", "23_60", "23_22", "23_23", "23_24", "23_40", "23_10",
    "24_20", "24_31", "24_50", "24_21", "24_30", "24_60", "24_22", "24_23", "24_24", "24_40", "24_10",
    "40_20", "40_31", "40_50", "40_21", "40_30", "40_60", "40_22", "40_23", "40_24", "40_40", "40_10",
    "10_20", "10_31", "10_50", "10_21", "10_30", "10_60", "10_22", "10_23", "10_24", "10_40", "10_10"
  )

  # Iterate over each desired column
  for (col in desired_columns[2:(length(desired_columns)-1)]) {
    if (!col %in% colnames(data)) {
      # If the column does not exist, create it with all values set to 0
      data[[col]] <- 0
    }
  }
  
  # Reorder the dataframe columns to match the desired order
  data <- data[, desired_columns]
  return(data)
}

# c matrix generating helper function
c_matrix_data_processing_helper = function(mapid, submission_data, base_data){
  total_submission = length(submission_data)
  base_luc_vec = c()
  base_area_vec = c()
  for (i in 1:length(base_data$parcels)){
    area = base_data$parcels[[i]]$properties$Area
    lucs = base_data$parcels[[i]]$properties$LUC
    base_area_vec = append(base_area_vec, area)
    base_luc_vec = append(base_luc_vec, lucs)
  }
  base_area_vec_proportion = base_area_vec/base_data$area
  submission_luc_vec_name_vec = c()
  for (i in 1:length(submission_data)){
    submission_luc_vec_name = paste0("submitted",sep = "_", i)
    submission_luc_vec_name_vec = append(submission_luc_vec_name_vec, submission_luc_vec_name)
  }
  df_sub_data = data.frame(matrix(ncol = length(submission_data), nrow = length(base_data$parcels)))
  colnames(df_sub_data) = submission_luc_vec_name_vec
  for (i in 1:length(submission_data)){
    df_sub_data[i] = submission_data[[i]]$lucs
  }
  df_sub_data["area"] = base_area_vec_proportion
  df_sub_data["base"] = base_luc_vec
  df_sub_data = df_sub_data %>% 
    mutate_all(as.character) 
  df_sub_data$area = as.numeric(df_sub_data$area)
  luc_vec = c("luc_0", "luc_1","luc_2","luc_3","luc_4","luc_5","luc_6","luc_7","luc_8","luc_9","luc_10")
  luc_original = c("20", "31", "50", "21", "30", "60", "22", "23", "24", "40", "10")
  for (i in 1:nrow(df_sub_data)){
    for (j in 1:ncol(df_sub_data)){
      for (f in seq(length(luc_vec))){
        if (df_sub_data[i,j] == luc_original[f]){
          df_sub_data[i,j] = luc_vec[f]
        }
      }
    }
  }
  luc_idx_reverse = c()
  luc_idx = c()
  for (i in 0:10){
    for (j in 0:10){
      v = paste("luc_", i, "_", j, sep = "")
      v1 = paste("luc_", j, "_", i, sep = "")
      luc_idx_reverse = append(luc_idx_reverse, v)
      luc_idx = append(luc_idx, v1)
    }
  }
  
  col_name = luc_idx_reverse
  
  #create data frame with 121 columns
  merged_data = data.frame(matrix(ncol = 121, nrow = length(submission_data)))
  
  #provide column names
  colnames(merged_data) = col_name
  
  merged_data[is.na(merged_data)] = 0
  merged_data = merged_data %>%
    rename(luc_0_A = luc_0_10,
           luc_1_A = luc_1_10,
           luc_2_A = luc_2_10,
           luc_3_A = luc_3_10,
           luc_4_A = luc_4_10,
           luc_5_A = luc_5_10,
           luc_6_A = luc_6_10,
           luc_7_A = luc_7_10,
           luc_8_A = luc_8_10,
           luc_9_A = luc_9_10,
           luc_A_A = luc_10_10,
           luc_A_0 = luc_10_0,
           luc_A_1 = luc_10_1, 
           luc_A_2 = luc_10_2, 
           luc_A_3 = luc_10_3, 
           luc_A_4 = luc_10_4, 
           luc_A_5 = luc_10_5, 
           luc_A_6 = luc_10_6, 
           luc_A_7 = luc_10_7,
           luc_A_8 = luc_10_8,
           luc_A_9 = luc_10_9)
  
  df_sub_data[df_sub_data == "luc_10"] <- "luc_A"
  
  for(i in 1:total_submission){ # n_sumbit is also equal to nrow(base_submitted)
    base = df_sub_data$base# 200 vector
    submitted = df_sub_data[[i]] # 200 vector
    for (j in 1:length(submitted)){ # 200 iteration
      for (f in 1:ncol(merged_data)){ #121 iteration
        if (substring(colnames(merged_data)[f],5,5) == substring(base[j],5,5)){
          if (substring(colnames(merged_data)[f],7,7) == substring(submitted[j],5,5)){
            merged_data[i,colnames(merged_data)[f]] = merged_data[i,colnames(merged_data)[f]] + df_sub_data[j,"area"]
          }
        }
      }
    }
  }
  
  submission_userkey = c()
  n_submission = c()
  for (i in 1:total_submission){
    submission_userkey = append(submission_data[[i]]$userKey, submission_userkey)
    n_sub = paste0("submission_", i, sep = "")
    n_submission = append(n_sub, n_submission)
  }
  colnames(merged_data) = luc_idx_reverse
  merged_data = merged_data[, luc_idx]
  
  merged_data$user_name = rev(submission_userkey)
  merged_data$submission = rev(n_submission)
  merged_data = merged_data %>% 
    relocate(user_name, .before = luc_0_0) %>% 
    relocate(submission, .after = user_name)
  
  
  filename_c_matrix = paste0(wd, "/data/", mapid, "_c_matrix.csv")
  # write.csv(merged_data, file = filename_c_matrix)
  # Check if the CSV file exists
  if (file.exists(filename_c_matrix)) {
    # Check if the file is empty (contains only the header)
    if (file.info(filename_c_matrix)$size > 0) {
      # Append rows to the existing CSV file without including column names
      merged_data %>% write_csv(filename_c_matrix, append = TRUE, col_names = FALSE)
    } else {
      # Write the data along with column names to the existing CSV file
      merged_data %>% write_csv(filename_c_matrix)
    }
    cat("Data appended to the existing CSV file:", filename_c_matrix, "\n")
  } else {
    # Create a new CSV file
    merged_data %>% write_csv(filename_c_matrix)
    cat("New CSV file created:", filename_c_matrix, "\n")
  }
  return(read_csv(filename_c_matrix))
}

# c matrix generating function
c_matrix_data_processing = function(mapid, ordered = FALSE, submission_data = readRDS(paste0(wd, "/data/", mapid, "a_sub_result_new.rds"))){
  base_data = jsonlite::read_json(paste0(wd, "/data/", mapid, "_init_map.json", sep = ""))
  if (ordered == TRUE){
    c_matrix_data_processing_helper(mapid, submission_data, base_data)
  }
  else{
    user_keys <- character()
    for (i in 1:length(submission_data)){
      user_keys <- append(user_keys, submission_data[[i]]$userKey)
    }
    unique_user_keys <- unique(user_keys)
    pb <- progress_bar$new(total = length(unique_user_keys))
    for (i in 1:length(unique_user_keys)){
      partial_data <- list.filter(submission_data, userKey == unique_user_keys[i])
      c_matrix_data_processing_helper(mapid, partial_data, base_data)
      pb$tick()
    }
  }
}

# Main:

# remove the existing ABC matrices before generate a new set of them to avoid conflicts
filename_a_matrix = paste0(mapid, "_a_matrix.csv")
filename_b_matrix = paste0(mapid, "_b_matrix.csv")
file.remove(paste0(wd, "/data/", filename_a_matrix))
file.remove(paste0(wd, "/data/", filename_b_matrix))
a_b_matrix_data_processing(mapid)

filename_c_matrix = paste0(mapid, "_c_matrix.csv")
file.remove(paste0(wd, "/data/", filename_c_matrix))
c_matrix_data_processing(mapid = mapid, ordered = FALSE) # change as appropriate
