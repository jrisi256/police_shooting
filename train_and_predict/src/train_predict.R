library(mlr)
library(here)
library(purrr)
library(dplyr)
library(stringr)

#################################################### Load in our functions
source(here("functions.R"))

################################################# Load in our training data
load(here("train_and_predict", "data", "raceTrainStd.RData"))
load(here("train_and_predict", "data", "fatalTrainStd.RData"))

####################################################### Load in our test data
load(here("train_and_predict", "data", "raceTestStd.RData"))
load(here("train_and_predict", "data", "fatalTestStd.RData"))

############################################## Load in our hyperparameters
load(here("train_and_predict", "data", "tunedSvms.RData"))
load(here("train_and_predict", "data", "tunedRfs.RData"))
load(here("train_and_predict", "data", "tunedXgbs.RData"))

################################################## Create the learners
svm <- makeLearner("classif.svm", predict.type = "prob")
rf <- makeLearner("classif.randomForest", importance = T, predict.type = "prob")
xgb <- makeLearner("classif.xgboost", predict.type = "prob")

############################ Select samples we need and create learning tasks
raceSamples <- c("washpoNdgBNm", "washpoDgBNm", "viceNdgBNm", "viceDgBNm")
fatalSamples <- c("fatalBNm")
totalSamples <- as.list(c(raceTrainStd[raceSamples], fatalTrainStd[fatalSamples]))

tasks <- pmap(list(totalSamples, names(totalSamples)), function(df, name) {
    if(str_detect(name, "washpo")) 
        makeClassifTask(data = df, target = "race")
    else if(str_detect(name, "vice"))
        makeClassifTask(data = df, target = "SubjectRace")
    else if(str_detect(name, "fatal"))
        makeClassifTask(data = df, target = "Fatal")
})

########################################## Keep only the test samples we need
testSamples <- as.list(c(raceTestStd[raceSamples], fatalTestStd[fatalSamples]))

############################ Train our models with the tuned hyperparameters
set.seed(420)

trainedSvms <-
    pmap(list(tunedSvms, tasks), function(hyperparam, task, learner) {
        tunedModel <- setHyperPars(learner, par.vals = hyperparam$x)
        trainedModel <- mlr::train(tunedModel, task)},
        learner = svm)

trainedRfs <-
    pmap(list(tunedRfs, tasks), function(hyperparam, task, learner) {
        tunedModel <- setHyperPars(learner, par.vals = hyperparam$x)
        trainedModel <- mlr::train(tunedModel, task)},
        learner = rf)

trainedXgbs <-
    pmap(list(tunedXgbs, tasks), function(hyperparam, task, learner) {
        tunedModel <- setHyperPars(learner, par.vals = hyperparam$x)
        trainedModel <- mlr::train(tunedModel, task)},
        learner = xgb)

######################### Save our trained models
save(trainedSvms, file = here("train_and_predict", "output", "trainedSvms.RData"))
save(trainedRfs, file = here("train_and_predict", "output", "trainedRfs.RData"))
save(trainedXgbs, file = here("train_and_predict", "output", "trainedXgbs.RData"))

######################## Make predictions using our trained models
svmPredictions <-
    pmap(list(trainedSvms, testSamples), function(model, testSample) {
        predict(model, newdata = testSample)})

rfPredictions <-
    pmap(list(trainedRfs, testSamples), function(model, testSample) {
        predict(model, newdata = testSample)})

xgbPredictions <-
    pmap(list(trainedXgbs, testSamples), function(model, testSample) {
        predict(model, newdata = testSample)})

################################ Save our predictions
save(svmPredictions, file = here("train_and_predict", "output", "svmPredictions.RData"))
save(rfPredictions, file = here("train_and_predict", "output", "rfPredictions.RData"))
save(xgbPredictions, file = here("train_and_predict", "output", "xgbPredictions.RData"))
