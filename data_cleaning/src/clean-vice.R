library(here)
library(dplyr)
library(readr)
library(purrr)
library(tidyr)
library(ggplot2)
library(stringr)
library(lubridate)

# Read in the data
vice_subject <- read_csv(here("data_cleaning", "data", "vice-subject.csv"))

# Create year, month, and day columns from the date
# Some dates are just the year
# Some dates are the month and the year
# Some dates are day, month, year
# Some dates are month, day year
viceClean <- 
    vice_subject %>%
    mutate(year = case_when(nchar(Date) == 4 ~ year(ymd(paste0(Date, "-01-01"))),
                            str_detect(Date, "-") & nchar(Date) == 7 ~ year(ymd(paste0(Date, "-01"))),
                            as.numeric(str_sub(Date, 1, 2)) >= 13 ~ year(dmy(Date)),
                            T ~ year(mdy(Date))),
           month = case_when(nchar(Date) == 4 ~ NA_real_,
                             str_detect(Date, "-") & nchar(Date) == 7 ~ month(ymd(paste0(Date, "-01"))),
                             as.numeric(str_sub(Date, 1, 2)) >= 13 ~ month(dmy(Date)),
                             T ~ month(mdy(Date))),
           day = case_when(nchar(Date) == 4 ~ NA_real_,
                           str_detect(Date, "-") & nchar(Date) == 7 ~ NA_real_,
                           as.numeric(str_sub(Date, 1, 2)) >= 13 ~ as.numeric(day(dmy(Date))),
                           T ~ as.numeric(day(mdy(Date)))))

# Clean up the number of shots fired.
# Categories like Multiple, Unknown, or U become missing
# If there was at least "x" number of shots (>/=), it becomes "x"
# Numbers split by ; indicates number of shots fired by each officer, they're summed together
viceClean <-
    viceClean %>%
    mutate(fixedNrShots = str_replace_all(NumberOfShots, "[a-zA-Z\\s>/=]", ""),
           fixedNrShots = map_dbl(str_split(NumberOfShots, ";"),
                                  function(vctr) {sum(as.numeric(vctr))}))

# Trying to make sense of the Nature of Stop variable and categorize it.
# The coding is based off of coding Vice did contained in the "sit" variable.
# I followed all their coding procedures based in initial_data_processing.R
# My coding largely aligns with their results, I think. Hard to verify because
# there is no id to link subjects to incidents. Additionally I believe I found
# some errors in their coding which mine fixes.
viceClean <-
    viceClean %>%
    mutate(situation =
               case_when(str_detect(tolower(NatureOfStop), "suicid") ~ "suicide",
                         str_detect(tolower(NatureOfStop), "mental") ~ "mentalhealth",
                         str_detect(tolower(NatureOfStop), "man with a gun|weapon|armed") ~ "weapon",
                         str_detect(tolower(NatureOfStop), "shots|shoot") ~ "shooting",
                         str_detect(tolower(NatureOfStop), "narcots|drugs|drug") ~ "drugs",
                         str_detect(tolower(NatureOfStop), "off duty|off-duty") ~ "offduty",
                         str_detect(tolower(NatureOfStop), "domestic") ~ "domesticViolence",
                         str_detect(tolower(NatureOfStop), "crime|assault|stabbing") ~ "crime",
                         str_detect(tolower(NatureOfStop), "call for service|radio call") ~ "call",
                         str_detect(tolower(NatureOfStop), "suspicious|welfare|proactive|investigation|pursuit") ~ "suspicious",
                         str_detect(tolower(NatureOfStop), "stolen vehicle|stolen car") ~ "stolenvehicle",
                         str_detect(tolower(NatureOfStop), "car|vehicle|speeding|traffic") ~ "traffic",
                         str_detect(tolower(NatureOfStop), "suspect|wanted|warrant") ~ "suspect",
                         str_detect(tolower(NatureOfStop), "robbery|burglary|theft|shoplifting|robbey") ~ "robbery",
                         T ~ "misc."))

viceClean <-
    viceClean %>%
    mutate(id = row_number(),
           OfficerGender)

a <-
    viceClean %>%
    mutate(OfficerGenderNew = str_replace(OfficerGender, ":", ";"),
           OfficerGenderNew = str_replace(OfficerGenderNew, ";$", "")) %>%
    separate(OfficerGenderNew, into = paste0("officerGender", 1:22), sep = ";") %>%
    mutate(id = row_number()) %>%
    pivot_longer(cols = matches("officerGender[0-9]{1,2}")) %>%
    select(-name) %>%
    mutate(value = str_replace(value, "^MALE$", "M"),
           value = str_replace(value, "^FEMALE$", "F"),
           value = str_replace(value, "/M", "M"),
           value = str_replace(value, "Male", "M"),
           value = if_else(value == "N", "U", value),
           value = str_replace(value, "Unknown", "U"),
           value = if_else(value == "W", "U", value),
           value = str_replace(value, " M", "M")) %>%
    count(id, value) %>%
    mutate(value = paste0("officerGender", value)) %>%
    filter(value != "officerGenderNA") %>%
    pivot_wider(names_from = value, values_from = n) %>%
    mutate(across(everything(), ~replace_na(.x, 0)))
    
b <-
    full_join(a, select(viceClean, OfficerGender, id, NumberOfOfficers), by = "id") %>%
    rowwise() %>%
    mutate(newOfficerCount = sum(officerGenderM, officerGenderF, officerGenderU)) %>%
    filter(newOfficerCount != NumberOfOfficers)
