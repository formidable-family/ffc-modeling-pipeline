library(glmnet)

lasso <- function(data, outcome, covariates, 
                  scores = NULL, 
                  family = "gaussian", ...) {
  
  # validation of input
  if (!is.null(scores)) {
    # only use scores for covariates that are in the provided data
    scores <- scores[which(covariates %in% colnames(data))]
  }
  # only use covariates that are in the provided data
  covariates <- covariates[covariates %in% colnames(data)]
  
  # build covariate matrix and response vector
  f <- as.formula(paste0(outcome, " ~ ", paste0(covariates, collapse = " + ")))
  d <- model.frame(f, data)
  x <- model.matrix(f, data = d)[, -1]
  y <- d[[outcome]]
  
  # if scores are provided, convert to penalties for penalty.factor
  # else use default penalty.factor of 1 for all covariates
  penalties <- 
    if (!is.null(scores)) {
      calculate_penalty_factors(colnames(x), covariates, scores)
    } else {
      rep(1, length(colnames(x)))
    }

  # fit lasso model
  # alpha = 1 by default
  # (alpha is the mixing parameter for elastic net, so 1 = lasso)
  model_fit <- 
    cv.glmnet(x = x, y = y, 
              family = family, 
              type.measure = "mse", 
              penalty.factor = penalties, 
              ...)
  
  # predict responses for outcome
  # don't want to drop NAs here
  # https://stackoverflow.com/a/31949950
  x_pred <- 
    model.matrix(f, data = model.frame(~ ., data, na.action = na.pass))[, -1]
  pred <- predict(model_fit, newx = x_pred, s = "lambda.min", type = "response")
  
  # in-sample mean squared error
  mse <- mean((data[[outcome]] - pred)^2, na.rm = TRUE)
  print(paste0("in-sample mse for ", outcome, ": ", 
               formatC(mse, digits = 5, format = "f")))
  # could return pred + mse + model
  # list(pred = pred, mse = mse, model = model_fit)
  
  # pred
  list(pred = pred, mse = mse, model = model_fit, formula = f)
}
