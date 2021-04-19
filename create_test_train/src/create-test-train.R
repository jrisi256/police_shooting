library(here)
library(dplyr)
library(caret)
library(purrr)
library(readr)

# Load in our functions to standardize data
source(here("functions.R"))

# Read in the data
vice <- read_csv(here("create_test_train", "data", "vice-clean.csv"),
                 col_types = cols(NumberOfOfficers = "c"))
washpo <- read_csv(here("create_test_train", "data", "washpo-clean.csv"))

# Select out columns we won't be using in any analysis and create base dataset
washpoBase <-
    washpo %>%
    select(-id, -name, -date, -city, -longitude, -latitude, -is_geocoding_exact,
           -armed)

viceBase <-
    vice %>%
    select(-Date, -NatureOfStop, -NumberOfShots, -NumberOfOfficers, -City,
           -OfficerRace, -OfficerGender, -FullNarrative, -Notes, -Department)

# There are 3 decisions we have to make concerning our data:
# Black-Americans vs. White-Americans OR Hispanics vs. Black-Americans vs. W
# Include Date/Geography vs. Don't Include Date/Geography
# Include missing vs. don't include missing.

##################### Washington Post
#################################### Used for main paper
washpoNdgBNm <-
    washpoBase %>%
    filter(race == "W" | race == "B") %>%
    select(-year, -month, -day, -state) %>%
    filter(across(everything(), ~!is.na(.x)))

washpoDgBNm <-
    washpoBase %>%
    filter(race == "W" | race == "B") %>%
    filter(across(everything(), ~!is.na(.x)))

#################################### Used for appendix
washpoDgBM <- washpoBase %>% filter(race == "W" | race == "B")
washpoDgHM <- washpoBase %>% filter(race == "B" | race == "W" | race == "H")

washpoDgHNm <-
    washpoBase %>%
    filter(race == "B" | race == "W" | race == "H") %>%
    filter(across(everything(), ~!is.na(.x)))

####################### Vice News
###################################### Used for main paper
viceNdgBNm <-
    viceBase %>%
    filter(SubjectRace == "B" | SubjectRace == "W") %>%
    select(-year, -month, -day, -departmentFixed, -fixedNrShots) %>%
    filter(across(everything(), ~!is.na(.x)))

viceDgBNm <-
    viceBase %>%
    filter(SubjectRace == "B" | SubjectRace == "W") %>%
    select(-fixedNrShots) %>%
    filter(across(everything(), ~!is.na(.x)))

##################################### Used for appendix
viceDgBM <- viceBase %>% filter(SubjectRace == "B" | SubjectRace == "W")
viceDgHM <- viceBase %>% filter(SubjectRace %in% c("B", "W", "L"))

viceDgHNm <-
    viceBase %>%
    filter(SubjectRace %in% c("B", "W", "L")) %>%
    select(-fixedNrShots) %>%
    filter(across(everything(), ~!is.na(.x)))

################################### Create Train/Test for each sample
set.seed(420)

listSamples <- list(washpoNdgBNm = washpoNdgBNm,
                    washpoDgBM = washpoDgBM,
                    washpoDgHM = washpoDgHM,
                    washpoDgHNm = washpoDgHNm,
                    viceNdgBNm = viceNdgBNm,
                    viceDgBNm = viceDgBNm,
                    viceDgBM = viceDgBM,
                    viceDgHM = viceDgHM,
                    viceDgHNm = viceDgHNm)

listSource <- as.list(c(rep("washpo", 4), rep("vice", 5)))

listSplits <-
    pmap(list(listSamples, listSource), function(sample, source) {
        if(source == "washpo")
            createDataPartition(sample[["race"]], p = 0.8, list = F, times = 1)
        else if(source == "vice")
            createDataPartition(sample[["SubjectRace"]],
                                p = 0.8,
                                list = F,
                                times = 1)
    })

