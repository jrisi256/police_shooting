# Obtaining the data and cleaning it
data_cleaning/data/washpo.csv:
	wget -O $@ https://github.com/washingtonpost/data-police-shootings/releases/download/v0.1/fatal-police-shootings-data.csv

data_cleaning/output/washpo-clean.csv: data_cleaning/data/washpo.csv data_cleaning/src/clean-washpo.R
	Rscript data_cleaning/src/clean-washpo.R

data_cleaning/data/vice-incident.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/incident_data.csv

data_cleaning/data/vice-subject.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/subject_data.csv

data_cleaning/data/vice-clean.csv: data_cleaning/data/vice-incident.csv data_cleaning/src/clean-vice.R
	Rscript data_cleaning/src/clean-vice.R

# Sym link the cleaned data to the folder for creating test and train AND then create test/train splits
create_test_train/data/washpo-clean.csv: data_cleaning/output/washpo-clean.csv
	cd create_test_train/data && ln -sf ../../data_cleaning/output/washpo-clean.csv washpo-clean.csv

create_test_train/data/vice-clean.csv: data_cleaning/output/vice-clean.csv
	cd create_test_train/data && ln -sf ../../data_cleaning/output/vice-clean.csv vice-clean.csv

create_test_train/output/trainTestRace.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/trainTestFatal.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

# Explore the train portion of our data
data_cleaning/output/washpo-explore.pdf: data_cleaning/src/washpo-explore.Rmd create_test_train/output/trainTestRace.RData
	Rscript -e "Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio/bin/pandoc'); rmarkdown::render(here::here('data_cleaning', 'src', 'washpo-explore.Rmd'))"
	mv data_cleaning/src/washpo-explore.pdf data_cleaning/output/

data_cleaning/output/vice-explore.pdf: data_cleaning/src/vice-explore.Rmd create_test_train/output/trainTestRace.RData create_test_train/output/trainTestFatal.RData
	Rscript -e "Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio/bin/pandoc'); rmarkdown::render(here::here('data_cleaning', 'src', 'vice-explore.Rmd'))"
	mv data_cleaning/src/vice-explore.pdf data_cleaning/output/