library(glmnet)

lasso <- function(data, outcome, covariates, family = "gaussian", ...) {
  # build covariate matrix and response vector
  f <- as.formula(paste0(outcome, " ~ ", paste0(covariates, collapse = " + ")))
  d <- model.frame(f, data)
  x <- model.matrix(f, data = d)[, -1]
  y <- d[[outcome]]

  # fit lasso model
  # alpha = 1 by default
  # (alpha is the mixing parameter for elastic net, so 1 = lasso)
  model_fit <- cv.glmnet(x = x, y = y, family = family, ...)
  
  # predict responses for outcome
  # don't want to drop NAs here
  # https://stackoverflow.com/a/31949950
  x_pred <- 
    model.matrix(f, data = model.frame(~ ., data, na.action = na.pass))[, -1]
  pred <- predict(model_fit, newx = x_pred, s = "lambda.min", type = "response")
  
  # in-sample mean squared error
  mse <- mean((data[[outcome]] - pred)^2, na.rm = TRUE)
  print(mse)
  # could return pred + mse
  # list(pred = pred, mse = mse)
  
  pred
}