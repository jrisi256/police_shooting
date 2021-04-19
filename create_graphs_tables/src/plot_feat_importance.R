library(mlr)
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)

############################## Load in trained random forest and XGBoost models
load(here("create_graphs_tables", "data", "trainedRfs.RData"))
load(here("create_graphs_tables", "data", "trainedXgbs.RData"))

############################## Get the feature importance
featImportanceNode <-
    pmap_dfr(list(trainedRfs, names(trainedRfs)), function(model, name) {
        getFeatureImportance(model)$res %>%
            mutate(model = "randomForestNode",
                   name = name)
})

featImportanceAcc <-
    pmap_dfr(list(trainedRfs, names(trainedRfs)), function(model, name) {
        getFeatureImportance(model, type = 1)$res %>%
            mutate(model = "randomForestAcc",
                   name = name)
})

featImportanceXgb <-
    pmap_dfr(list(trainedXgbs, names(trainedXgbs)), function(model, name) {
        getFeatureImportance(model)$res %>%
            mutate(model = "xgboost",
                   name = name)
})

features <-
    bind_rows(featImportanceAcc, featImportanceNode, featImportanceXgb) %>%
    group_by(name, model) %>%
    arrange(desc(importance)) %>%
    mutate(rank = row_number())

featuresWide <-
    features %>%
    mutate(label = paste0(name, "_", model),
           source = str_extract(name, "fatal|vice|washpo")) %>%
    group_by(source) %>%
    group_split() %>%
    map(., function(df) {
        df %>%
            pivot_wider(id = variable, names_from = label, values_from = rank)})
