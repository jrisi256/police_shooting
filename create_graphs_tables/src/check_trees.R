library(mlr)
library(here)
library(purrr)
library(ggplot2)

# Load the trained Random Forest and XGBoost models
load(here("create_graphs_tables", "data", "trainedRfs.RData"))
load(here("create_graphs_tables", "data", "trainedXgbs.RData"))

# Check to see if our OOB error rate converges for random forest
pmap(list(trainedRfs, names(trainedRfs)), function(rf, name) {
    rfData <- rf$learner.model
    png(here("create_graphs_tables", "output", paste0(name, "_rfDiagnostic.png")))
    plot(rfData, main = name)
    dev.off()
})

# Check to see if our error converges for XGBoost
pmap(list(trainedXgbs, names(trainedXgbs)), function(xgb, name) {
    
    xgbData <- xgb$learner.model
    
    ggplot(xgbData$evaluation_log, aes(iter, train_logloss)) +
        geom_line() +
        geom_point() +
        theme_bw() +
        labs(title = name) +
        ggsave(paste0(name, "_xgbDiagnostic.png"),
               path = here("create_graphs_tables", "output"))
})
