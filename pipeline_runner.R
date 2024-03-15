# author: Krirk Nirunwiroj, 2023
# For the best practice, you should run line by line and check the output and variables for any error that may occur.
# If you are confident with the codes, you may click "Source" to quickly generate the A, B, and C matrices for the desired mapid.
# In some cases, "R session aborted, fatal error" may occur. You should run line by line instead.

rm(list = ls())

# library("rstudioapi")
# setwd(dirname(getActiveDocumentContext()$path))

# please make sure your working directory is set to this file location
wd = getwd()

library(dplyr)
library(tidyverse)
library(rENA)
library(plotly)

# change it as appropriate
mapid = "20141264"
# mapid = "21078015"
# mapid = "57718789"
samplesize <- 10000

# generate important mapid JSON files: 
reticulate::source_python("py/db_wrangler.py") # for the small mapids, you may want to reduce batchSize for a faster runtime.

# generate submission result RDS file:
sub_result = submissions_by_mapid$response$result
sub_result_name = paste0(wd, "/data/", mapid, "a_sub_result_new.rds")
saveRDS(sub_result, sub_result_name)

# prepare data for ABC matrices generation:
reticulate::source_python("py/preAB_processor.py")

# ABC Matrices generator:
source("R/abc_matrix_generator.R")
# In the first run, there might be warning messages saying 'No such file or directory'. You can ignore that. The code just tried to clear the old version of abc matrices.

# if you want ONA graphs, please proceed to ONA_analysis.Rmd after run all the previous lines.