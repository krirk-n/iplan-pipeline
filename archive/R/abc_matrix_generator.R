library(readr)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(ggrepel)
library(ggfortify)
library(data.table)
library(superheat)
library(rlist)

# a and b matrix generating function
a_b_matrix_data_processing = function(mapid, start_idx = 4, end_idx = 124){
  data = read.csv(paste0("new_final_result_", mapid,".csv",sep = ""))
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
  write.csv(data_1, file = filename_a_matrix)
  write.csv(all_mean, file = filename_b_matrix)
  return(data_1)
}

# c matrix generating helper function
c_matrix_data_processing_helper = function(mapid, submission_data){
  base_data = jsonlite::read_json(paste0(mapid, ".json", sep = ""))
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
  df_sub_data = data.frame(matrix(ncol = length(submission_data), nrow = 200))
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
  
  #create data frame with 1rows and 121 columns
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
  
  
  filename_c_matrix = paste0(mapid, "_c_matrix.csv")
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
c_matrix_data_processing = function(mapid, ordered = TRUE, submission_data = readRDS(paste0(mapid, "a_sub_result_new.rds", sep = ""))){
  if (ordered == TRUE){
    c_matrix_data_processing_helper(mapid, submission_data)
  }
  else{
    user_keys <- character()
    for (i in 1:length(submission_data)){
      user_keys <- append(user_keys, submission_data[[i]]$userKey)
    }
    unique_user_keys <- unique(user_keys)
    for (i in 1:length(unique_user_keys)){
      partial_data <- list.filter(submission_data, userKey == unique_user_keys[i])
      c_matrix_data_processing_helper(mapid, partial_data)
    }
  }
}

a_b_matrix_data_processing(mapid)
c_matrix_data_processing(mapid = mapid, ordered = FALSE) # change as appropriate
