library(mlr)
library(here)
library(dplyr)
library(tidyr)
library(purrr)
library(table1)
library(stringr)
library(ggplot2)

######################################### Load in the data
load(here("create_graphs_tables", "data", "raceTrain.RData"))
load(here("create_graphs_tables", "data", "fatalTrain.RData"))

####################### Choose appropriate samples to create descriptive tables
raceSampleWashPo <- raceTrain[["washpoDgBNm"]]
raceSampleVice <- raceTrain[["viceDgBNm"]]
fatalSample <- fatalTrain[["fatalBNm"]]

################################ Create the table for the Washington Post
raceSampleWashPo <-
    raceSampleWashPo %>%
    mutate(year = as.character(year),
           month = factor(month, levels = seq(1, 12, 1)),
           day = factor(day, levels = seq(1, 31, 1)))

table1::label(raceSampleWashPo$manner_of_death) <- "Manner of Death"
table1::label(raceSampleWashPo$age) <- "Age"
table1::label(raceSampleWashPo$gender) <- "Sex"
table1::label(raceSampleWashPo$race) <- "Race"
table1::label(raceSampleWashPo$state) <- "State"
table1::label(raceSampleWashPo$signs_of_mental_illness) <-
    "Signs of Mental Illness"
table1::label(raceSampleWashPo$threat_level) <- "Threat Level"
table1::label(raceSampleWashPo$flee) <- "Attempted Fleeing"
table1::label(raceSampleWashPo$body_camera) <- "Body Camera In Use by Officer"
table1::label(raceSampleWashPo$year) <- "Year"
table1::label(raceSampleWashPo$month) <- "Month"
table1::label(raceSampleWashPo$day) <- "Day"
table1::label(raceSampleWashPo$armedNew) <- "Civilian Armed"

washpoTable <-
    table1(~manner_of_death + age + gender + state + signs_of_mental_illness +
               threat_level + flee + body_camera + year + month + day + armedNew | race,
       data = raceSampleWashPo)

################################ Create the table for Vice News
raceSampleVice <-
    raceSampleVice %>%
    mutate(year = as.character(year),
           month = factor(month, levels = seq(1, 12, 1)),
           day = factor(day, levels = seq(1, 31, 1)))

table1::label(raceSampleVice$Fatal) <-
    "Fatal Incident (F = Fatal, N = Not Fatal, U = Unknown)"
table1::label(raceSampleVice$SubjectArmed) <- "Civilian Armed with A Gun"
table1::label(raceSampleVice$SubjectGender) <- "Sex"
table1::label(raceSampleVice$SubjectAge) <- "Age"
table1::label(raceSampleVice$year) <- "Year"
table1::label(raceSampleVice$month) <- "Month"
table1::label(raceSampleVice$day) <- "Day"
table1::label(raceSampleVice$fixedNrOfficers) <-"Number of Responding Officers"
table1::label(raceSampleVice$departmentFixed) <- "Police Department"
table1::label(raceSampleVice$situation) <- "Situation"
table1::label(raceSampleVice$officerGenderM) <- "Number of Male Responding Officers"
table1::label(raceSampleVice$officerGenderF) <- "Number of Female Responding Officers"
table1::label(raceSampleVice$officerRaceW) <- "Number of White Responding Officers"
table1::label(raceSampleVice$officerRaceB) <- "Number of Black Responding Officers"
table1::label(raceSampleVice$officerRaceL) <- "Number of Latinx Responding Officers"

viceTable <-
    table1(~Fatal + SubjectArmed + SubjectGender + SubjectAge + year + month + day +
               fixedNrOfficers + departmentFixed + situation + officerGenderM +
               officerGenderF + officerRaceW + officerRaceB + officerRaceL | SubjectRace,
           data = raceSampleVice)

################################ Create the table for Vice News (Fatal)
fatalSample <-
    fatalSample %>%
    mutate(year = as.character(year),
           month = factor(month, levels = seq(1, 12, 1)),
           day = factor(day, levels = seq(1, 31, 1)))

table1::label(fatalSample$SubjectRace) <- "Race"
table1::label(fatalSample$SubjectArmed) <- "Civilian Armed with A Gun"
table1::label(fatalSample$SubjectGender) <- "Sex"
table1::label(fatalSample$SubjectAge) <- "Age"
table1::label(fatalSample$year) <- "Year"
table1::label(fatalSample$month) <- "Month"
table1::label(fatalSample$day) <- "Day"
table1::label(fatalSample$fixedNrOfficers) <-"Number of Responding Officers"
table1::label(fatalSample$departmentFixed) <- "Police Department"
table1::label(fatalSample$situation) <- "Situation"
table1::label(fatalSample$officerGenderM) <- "Number of Male Responding Officers"
table1::label(fatalSample$officerGenderF) <- "Number of Female Responding Officers"
table1::label(fatalSample$officerRaceW) <- "Number of White Responding Officers"
table1::label(fatalSample$officerRaceB) <- "Number of Black Responding Officers"
table1::label(fatalSample$officerRaceL) <- "Number of Latinx Responding Officers"

fatalTable <-
    table1(~SubjectRace + SubjectArmed + SubjectGender + SubjectAge + year + month + day +
               fixedNrOfficers + departmentFixed + situation + officerGenderM +
               officerGenderF + officerRaceW + officerRaceB + officerRaceL | Fatal,
           data = fatalSample)
