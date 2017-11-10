if (!"devtools" %in% installed.packages()) install.packages("devtools")

if (!"FFCRegressionImputation" %in% installed.packages()) {
  devtools::install_github("annafil/FFCRegressionImputation")
}

library(FFCRegressionImputation)

# Setup ----

# read background data
yourDF <- initImputation(data='data/background.csv') 

# retrieve lists of continuous and categorical variables
vars_continuous <- readLines("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/output/continuous.txt")
vars_categorical <- readLines("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/output/categorical.txt")

# Imputation ----

# Correlation matrix for data sets 1 and 2
output <- corMatrix(data=yourDF, 
                    continuous = vars_continuous, 
                    categorical = vars_categorical)

# Imputed data set 1: lasso regression imputation
# filename: imputed-fulldata-lasso.rds
lassoImputedDF <- regImputation(yourDF, output,     
                                method = 'lasso')

saveRDS(lassoImputedDF, "data/imputed-fulldata-lasso.rds")

# Imputed data set 2: typed OLS regression imputation
# filename: imputed-lm-vartype.rds
lmImputedDF <- regImputation(yourDF, output,                    
                             continuous = vars_continuous, 
                             categorical = vars_categorical)

saveRDS(lmImputedDF, "data/imputed-lm-vartype.rds")

# Imputed data set 3: mean/mode imputation
# filename: meanmode-imputed.rds
meanImputedDF <- initImputation(data='data/background.csv', meanimpute = 1)

# Imputed data set 4: lasso regression imputation, constructed variables only
# filename: imputed-lasso-constructed.rds
output_constructed <- corMatrix(data=yourDF,              
                                continuous = vars_continuous, 
                                categorical = vars_categorical,  
                                varpattern = '^c[mfhpktfvino]{1,2}[12345]')

lassoConstructedImputedDF <- regImputation(output_constructed$df, 
                                           output_constructed$corMatrix, 
                                           continuous = vars_continuous, 
                                           categorical = vars_categorical, 
                                           method = 'lasso')

saveRDS(lassoConstructedImputedDF, "data/imputed-lasso-constructed.rds")

# Imputed data set 5: untyped OLS regression imputation
output_untyped <- corMatrix(data=yourDF)
lmUntypedImputedDF <- regImputation(output_untyped$df, 
                                    output_untyped$corMatrix)
saveRDS(lmUntypedImputedDF, "data/imputed-lm-untyped.rds")

# Imputed data sets 6 and 7 do not use FFCRegressionImputation. 
# Instead, they use Amelia, and the following scripts:
# https://github.com/ccgilroy/ffc-data-processing/blob/master/vignettes/setup_mi_data.R
# https://github.com/ccgilroy/ffc-data-processing/blob/master/vignettes/mi.R
