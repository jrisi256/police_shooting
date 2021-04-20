library(mlr)
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)
library(flextable)

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

################# Find the rankings of the importance of each of the features
features <-
    bind_rows(featImportanceAcc, featImportanceNode, featImportanceXgb) %>%
    group_by(name, model) %>%
    arrange(desc(importance)) %>%
    mutate(rank = row_number())

featuresWideRank <-
    features %>%
    mutate(label = paste0(name, "_", model),
           source = str_extract(name, "fatal|vice|washpo")) %>%
    group_by(source) %>%
    group_split() %>%
    map(., function(df) {
        df %>%
            pivot_wider(id = variable, names_from = label, values_from = rank)})

featuresWideScore <-
    features %>%
    mutate(label = paste0(name, "_", model),
           source = str_extract(name, "fatal|vice|washpo")) %>%
    group_by(source) %>%
    group_split() %>%
    map(., function(df) {
        df %>%
            pivot_wider(id = variable, names_from = label, values_from = importance)})

names <- map_chr(featuresWideRank, function(df) {
    column <- colnames(df)[2]
    source <- str_extract(column, "fatal|vice|washpo")
})

names(featuresWideRank) <- names
names(featuresWideScore) <- names

pmap(list(featuresWideRank, names(featuresWideRank)), function(table, name) {
    
    if(name == "fatal")
        table <- table %>% arrange(fatalBNm_xgboost)
    else if(name == "washpo")
        table <- table %>% arrange(washpoDgBNm_xgboost)
    else if(name == "vice")
        table <- table %>% arrange(viceDgBNm_xgboost)
    
    table %>%
        flextable() %>%
        save_as_docx(path = here("create_graphs_tables",
                                 "output",
                                 paste0(name, "_featRank.docx")))
})

pmap(list(featuresWideScore, names(featuresWideScore)), function(table, name) {
    
    if(name == "fatal")
        table <- table %>% arrange(desc(fatalBNm_xgboost))
    else if(name == "washpo")
        table <- table %>% arrange(desc(washpoDgBNm_xgboost))
    else if(name == "vice")
        table <- table %>% arrange(desc(viceDgBNm_xgboost))
    
    table %>%
        flextable() %>%
        save_as_docx(path = here("create_graphs_tables",
                                 "output",
                                 paste0(name, "_featScore.docx")))
})
