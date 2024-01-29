# author: Krirk Nirunwiroj, 2023
# For the best practice, you should run line by line and check the output and variables for any error that may occur.
# If you are certain with the codes, you may click "Source" to quickly generate the A, B, and C matrices for the desired mapid.
# In some cases, "R session aborted, fatal error" may occur. You should run line by line instead.

rm(list = ls())

library("rstudioapi")
setwd(dirname(getActiveDocumentContext()$path))

# please make sure your working directory is set to this file location
wd = getwd()

library(dplyr)
library(tidyverse)
library(rENA)
library(plotly)
library(jsonlite)
library(ona)
library(tma)
library(magrittr)
library(readr)
library(ggplot2)
library(ggrepel)
library(ggfortify)
library(data.table)
library(superheat)
library(rjson)
library(RColorBrewer)
library(randomcoloR)
library(rlist)
library(webshot)

generate.ona.object <- function(data, unit.col, meta.col, codes){
  output <- list()
  f.units <- unit.col
  ENA_UNIT <- rENA::merge_columns_c(f.units, cols = colnames(f.units));
  # ENA_UNIT <-  f.units
  f.raw <- data
  f.codes <- codes
  dena_data = directedENA:::ena.set.directed(f.raw, f.units, NA, f.codes)
  output.meta.data <- meta.col
  dena_data$meta.data <- data.table::as.data.table(cbind(ENA_UNIT, output.meta.data))
  for( i in colnames(dena_data$meta.data) ) {
    set(dena_data$meta.data, j = i, value = rENA::as.ena.metadata(dena_data$meta.data[[i]]))
  }
  code_length <- length(dena_data$rotation$codes);
  dena_data$rotation$adjacency.key <- data.table::data.table(matrix(c(
    rep(1:code_length, code_length),
    rep(1:code_length, each = code_length)),
    byrow = TRUE, nrow = 2
  ))
  directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(data[, grep("V", colnames(data))]), "ena.connections")
  # aren't these two the same thing 
  dena_data$connection.counts <- data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
  dena_data$connection.counts = rENA::as.ena.matrix(x = dena_data$connection.counts, "ena.connections")
  for (i in which(!rENA::find_meta_cols(dena_data$connection.counts)))
    set(dena_data$connection.counts, j = i, value = as.ena.co.occurrence(as.double(dena_data$connection.counts[[i]])))
  dena_data$model$row.connection.counts = data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
  dena_data$model$row.connection.counts <- rENA::as.ena.matrix(dena_data$model$row.connection.counts, "row.connections")
  output = dena_data;
  return(output)
}

