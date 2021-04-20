library(mlr)
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)
library(flextable)

##################################################### Load in predictions
load(here("create_graphs_tables", "data", "svmPredictions.RData"))
load(here("create_graphs_tables", "data", "rfPredictions.RData"))
load(here("create_graphs_tables", "data", "xgbPredictions.RData"))

################################# Load in test data to calculate naive accuracy
load(here("create_graphs_tables", "data", "fatalTest.RData"))
load(here("create_graphs_tables", "data", "raceTest.RData"))

#################### Find Accuracy, True Positive Rate, and False Positive Rate
performanceSvm <-
    pmap(list(svmPredictions, names(svmPredictions)),
         function(predictions, name, algo) {
             generateThreshVsPerfData(predictions,
                                      measures = list(fpr, tpr, acc))$data %>%
            as_tibble() %>%
            mutate(name = paste0(name, algo))},
         algo = "Svm")

performanceRf <-
    pmap(list(rfPredictions, names(rfPredictions)),
         function(predictions, name, algo) {
             generateThreshVsPerfData(predictions,
                                      measures = list(fpr, tpr, acc))$data %>%
                 as_tibble() %>%
                 mutate(name = paste0(name, algo))},
         algo = "Rf")

performanceXgb <-
    pmap(list(xgbPredictions, names(xgbPredictions)),
         function(predictions, name, algo) {
             generateThreshVsPerfData(predictions,
                                      measures = list(fpr, tpr, acc))$data %>%
                 as_tibble() %>%
                 mutate(name = paste0(name, algo))},
         algo = "Xgb")

performance <-
    map_dfr(list(performanceRf, performanceSvm, performanceXgb), bind_rows) %>%
    mutate(source = str_extract(name, "washpo|vice|fatal"),
           datePlace = str_extract(name, "Dg|Ndg"),
           algo = str_extract(name, "Rf|Svm|Xgb"),
           datePlace = if_else(is.na(datePlace), "Dg", datePlace))

############################################## Plot ROC Curve
ggplot(performance, aes(x = fpr, y = tpr)) +
    geom_line(aes(color = datePlace, group = datePlace)) +
    facet_wrap(~source+algo) +
    theme_bw() +
    ggsave(here("create_graphs_tables", "output", "ROCCurves.png"))

########################################################## Find max accuracy
maxAcc <-
    performance %>%
    group_by(name, source, algo, datePlace) %>%
    summarise(acc = max(acc)) %>%
    ungroup()

###################################################### Find naive accuracy
test <- as.list(c(fatalTest, raceTest))
test <- test[names(rfPredictions)]

naiveAccuracy <- pmap_dfr(list(test, names(test)), function(df, name) {
    if(str_detect(name, "washpo"))
        max(table(df$race)) / sum(table(df$race))
    else if(str_detect(name, "vice"))
        max(table(df$SubjectRace)) / sum(table(df$SubjectRace))
    else if(str_detect(name, "fatal"))
        max(table(df$Fatal)) / sum(table(df$Fatal))
}) %>%
    pivot_longer(everything(), names_to = "name", values_to = "acc") %>%
    mutate(source = str_extract(name, "washpo|vice|fatal"),
           algo = "naive",
           datePlace = str_extract(name, "Dg|Ndg"),
           datePlace = if_else(is.na(datePlace), "Dg", datePlace))

##################################################### Plot results
accuracy <-
    bind_rows(maxAcc, naiveAccuracy) %>%
    mutate(label = paste0(algo, datePlace),
           label = case_when(label == "naiveDg" ~ "Naive (Time and Place)",
                             label == "RfDg" ~ "Random Forest (Time and Place)",
                             label == "XgbDg" ~ "XGBoost (Time and Place)",
                             label == "SvmDg" ~ "SVM (Time and Place",
                             label == "naiveNdg" ~ "Naive",
                             label == "RfNdg" ~ "Random Forest",
                             label == "SvmNdg" ~ "SVM",
                             label == "XgbNdg" ~ "XGBoost"),
           source = case_when(source == "fatal" ~ "Vice News (Fatal)",
                              source == "vice" ~ "Vice News (Race)",
                              source == "washpo" ~ "Washington Post (Race)"))

ggplot(accuracy, aes(x = reorder(label, acc), y = acc)) +
    geom_bar(stat = "identity") +
    facet_wrap(~source, scales = "free_y", ncol = 1) +
    theme_bw() +
    scale_y_continuous(breaks = seq(0, 1, 0.1)) +
    labs(x = "Sample + Algorithm",
         y = "Maximum Accuracy",
         title = "Comparison of Accuracies Across Samples") +
    coord_flip() +
    theme(axis.text.y = element_text(size = 7)) +
    ggsave(here("create_graphs_tables", "output", "Accuracy.png"))

############################################# Create table of results
accuracyTables <-
    accuracy %>%
    arrange(source, desc(acc)) %>%
    select(-name, -algo, -datePlace) %>%
    group_by(source) %>%
    group_split()

names <- map_chr(accuracyTables,
                 function(table) {table %>% select(source) %>% unique() %>% unlist()})
names(accuracyTables) <- names

pmap(list(accuracyTables, names(accuracyTables)), function(table, name) {
    table %>%
        flextable() %>%
        save_as_docx(path = here("create_graphs_tables",
                                 "output",
                                 paste0(name, ".docx")))
})
