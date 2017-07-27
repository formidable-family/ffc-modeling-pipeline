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
imputed_background <- readRDS(file.path("data", "imputed-fulldata-lasso.rds"))

# handling for issues with imputed data
# if the imputed data has no challengeID column, add one
if (!"challengeID" %in% colnames(imputed_background)) {
  challengeID <- data_frame(challengeID = 1:nrow(imputed_background))
  imputed_background <- bind_cols(challengeID, imputed_background)
}

# if the imputed data still has columns with NAs, get rid of those columns
na_check <- sapply(imputed_background, function(x) any(is.na(x)))
still_nas <- names(na_check[na_check])
imputed_background <- imputed_background %>% select(-one_of(still_nas))

# convert categorical variables to factors
categorical_vars <- read_lines("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/output/categorical.txt")
categorical_vars <- 
  categorical_vars[categorical_vars %in% colnames(imputed_background)]

d1 <- imputed_background %>% select(-one_of(categorical_vars))
d2 <- 
  imputed_background %>%
  select(one_of(categorical_vars)) %>%
  Map(as.factor, .)

imputed_background <- bind_cols(d1, d2)

source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/merge_train.R")
ffc <- merge_train(imputed_background, train)

# covariates ----
ffvars_scored <- 
  read_csv(file.path("variables", "ffvars_scored.csv")) %>%
  filter(!is.na(ffvar))

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

all_covariates <- rep(list(colnames(imputed_background)[-1]), 6)

covariates <- map(vars_data_list, "ffvar")

scores_experts <- map(vars_data_list, "experts")
scores_mturks <- map(vars_data_list, "mturks")

families <- as.list(c(rep("gaussian", 3), 
                      rep("binomial", 3)))

# without score information
prediction_list <- 
  Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
      outcome = outcomes, 
      covariates = covariates, 
      family = families)

# with score information
prediction_list2 <- 
  Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
      outcome = outcomes, 
      covariates = covariates, 
      scores = scores_experts,
      family = families)

# predictions ----
names(prediction_list) <- as.character(outcomes)
prediction <- 
  ffc %>% 
  select(challengeID) %>%
  bind_cols(prediction_list)

if (!dir.exists("predictions")) dir.create("predictions")

pred_path <- file.path("predictions", "test_prediction")
if (!dir.exists(pred_path)) dir.create(pred_path)

write_csv(prediction, file.path(pred_path, "prediction.csv"))

