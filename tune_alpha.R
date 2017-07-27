# notes ----
# run run_lasso.R to set up, through line 59

source("models/generate_test_indices.R")

set.seed(42)
gpa_test <- generate_test_indices(ffc, "gpa")
foldid <- generate_foldid(ffc, "gpa", gpa_test)
# test_fit <- lasso(ffc, "gpa", covariates$gpa, test_indices = gpa_test)

alphas <- seq(0, 1, .1)
test_alphas <- 
  lapply(alphas, function(x)  { 
    lasso(ffc, "gpa", covariates$gpa, test_indices = gpa_test, 
          alpha = x, foldid = foldid)
  })

gpa_alphas <- 
  data_frame(alpha = alphas,
             mse = map_dbl(test_alphas, "mse"), 
             test_mse = map_dbl(test_alphas, "test_mse"))

# using caret ----
library(caret)
gpa_setup <- setup_lasso(ffc, "gpa", covariates$gpa)
control <- trainControl(method = "repeatedcv", repeats = 3, verboseIter = TRUE)
egrid <- expand.grid(.alpha = 1:10 * .1, 
                     .lambda = 1:10 * .1)
gpa_caret <- train(x = gpa_setup$x, 
                   y = gpa_setup$y, 
                   method = "glmnet",
                   tuneGrid = egrid, 
                   trControl = control) 

grit_setup <- setup_lasso(ffc, "grit", covariates$grit)
grit_caret <- train(x = grit_setup$x, 
                    y = grit_setup$y, 
                    method = "glmnet",
                    tuneGrid = egrid, 
                    trControl = control) 
