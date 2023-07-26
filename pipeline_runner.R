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

mapid = "23917296" # change it as appropriate
samplesize <- 10000

# generate important mapid JSON files: 
reticulate::source_python("py/json_generator.py")

# generate submission result RDS file:
sub_result = submissions_by_mapid$response$result
sub_result_name = paste0(wd, "/data/", mapid, "a_sub_result_new.rds")
saveRDS(sub_result, sub_result_name)

# prepare data for ABC matrices generation:
reticulate::source_python("py/preABC_generator.py")

# ABc Matrices generator:
# Disclaimer: if you want to re-generate the C matrix, make sure to remove the current C matrix file before re-run the code
# since we are using appending method.
source("R/abc_matrix_generator.R")

# if you want ONA graphs, please proceed to ONA_analysis.Rmd after run all the previous lines.