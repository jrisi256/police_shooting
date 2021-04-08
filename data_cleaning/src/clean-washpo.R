library(here)
library(readr)
library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)
library(lubridate)

# Read in data
washpo <- read_csv(here("data_cleaning", "data", "washpo.csv"))

# Create year, month, and day columns   
washpoClean <-
    washpo %>%
    mutate(year = year(date),
           month = month(date),
           day = day(date))

# Each armed category mentioned in less than 1% of cases gets recoded to other
armedNewDf <-
    washpoClean %>%
    count(armed) %>%
    mutate(prcnt = n / sum(n),
           armedNew = if_else(prcnt < 0.01, "other", armed))

washpoClean <-
    washpoClean %>%
    inner_join(select(armedNewDf, armed, armedNew), by = "armed")

# Write out cleaned dataset
write_csv(washpoClean, here("data_cleaning", "output", "washpo-clean.csv"))
