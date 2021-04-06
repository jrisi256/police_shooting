library(here)
library(readr)

# Read in the data
washpo <- read_csv(here("data", "washpo.csv"))
vice_subject <- read_csv(here("data", "vice-subject.csv"),
                         col_types = cols(NumberOfOfficers = "c"))
vice_incident <- read_csv(here("data", "vice-incident.csv"),
                          col_types = cols(NumberOfOfficers = "c"))
