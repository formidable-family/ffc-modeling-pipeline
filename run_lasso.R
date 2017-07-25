library(tidyverse)
library(doParallel)
registerDoParallel(cores = parallel::detectCores(logical = FALSE))

# for more info on
# cv.glmnet with parallel = TRUE and doParallel package:
# https://stackoverflow.com/a/21710769
# https://stackoverflow.com/a/29001039

source("models/calculate_penalty_factors.R")
source("models/lasso.R")

# data ----

train <- read_csv(file.path("data", "train.csv"))
imputed_background <- readRDS(file.path("data", "<FILENAME>"))

source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/merge_train.R")
ffc <- merge_train(imputed_background, train)

# covariates ----
ffvars_scored <- read_csv(file.path("variables", "ffvars_scored.csv"))

gpa_vars <- ffvars_scored %>% filter(outcome == "gpa")
grit_vars <- ffvars_scored %>% filter(outcome == "grit")
materialHardship_vars <- ffvars_scored %>% filter(outcome == "material_hardship")
eviction_vars <- ffvars_scored %>% filter(outcome == "eviction")
layoff_vars <- ffvars_scored %>% filter(outcome == "layoff")
jobTraining_vars <- ffvars_scored %>% filter(outcome == "job_training")

# models ----
outcomes <- list("gpa", "grit", "materialHardship", 
                 "eviction", "layoff", "jobTraining")

vars_data_list <- list(gpa_vars, grit_vars, materialHardship_vars, 
                       eviction_vars, layoff_vars, jobTraining_vars)
names(vars_data_list) <- as.character(outcomes)

covariates <- map(vars_data_list, "ffvar")

scores_experts <- map(vars_data_list, "experts")
scores_mturks <- map(vars_data_list, "mturks")

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
