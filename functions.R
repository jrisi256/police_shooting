library(dplyr)

StandardizeData <- function(df, name) {
    
    ##### If the data frame we are dealing with comes from the Washington Post
    if(str_detect(name, "washpo")) {
        df <-
            df %>%
            mutate(manner_of_death = as.factor(manner_of_death),
                   age = as.numeric(age),
                   gender = as.factor(gender),
                   race = as.factor(race),
                   signs_of_mental_illness = as.factor(signs_of_mental_illness),
                   threat_level = as.factor(threat_level),
                   flee = as.factor(flee),
                   body_camera = as.factor(body_camera),
                   armedNew = as.factor(armedNew))
        
        ################# If we are using date and geography
        if(str_detect(name, "Dg")) {
            df <-
                df %>%
                mutate(state = as.factor(state),
                       year = as.factor(year),
                       month = as.factor(month),
                       day = as.factor(day))
        }
        
    ############ If the data frame we are dealing with comes from Vice
    } else if(str_detect(name, "vice|fatal")) {
        df <-
            df %>%
            mutate(Fatal = as.factor(Fatal),
                   SubjectArmed = as.factor(SubjectArmed),
                   SubjectRace = as.factor(SubjectRace),
                   SubjectGender = as.factor(SubjectGender),
                   SubjectAge = as.factor(SubjectAge),
                   fixedNrOfficers = as.numeric(fixedNrOfficers),
                   situation = as.factor(situation),
                   officerGenderM = as.numeric(officerGenderM),
                   officerGenderF = as.numeric(officerGenderF),
                   officerGenderU = as.numeric(officerGenderU),
                   officerRaceW = as.numeric(officerRaceW),
                   officerRaceL = as.numeric(officerRaceL),
                   officerRaceU = as.numeric(officerRaceU),
                   officerRaceB = as.numeric(officerRaceB),
                   officerRaceA = as.numeric(officerRaceA),
                   officerRaceO = as.numeric(officerRaceO))
        
        ################### If we are using date and geography
        if(str_detect(name, "DgBNm|DgHNm|fatalBNm|fatalHNm")) {
            df <-
                df %>%
                mutate(departmentFixed = as.factor(departmentFixed),
                       year = as.factor(year),
                       month = as.factor(month),
                       day = as.factor(day))
            
            ######### If we are using missing data, we have a new column
            if(str_detect(name, "M")) {
                df <-
                    df %>%
                    mutate(fixedNrShots = as.numeric(fixedNrShots))
            }
        }
    }
    
    return(df)
}
