library(here)
library(dplyr)
library(readr)
library(purrr)
library(tidyr)
library(ggplot2)
library(stringr)
library(lubridate)

# Read in the data
vice_subject <- read_csv(here("data_cleaning", "data", "vice-subject.csv"),
                         col_types = cols(NumberOfOfficers = "c"))

# Standardize columns and ensure they have appropriate type
# SubjectArmed: Recode NA valuees to U.
# SubjectRace: Recode NA values to U.
# SubjectGender: Recode NA values to U. Recode one M;U value to M.
# SubjectAge: Recode values to be categorical and NA values to be U.

viceClean <-
    vice_subject %>%
    mutate(SubjectArmed = if_else(is.na(SubjectArmed), "U", SubjectArmed),
           SubjectRace = if_else(is.na(SubjectRace), "U", SubjectRace),
           SubjectGender = if_else(SubjectGender == "N/A", "U", SubjectGender),
           SubjectGender = if_else(SubjectGender == "M;U", "M", SubjectGender),
           SubjectAge = case_when(as.numeric(SubjectAge) <= 19 ~ "0-19",
                                  SubjectAge == "Juvenile" ~ "0-19",
                                  as.numeric(SubjectAge) >= 20 & as.numeric(SubjectAge) < 30 ~ "20-29",
                                  SubjectAge == "21-23" ~ "20-29",
                                  as.numeric(SubjectAge) >= 30 & as.numeric(SubjectAge) < 40 ~ "30-39",
                                  as.numeric(SubjectAge) >= 40 & as.numeric(SubjectAge) < 50 ~ "40-49",
                                  as.numeric(SubjectAge) >= 50 & as.numeric(SubjectAge) < 60 ~ "50-59",
                                  as.numeric(SubjectAge) >= 60  ~ "60+",
                                  SubjectAge == "60-69" ~ "60+",
                                  SubjectAge == "UNKNOWN" ~ "U",
                                  SubjectAge == "N/A" ~ "U",
                                  T ~ "U"))

# Create year, month, and day columns from the date
# Some dates are just the year
# Some dates are the month and the year
# Some dates are day, month, year
# Some dates are month, day year
viceClean <- 
    viceClean %>%
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
           fixedNrShots = map_dbl(str_split(fixedNrShots, ";"),
                                  function(vctr) {sum(as.numeric(vctr))}))

# If there was at least "x" number of officers (>), it becomes "x".
# "2 or more" officers becomes 2 officers.
# "U" becomes NA.
# Finally this variable is converted to numeric type.
viceClean <-
    viceClean %>%
    mutate(fixedNrOfficers = str_replace_all(NumberOfOfficers, ">| or More", ""),
           fixedNrOfficers = if_else(fixedNrOfficers == "U",
                                     NA_character_,
                                     fixedNrOfficers),
           fixedNrOfficers = as.numeric(fixedNrOfficers))

# Recode some of the police departments to ensure more consistency
viceClean <-
    viceClean %>%
    mutate(departmentFixed =
               case_when(Department == "Baltimore County Police Department" ~ "Baltimore Police Department",
                         Department == "Boston Police Department; Massachusetts State Police" ~ "Boston Police Department",
                         Department == "Chicago Police Department; Illinois State Police" ~ "Chicago Police Department",
                         T ~ Department))

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

# Step 1: All colons (:) are replaced with semicolons (standardized split).
# Step 2: We split gender into multiple columns splitting on the semicolon.
# Step 3: We turn our dataset into a long dataset.
# Step 4: We standardize to have three values: Male, Female, Unknown
# Step 5: Widen the dataset to have 3 columns for the three sex values

viceClean <- viceClean %>% mutate(id = row_number())

genderClean <-
    viceClean %>%
    mutate(OfficerGenderNew = str_replace(OfficerGender, ":", ";"),
           OfficerGenderNew = str_replace(OfficerGenderNew, ";$", "")) %>%
    separate(OfficerGenderNew, into = paste0("officerGender", 1:23), sep = ";") %>%
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

