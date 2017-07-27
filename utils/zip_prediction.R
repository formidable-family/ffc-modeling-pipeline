library(readr)

zip_prediction <- function(prediction, name) {
  if (!dir.exists("predictions")) dir.create("predictions")
  
  # write prediction to csv
  pred_path <- file.path("predictions", name)
  if (!dir.exists(pred_path)) dir.create(pred_path)
  write_csv(prediction, file.path(pred_path, "prediction.csv"))
  
  # copy narrative to prediction directory
  narrative <- file.path("narratives", name, "narrative.txt")
  if (file.exists(narrative)) {
    file.copy(narrative, pred_path)
  } else {
    warning("Please create a narrative.txt file for this prediction: ", name)
  }
  
  # copy code to prediction directory
  file.copy("run_lasso.R", pred_path)
  file.copy("models/lasso.R", pred_path)
  
  # cd into predictions directory is the best way to get the directory structure
  # that I want the zip file to have. -j parameter junks the whole directory
  # structure, -p (default) includes predictions/<name>/<files>
  setwd("predictions")
  zip(zipfile = name, 
      files = list.files(name, full.names = TRUE))
  setwd("..")
}