ona_plot <- function(includeSub = TRUE){
  colors <- c("green", "blue", "brown", "purple", "yellow", "deeppink", "Tan", "Cyan", "orange")
  
  p <- ona:::plot.ena.directed.set(set) %>%
    units(
      points = set$points,
      points_color = "white",
      point_position_multiplier = point_position_multiplier,
      show_mean = FALSE,
      show_points = TRUE,
      with_ci = FALSE
    )
  
  for (i in 1:length(sh_name)) {
    tryCatch({
      p <- p %>%
        units(
          points = setA$points[SH == sh_name[i] & Satisfy == "Yes"],
          points_color = colors[i],
          point_position_multiplier = point_position_multiplier,
          show_mean = TRUE,
          show_points = FALSE,
          with_ci = TRUE
        )
    }, error = function(e) {
      cat("An error occurred:", conditionMessage(e), "\n")
      # If an error occurs, set with_ci = FALSE
      p <- p %>%
        units(
          points = setA$points[SH == sh_name[i] & Satisfy == "Yes"],
          points_color = colors[i],
          point_position_multiplier = point_position_multiplier,
          show_mean = TRUE,
          show_points = FALSE,
          with_ci = FALSE
        )
    })
  }
  
  p <- p %>%
    nodes(
      node_size_multiplier = 0.01,
      node_position_multiplier = node_position_multiplier,
      self_connection_color = "blue")
  if(includeSub) {
    j = 0
    k = 1
    prev = ""
    for (i in 1:length(submission_name)) {
      if (submission_name[i] %in% selected_users) {
        if (submission_name[i] != prev) {
          j <- j+1
          prev <- submission_name[i]
          k <- 1
        }
        p <- p %>%
          add_annotations(
            x = set$points[ENA_DIRECTION == "response"]$SVD1[i],
            y = set$points[ENA_DIRECTION == "response"]$SVD2[i],
            text = paste0(substring(submission_name[i], 1, 2), "[", k, "]"),
            font = list(color = colors_selected[j]),
            showarrow = FALSE
          )
        k <- k+1
      }
    }
  }
  p <- p %>%
    plotly::layout(showlegend = TRUE, legend = list(x = 100, y = 0.9)) %>% 
    style(name = "point", traces = c(2)) %>% 
    style(name = sh_info[1], traces = c(3)) %>% 
    style(name = sh_info[2], traces = c(4)) %>% 
    style(name = sh_info[3], traces = c(5)) %>% 
    style(name = sh_info[4], traces = c(6)) %>% 
    style(name = sh_info[5], traces = c(7)) %>% 
    style(name = sh_info[6], traces = c(8)) %>% 
    style(name = sh_info[7], traces = c(9)) %>% 
    style(name = sh_info[8], traces = c(10)) %>% 
    style(name = sh_info[9], traces = c(11))
  p <- p %>% layout(xaxis = list(autorange = TRUE),
                    yaxis = list(autorange = TRUE))
  # plotly::export(file = "plots/test.png")
  return(p)
}

mapid = "30176134" # change it as appropriate
samplesize <- 10000

init <- jsonlite::fromJSON(paste0("data/", mapid, "_init_map.json"))
reps <- jsonlite::fromJSON(paste0("data/", mapid, "_reps.json"))

indicators <- unique(reps$Indicator)

thresholds_r <- c(0,0,0,0,0)
mul1 <- sort(unique(init$lucs$multipliers[[which(names(init$lucs$multipliers) == indicators[1])]]))
mul2 <- sort(unique(init$lucs$multipliers[[which(names(init$lucs$multipliers) == indicators[2])]]))
mul3 <- sort(unique(init$lucs$multipliers[[which(names(init$lucs$multipliers) == indicators[3])]]))
mul4 <- sort(unique(init$lucs$multipliers[[which(names(init$lucs$multipliers) == indicators[4])]]))
mul5 <- sort(unique(init$lucs$multipliers[[which(names(init$lucs$multipliers) == indicators[5])]]))