viceClean <- viceClean %>% full_join(genderClean, by = "id")

# The number of officers in the fixedNrOfficers column does not always
# equal the number of officers summed across all the newly created gender
# columns. This is because the number of genders listed in OfficerGender does
# not always equal fixedNrOfficers. I leave as is for now. 549 mismatched records.

mismatchGender <-
    viceClean %>%
    select(officerGenderM, officerGenderF, officerGenderU, OfficerGender, id,
           fixedNrOfficers) %>%
    rowwise() %>%
    mutate(newOfficerCount = sum(officerGenderM, officerGenderF, officerGenderU)) %>%
    filter(newOfficerCount != fixedNrOfficers)

# Step 1: All colons (:) are replaced with semicolons (standardized split).
# Step 1a: Replace all missing values in Officer with Unknowns.
# Step 2: We split race into multiple columns splitting on the semicolon.
# Step 3: We turn our dataset into a long dataset.
# Step 4: We standardize to have 6 values: White, Black, Latino, Asian, Other, Unknown
# Step 5: Widen the dataset to have 6 columns for the 6 racevalues

raceClean <-
    viceClean %>%
    mutate(OfficerRaceNew = str_replace(OfficerRace, ":", ";"),
           OfficerRaceNew = str_replace(OfficerRaceNew, "A/PI Unknown", "A/PI;Unknown"),
           OfficerRaceNew = if_else(is.na(OfficerRaceNew), "U", OfficerRaceNew)) %>%
    separate(OfficerRaceNew, into = paste0("officerRace", 1:23), sep = ";") %>%
    mutate(id = row_number()) %>%
    pivot_longer(cols = matches("officerRace[0-9]{1,2}")) %>%
    select(-name) %>%
    mutate(value = str_replace(value, "WHITE", "W"),
           value = str_replace(value, "A/W|NA/W|W/ H|W/H|W/A|Multi-Racial", "O"),
           value = str_replace(value, "ASIAN", "A"),
           value = str_replace(value, "H/L", "L"),
           value = str_replace(value, "H| H", "L"),
           value = str_replace(value, "A/PI", "A"),
           value = str_replace(value, "AI/AN", "O"),
           value = str_replace(value, "I", "O"),
           value = str_replace(value, "BLACK", "B"),
           value = str_replace(value, "NA", "U"),
           value = str_replace(value, "Other", "O"),
           value = str_replace(value, "m/m", "U"),
           value = str_replace(value, "M", "U"),
           value = str_replace(value, "Unknown|Unknown ", "U"),
           value = str_replace(value, "U ", "U")) %>%
    count(id, value) %>%
    mutate(value = paste0("officerRace", value)) %>%
    filter(value != "officerRaceNA") %>%
    pivot_wider(names_from = value, values_from = n) %>%
    mutate(across(everything(), ~replace_na(.x, 0)))

viceClean <- viceClean %>% full_join(raceClean, by = "id")

# The number of officers in the fixedNrOfficers column does not always
# equal the number of officers summed across all the newly created race
# columns. This is because the number of races listed in OfficerGender does
# not always equal fixedNrOfficers. I leave as is for now. 443 mismatched records.

mismatchRace <-
    viceClean %>%
    select(officerRaceU, officerRaceW, officerRaceL, officerRaceB, officerRaceA,
           officerRaceO, OfficerRace, id, fixedNrOfficers) %>%
    rowwise() %>%
    mutate(newOfficerCount = sum(officerRaceU, officerRaceW, officerRaceL,
                                 officerRaceB, officerRaceA, officerRaceO)) %>%
    filter(newOfficerCount != fixedNrOfficers)

# Create final dataset and remove unnecessary columns
viceClean <-
    viceClean %>%
    select(-NumberOfSubjects, -id)

# Write out results
write_csv(viceClean, here("data_cleaning", "output", "vice-clean.csv"))
