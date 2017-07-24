library(tidyverse)
library(doParallel)
registerDoParallel(cores = parallel::detectCores(logical = FALSE))

# for more info on
# cv.glmnet with parallel = TRUE and doParallel package:
# https://stackoverflow.com/a/21710769
# https://stackoverflow.com/a/29001039

source("models/lasso.R")

# data ----

train <- read_csv(file.path("data", "train.csv"))
imputed_background <- readRDS(file.path("data", "<FILENAME>"))

source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/merge_train.R")
ffc <- merge_train(imputed_background, train)

# covariates ----

gpa_vars <- read_csv(file.path("variables", "<FILENAME>"))
grit_vars <- read_csv(file.path("variables", "<FILENAME>"))
materialHardship_vars <- read_csv(file.path("variables", "<FILENAME>"))
eviction_vars <- read_csv(file.path("variables", "<FILENAME>"))
layoff_vars <- read_csv(file.path("variables", "<FILENAME>"))
jobTraining_vars <- read_csv(file.path("variables", "<FILENAME>"))

# models ----

outcomes <- list("gpa", "grit", "materialHardship", 
                 "eviction", "layoff", "jobTraining")

covariates <- list(gpa_vars, grit_vars, materialHardship_vars, 
                   eviction_vars, layoff_vars, jobTraining_vars)

families <- as.list(c(rep("gaussian", 3), 
                      rep("binomial", 3)))

prediction_list <- 
  Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
      outcome = outcomes, 
      covariates = covariates, 
      family = families)

names(prediction_list) <- as.character(outcomes)
prediction <- 
  train %>% 
  select(challengeID) %>%
  bind_cols(prediction_list)