###################### Vice News Fatal vs. Non-Fatal
###################################################### For main paper
fatalBNm <-
    viceBase %>%
    filter(Fatal != "U") %>%
    filter(SubjectRace == "B" | SubjectRace == "W") %>%
    select(-fixedNrShots) %>%
    filter(across(everything(), ~!is.na(.x)))

fatalHNm <-
    viceBase %>%
    filter(Fatal != "U") %>%
    filter(SubjectRace == "B" | SubjectRace == "W" | SubjectRace == "L") %>%
    select(-fixedNrShots) %>%
    filter(across(everything(), ~!is.na(.x)))

##################################################### For Appendix
fatalBM <-
    viceBase %>%
    filter(Fatal != "U") %>%
    filter(SubjectRace %in% c("B", "W"))

fatalHM <-
    viceBase %>%
    filter(Fatal != "U") %>%
    filter(SubjectRace %in% c("B", "W", "L"))

listFatalSamples <- list(fatalBNm = fatalBNm,
                         fatalHNm = fatalHNm,
                         fatalBM = fatalBM,
                         fatalHM = fatalHM)

listFatalSplits <-
    map(listFatalSamples, function(sample) {
        createDataPartition(sample[["Fatal"]], p = 0.8, list = F, times = 1)
    })

#################################################### Create test/train splits
raceTrain <-
    pmap(list(listSamples, listSplits), function(sample, indices) {
        sample[indices,]})

raceTest <-
    pmap(list(listSamples, listSplits), function(sample, indices) {
        sample[-indices,]})

# We can do this because they have the same number of observations
raceTrain[["washpoDgBNm"]] <- washpoDgBNm[listSplits[["washpoNdgBNm"]],]
raceTest[["washpoDgBNm"]] <- washpoDgBNm[-listSplits[["washpoNdgBNm"]],]

fatalTrain <-
    pmap(list(listFatalSamples, listFatalSplits), function(sample, indices) {
        sample[indices,]})

fatalTest <-
    pmap(list(listFatalSamples, listFatalSplits), function(sample, indices) {
        sample[-indices,]})

######################################### Save Train/Test Splits for our data
save(raceTrain, file = here("create_test_train", "output", "raceTrain.RData"))
save(raceTest, file = here("create_test_train", "output", "raceTest.RData"))
save(fatalTrain, file = here("create_test_train", "output", "fatalTrain.RData"))
save(fatalTest, file = here("create_test_train", "output", "fatalTest.RData"))

############################ Create train/test splits for standardized data too
listSamplesStd <- pmap(list(listSamples, names(listSamples)), StandardizeData)
listFatalSamplesStd <- pmap(list(listFatalSamples, names(listFatalSamples)),
                            StandardizeData)

raceTrainStd <-
    pmap(list(listSamplesStd, listSplits), function(sample, indices) {
        sample[indices,]})

raceTestStd <-
    pmap(list(listSamplesStd, listSplits), function(sample, indices) {
        sample[-indices,]})

# We can do this because they have the same number of observations
raceTrainStd[["washpoDgBNm"]] <-
    StandardizeData(washpoDgBNm, "washpoDgBNm")[listSplits[["washpoNdgBNm"]],]

raceTestStd[["washpoDgBNm"]] <-
    StandardizeData(washpoDgBNm, "washpoDgBNm")[-listSplits[["washpoNdgBNm"]],]

fatalTrainStd <-
    pmap(list(listFatalSamplesStd, listFatalSplits), function(sample, indices) {
        sample[indices,]})

fatalTestStd <-
    pmap(list(listFatalSamplesStd, listFatalSplits), function(sample, indices) {
        sample[-indices,]})

############################ Save Standardized Train/Test Splits for our data
save(raceTrainStd,
     file = here("create_test_train", "output", "raceTrainStd.RData"))
save(raceTestStd,
     file = here("create_test_train", "output", "raceTestStd.RData"))
save(fatalTrainStd,
     file = here("create_test_train", "output", "fatalTrainStd.RData"))
save(fatalTestStd,
     file = here("create_test_train", "output", "fatalTestStd.RData"))
