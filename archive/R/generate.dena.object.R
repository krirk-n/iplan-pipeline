library(directedENA)
library(rENA)

TP_43 <- read.csv("~/Documents/map/MAP analysis/TP_43.csv")
View(TP_43)

rs_codes <- as.vector(c("BEGIN",
                        "END",
                        "Client.and.Consultant.Requests",
                        "Data",
                        "Technical.Constraints",
                        "Performance.Parameters",
                        "Design.Reasoning",
                        "Collaboration"))

unit.col <- TP_43[,c("UserName","Condition")]
meta.col <- TP_43[,c("Condition")]


generate.dena.object <- function(TP_43, unit.col, meta.col, rs_codes){
  # browser()
  output <- list()
  f.units <- unit.col
  f.units
  ENA_UNIT <- rENA::merge_columns_c(f.units, cols = colnames(f.units));
  f.raw <- TP_43
  f.codes <- rs_codes
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
  
  # browser()
  # directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(TP_43[,which(!paste("V", 1:64, sep = "") %in% paste("V", c(1:8, seq(2, by = 8, length.out = 8)), sep = ""))]), "ena.connections")
  directed.adjacency.vectors <- as.ena.matrix(data.table::as.data.table(TP_43[,3:66]), "ena.connections")
  dena_data$connection.counts <- data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
  dena_data$connection.counts = rENA::as.ena.matrix(x = dena_data$connection.counts, "ena.connections")
  
  # browser()
  for (i in which(!rENA::find_meta_cols(dena_data$connection.counts)))
    set(dena_data$connection.counts, j = i, value = as.ena.co.occurrence(as.double(dena_data$connection.counts[[i]])))
  
  dena_data$model$row.connection.counts = data.table::as.data.table(cbind(dena_data$meta.data, directed.adjacency.vectors))
  dena_data$model$row.connection.counts <- rENA::as.ena.matrix(dena_data$model$row.connection.counts, "row.connections")
  
  output = dena_data;
  
  return(output)
}

TPdENA <- generate.dena.object(TP_43,
                               as.data.frame(TP_43[,c("UserName","Condition")]),
                               as.data.frame(TP_43[,c("Condition")]),
                               rs_codes)


set <- directed_model(
  TPdENA,
  rotation_on = "ground",
  norm.by = rENA::fun_sphere_norm)


plot(set,
     multiplier_edges = 100,
     multiplier_nodes = 100,
     with_points = FALSE)
