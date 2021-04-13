library(mlr)
library(here)
library(dplyr)
library(purrr)
library(e1071)
library(stringr)
library(xgboost)
library(parallel)
library(parallelMap)
library(randomForest)

source(here("functions.R"))

# Read in data
load(here("hyperparameter_tuning", "data", "raceTrain.RData"))
load(here("hyperparameter_tuning", "data", "fatalTrain.RData"))

# Select samples we need and create learning tasks
raceSamples <- c("washpoNdgBNm", "washpoDgBNm", "viceNdgBNm", "viceDgBNm")
fatalSamples <- c("fatalBNm")
totalSamples <- as.list(c(raceTrain[raceSamples], fatalTrain[fatalSamples]))
totalSamples <- pmap(list(totalSamples, names(totalSamples)), StandardizeData)

tasks <- pmap(list(totalSamples, names(totalSamples)), function(df, name) {
    if(str_detect(name, "washpo")) 
        makeClassifTask(data = df, target = "race")
    else if(str_detect(name, "vice"))
        makeClassifTask(data = df, target = "SubjectRace")
    else if(str_detect(name, "fatal"))
        makeClassifTask(data = df, target = "Fatal")
})

################################## Xgboost doesn't support factors
totalSamplesXgboost <-
    pmap(list(totalSamples, names(totalSamples)), function(df, name) {
        if(str_detect(name, "washpo"))
            df <- df %>% select(-race)
        else if(str_detect(name, "vice"))
            df <- df %>% select(-SubjectRace)
        else if(str_detect(name, "fatal"))
            df <- df %>% select(-Fatal)
    }) %>%
    map(createDummyFeatures)

totalSamplesXgboost <-
    pmap(list(totalSamplesXgboost, totalSamples, names(totalSamples)),
         function(dfX, df, name) {
             if(str_detect(name, "washpo"))
                 dfX <- bind_cols(dfX, select(df, race)) 
             else if(str_detect(name, "vice"))
                 dfX <- bind_cols(dfX, select(df, SubjectRace))
             else if(str_detect(name, "fatal"))
                 dfX <- bind_cols(dfX, select(df, Fatal))
            })

tasksXgboost <- pmap(list(totalSamplesXgboost,
                          names(totalSamplesXgboost)), function(df, name) {
    if(str_detect(name, "washpo")) 
        makeClassifTask(data = df, target = "race")
    else if(str_detect(name, "vice"))
        makeClassifTask(data = df, target = "SubjectRace")
    else if(str_detect(name, "fatal"))
        makeClassifTask(data = df, target = "Fatal")
})

# Create the learners
svm <- makeLearner("classif.svm", predict.type = "prob")
rf <- makeLearner("classif.randomForest", importance = T, predict.type = "prob")
xgb <- makeLearner("classif.xgboost", predict.type = "prob")

# Create cross-validation procedure - 5-fold cross validation, repeated 5 times
kFold5Rep5 <- makeResampleDesc("RepCV", fold = 1, reps = 1)
kFold5Rep5 <- makeResampleDesc("CV", iters = 2)

# Explore 50 different combinations of hyperparameters for SVM
randSearchSvm <- makeTuneControlRandom(maxit = 1)

# Explore 500 different combinations of hyperparameters for trees
randSearchTrees <- makeTuneControlRandom(maxit = 1)

# Create the hyperparameter space for the support vector machine
svmParamSpace <- makeParamSet(
    makeDiscreteParam("kernel", values = c("polynomial", "radial", "sigmoid")),
    makeIntegerParam("degree", lower = 1, upper = 3),
    makeNumericParam("cost", lower = 0.1, upper = 10),
    makeNumericParam("gamma", lower = 0.1, upper = 10))

# Create the hyperparameter space for the random forest
rfParamSpace <- makeParamSet(
    makeIntegerParam("ntree", lower = 200, upper = 200),
    makeIntegerParam("mtry", lower = 5, upper = 10),
    makeIntegerParam("nodesize", lower = 1, upper = 10),
    makeIntegerParam("maxnodes", lower = 5, upper = 30))

# Create the hyperparameter space for xgboost
xgbParamSpace <- makeParamSet(
    makeNumericParam("eta", lower = 0, upper = 1),
    makeNumericParam("gamma", lower = 0, upper = 10),
    makeIntegerParam("max_depth", lower = 1, upper = 20),
    makeNumericParam("min_child_weight", lower = 1, upper = 10),
    makeNumericParam("subsample", lower = 0.5, upper = 1),
    makeNumericParam("colsample_bytree", lower = 0.5, upper = 1),
    makeIntegerParam("nrounds", lower = 75, upper = 75))

######################## Used for setting seeds in parallel computing contexts
set.seed(420, kind = "L'Ecuyer-CMRG")

################### Tune our hyperparameters for the SVM
ptm <- proc.time()
parallelStartSocket(cpus = detectCores())

tunedSvms <- map(tasks, function(task) {
    tuneParams(svm,
               task = task,
               resampling = kFold5Rep5,
               par.set = svmParamSpace,
               control = randSearchSvm,
               measures = list(acc, fpr, fnr))
})

parallelStop()
proc.time() - ptm

################### Tune our hyperparameters for the Random Forest
ptm <- proc.time()
parallelStartSocket(cpus = detectCores())

tunedRfs <- map(tasks, function(task) {
    tuneParams(rf,
               task = task,
               resampling = kFold5Rep5,
               par.set = rfParamSpace,
               control = randSearchTrees,
               measures = list(acc, fpr, fnr))
})

parallelStop()
proc.time() - ptm

################### Tune our hyperparameters for the Random Forest
ptm <- proc.time()

tunedXgbs <- map(tasksXgboost, function(task) {
    tuneParams(xgb,
               task = task,
               resampling = kFold5Rep5,
               par.set = xgbParamSpace,
               control = randSearchTrees,
               measures = list(acc, fpr, fnr))
})

proc.time() - ptm
