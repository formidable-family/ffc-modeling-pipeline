# Humans in the loop: an approach to the Fragile Families Challenge

This is an end-to-end pipeline for running different models on Fragile Families Challenge data and producing predictions.

This repository depends on variable selection from [collective_wisdom](https://github.com/formidable-family/collective_wisdom), variable categorization from [ffc-data-processing](https://github.com/ccgilroy/ffc-data-processing), and missing-data imputation from [FFCRegressionImputation](https://github.com/annafil/FFCRegressionImputation). It requires the training and outcome data provided by the Fragile Families Challenge, and must be evaluated on the held-out test data kept by the Challenge sponsors. The resulting out-of-sample mean squared errors are used to evaluated and compare model performance, in figures and tables at [ffc-paper](https://github.com/formidable-family/ffc-paper).

The goal of this project is to assess the results of combining the original Fragile Families Challenge data set with additional information (or metadata, or "priors") about the variables contained in that data set, and additionally to assess the impact of different approaches to missing-data imputation on the original data. The additional information is produced and recorded in the repositories named above, and drawn on here. Ultimately, this pipeline produces 21 distinct models.

# Running the code

## Packages and dependencies

Packages: tidyverse, doParallel, devtools, FFCRegressionImputation, Amelia

Additional repositories: ffc-data-processing

## Setup and data

The data files from the FFC, `background.csv` and `train.csv`, must be placed in the `data/` folder.

Information about variable scoring or ranking comes from the `collective_wisdom` repository has been included in the `variables/` subfolder of this repository.

Information about variable classification, as either categorical or continuous, ultimately relies on `background.dta` and on both programmatic and manual assessment. This information is obtained by reading text files directly from `ffc-data-processing/output`. Additional utility functions are also sourced from that repository where necessary; therefore, running this pipeline requires an internet connection.

## Producing imputed data sets

We do not run models directly on the original data sets. Instead, we use 7 intermediate data sets, spanning 5 different approaches to missing-data imputation:

- lasso regression-based imputation
    - on the full set of viable variables: imputed-fulldata-lasso.rds
    - on the subset of "constructed" variables: imputed-lasso-constructed.rds
- OLS regression-based imputation with variable types: imputed-lm-vartype.rds
- OLS regression-based imputation without variable types\*
- mean (and mode) imputation: meanmode_imputed.rds
- multiple imputation with the Amelia package
    - on the subset of "collective wisdom" variables: background_ffvars_amelia.rds
    - on the subset of "constructed" variables: background_constructed_amelia.rds

\* This was the first implementation of regression-based implementation; we expected subsequent versions to be improvements, but retained the predictions for comparison.

### FFCRegressionImputation

**Note:** Currently reconstructing the options used to generate our data sets.

Run `impute_data.R` to install the FFCRegressionImputation package and generate data sets by regression-based imputation and by mean imputation. Producing the first five imputed data sets described above will take several hours.

### Amelia

The code for multiple imputation using Amelia is located in [ffc-data-processing](https://github.com/ccgilroy/ffc-data-processing), not in this repository, because it relies extensively on utility functions in that repository (as well as on FFCRegressionImputation). The two scripts to run are [`setup_mi_data.R`](https://github.com/ccgilroy/ffc-data-processing/blob/master/vignettes/setup_mi_data.R) and [`mi.R`](https://github.com/ccgilroy/ffc-data-processing/blob/master/vignettes/mi.R) in the `vignettes/` subfolder.

**Important:** `mi.R` is computationally intensive. It should be run *separately* from all other code, on a server with sufficient resources. It was run on the [CSDE Simulation Cluster](https://csde.washington.edu/computing/resources/) at the University of Washington, and took approximately eight hours, with the multiple data sets (m = 5) run in parallel.

Amelia is bootstrapping values from a multivariate normal distribution, and computation time increases very nonlinearly with increasing number of variables. Even with only 200-300 variables out of 10000, this is much slower than any of the other data-processing, imputation, or model-fitting code in this project.

Once `background_ffvars_amelia.rds` and `background_constructed_amelia.rds` are produced, they should be manually moved from the server where they were created and placed in the `data/` subfolder of this repository.

## Fitting models

The scripts that use the intermediate data sets imputed above to produce zipped predictions are all of the form `run_lasso{_X}.R`.

These scripts source functions from the `models/` and `utils/` subdirectories; no code in those subdirectories needs to be run independently.

`tune_alpha.R` was run once, interactively, to produce approximately optimal alpha values via a grid search. Because these values are hardcoded in the run_lasso scripts, `tune_alpha.R` does not need to be run again.