for (i1 in 1:(length(mul1)-1)) {
  for (i2 in 1:(length(mul2)-1)) {
    for (i3 in 1:(length(mul3)-1)) {
      for (i4 in 1:(length(mul4)-1)) {
        for (i5 in 1:(length(mul5)-1)) {
          thresholds_r[1] <- mul1[i1]
          thresholds_r[2] <- mul2[i2]
          thresholds_r[3] <- mul3[i3]
          thresholds_r[4] <- mul4[i4]
          thresholds_r[5] <- mul5[i5]
          reticulate::source_python("py/preABC_generator_hand.py")
          source("R/abc_matrix_generator.R")
          
          #ONA
          A_matrix = read_csv(paste0(wd, "/data/", mapid, "_a_matrix.csv"))
          B_matrix = read_csv(paste0(wd, "/data/", mapid, "_b_matrix.csv"))
          C_matrix = read.csv(paste0(wd, "/data/", mapid, "_c_matrix.csv"))
          sh_info = read.csv(paste0(wd, "/data/", "LEM text - Stakeholders.csv"))
          A = jsonlite::read_json(paste0(wd, "/data/", mapid, ".json"))
          reps = jsonlite::read_json(paste0(wd, "/data/", mapid, "_reps.json"))
          sub_result = readRDS(paste0(wd, "/data/", mapid, "a_sub_result_new.rds")) #record satisfy level
          submission_name = C_matrix$user_name
          submission_order = c()
          sub_approval_count = c()
          for (i in 1:length(sub_result)){
            submission_order = append(submission_order, sub_result[[i]]$userKey)
            sub_approval_count = append(sub_approval_count, sub_result[[i]]$approvalCount)
          }
          sub_approval_count = sub_approval_count/9
          sh_name = A_matrix %>%
            select(c(Name)) %>%
            unique() %>%
            pull()
          sh_info = sh_info %>% 
            filter(Name %in% sh_name) %>% 
            arrange(match(Name, sh_name)) %>% 
            unite("SHinfo", Name:Direction, remove = TRUE) %>% 
            pull()
          A_matrix_2 <- A_matrix
          B_matrix_2 <- B_matrix
          C_matrix_2 <- C_matrix
          for (i in 1:11) {
            A_luc1x = which(names(A_matrix_2)==paste0("luc_", 1, "_", i-1))
            A_luc4x = which(names(A_matrix_2)==paste0("luc_", 4, "_", i-1))
            B_luc1x = which(names(B_matrix_2)==paste0("luc_", 1, "_", i-1))
            B_luc4x = which(names(B_matrix_2)==paste0("luc_", 4, "_", i-1))
            C_luc1x = which(names(C_matrix_2)==paste0("luc_", 1, "_", i-1))
            C_luc4x = which(names(C_matrix_2)==paste0("luc_", 4, "_", i-1))
            A_matrix_2[[A_luc1x]] <- A_matrix_2[[A_luc1x]] + A_matrix_2[[A_luc4x]]
            B_matrix_2[[B_luc1x]] <- B_matrix_2[[B_luc1x]] + B_matrix_2[[B_luc4x]]
            C_matrix_2[[C_luc1x]] <- C_matrix_2[[C_luc1x]] + C_matrix_2[[C_luc4x]]
          }
          for (i in 1:11) {
            A_lucx1 = which(names(A_matrix_2)==paste0("luc_", i-1, "_", 1))
            A_lucx4 = which(names(A_matrix_2)==paste0("luc_", i-1, "_", 4))
            B_lucx1 = which(names(B_matrix_2)==paste0("luc_", i-1, "_", 1))
            B_lucx4 = which(names(B_matrix_2)==paste0("luc_", i-1, "_", 4))
            C_lucx1 = which(names(C_matrix_2)==paste0("luc_", i-1, "_", 1))
            C_lucx4 = which(names(C_matrix_2)==paste0("luc_", i-1, "_", 4))
            A_matrix_2[[A_lucx1]] <- A_matrix_2[[A_lucx1]] + A_matrix_2[[A_lucx4]]
            B_matrix_2[[B_lucx1]] <- B_matrix_2[[B_lucx1]] + B_matrix_2[[B_lucx4]]
            C_matrix_2[[C_lucx1]] <- C_matrix_2[[C_lucx1]] + C_matrix_2[[C_lucx4]]
          }
          for (i in 1:11) {
            A_lucxx = which(names(A_matrix_2)==paste0("luc_", i-1, "_", i-1))
            B_lucxx = which(names(B_matrix_2)==paste0("luc_", i-1, "_", i-1))
            C_lucxx = which(names(C_matrix_2)==paste0("luc_", i-1, "_", i-1))
            A_matrix_2[[A_lucxx]] = 0
            B_matrix_2[[B_lucxx]] = 0
            C_matrix_2[[C_lucxx]] = 0
          }
          
          A_matrix_2 <- A_matrix_2 %>% select(-c(luc_4_0, luc_4_1, luc_4_2, luc_4_3, luc_4_4, 
                                                 luc_4_5, luc_4_6, luc_4_7, luc_4_8, luc_4_9, luc_4_10,
                                                 luc_0_4, luc_1_4, luc_2_4, luc_3_4, luc_4_4,
                                                 luc_5_4, luc_6_4, luc_7_4, luc_8_4, luc_9_4, luc_10_4))
          B_matrix_2 <- B_matrix_2 %>% select(-c(luc_4_0, luc_4_1, luc_4_2, luc_4_3, luc_4_4, 
                                                 luc_4_5, luc_4_6, luc_4_7, luc_4_8, luc_4_9, luc_4_10,
                                                 luc_0_4, luc_1_4, luc_2_4, luc_3_4, luc_4_4,
                                                 luc_5_4, luc_6_4, luc_7_4, luc_8_4, luc_9_4, luc_10_4))
          C_matrix_2 <- C_matrix_2 %>% select(-c(luc_4_0, luc_4_1, luc_4_2, luc_4_3, luc_4_4, 
                                                 luc_4_5, luc_4_6, luc_4_7, luc_4_8, luc_4_9, luc_4_10,
                                                 luc_0_4, luc_1_4, luc_2_4, luc_3_4, luc_4_4,
                                                 luc_5_4, luc_6_4, luc_7_4, luc_8_4, luc_9_4, luc_10_4))
          colnames(A_matrix_2)[2] = "SH"
          A_matrix_2 <- A_matrix_2 %>%
            select(-c(...1)) %>% 
            add_column(user_name = "NA", .before = "luc_0_0") %>%
            add_column(submission = "NA",.before = "luc_0_0") %>%
            add_column(index = 1:nrow(A_matrix), .before = "SH")
          colnames(B_matrix_2)[2] = "SH"
          B_matrix_2 <- B_matrix_2 %>%
            select(-c(...1)) %>% 
            add_column(user_name = "NA", .before = "luc_0_0") %>%
            add_column(submission = "NA",.before = "luc_0_0") %>%
            add_column(index = 1:nrow(B_matrix), .before = "SH")
          C_matrix_2 <- C_matrix_2 %>%
            add_column(index = 1:nrow(C_matrix_2), .before = "user_name") %>%
            add_column(Name = "NA", .before = "user_name") %>%
            add_column(Satisfy = "NA",.before = "user_name") %>%
            add_column(N = "NA", .before = "user_name")
          df <- C_matrix_2
          
          names(df)[7:106] <- paste0("V",seq(1:100))
          df$mapid = mapid
          
          # 2. accum
          accumC <- generate.ona.object(
            df,
            unit.col = df[,1:7],
            meta.col = df[,1:7],
            codes = as.vector(
              c("Commercial",
                "Conservation_lu",
                # "Conservation",
                "Cropland",
                "Industrial",
                # "Limited Use",
                "Pasture",
                "Recreation",
                "Residential HD",
                "Residential LD",
                "Timber",
                "Wetlands")))
          
          # 3. model
          setC <- model(accumC)

          df1 <- A_matrix_2
          # df <- B_matrix
          # df <- C_matrix
          
          names(df1)[7:106] <- paste0("V",seq(1:100))
          df1$mapid = mapid
          
          # 2. accum
          accumA <- generate.ona.object(
            df1,
            unit.col = df1[,1:7],
            meta.col = df1[,1:7],
            codes = as.vector(
              c("Commercial",
                "Conservation_lu",
                # "Conservation",
                "Cropland",
                "Industrial",
                # "Limited Use",
                "Pasture",
                "Recreation",
                "Residential HD",
                "Residential LD",
                "Timber",
                "Wetlands")))
          
          # 3. model
          setA <- model(accumA)
          
          set=model(accumC, rotation.set = setA$rotation)
          
          node_size_multiplier = 0.2
          node_position_multiplier = 1.0
          edge_size_multiplier = 0.2
          point_position_multiplier = 1.0
          edge_arrow_saturation_multiplier = 1.0
          
          A = setA$points[ENA_DIRECTION== 'response']
          user_names <- unique(C_matrix$user_name)
          n <- length(user_names)
          colors_selected <- distinctColorPalette(n)
          selected_users <- user_names[c(2,3,4,6)] # for 3017613
          ona_plot()
          plotly::export(file = paste0("plots/", mapid, "/plot_", i1, i2, i3, i4, i5,".png"))
      
        }
      }
    }
  }
}