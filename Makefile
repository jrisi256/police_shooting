data_cleaning/data/washpo.csv:
	wget -O $@ https://github.com/washingtonpost/data-police-shootings/releases/download/v0.1/fatal-police-shootings-data.csv

data_cleaning/output/washpo-clean.csv: data_cleaning/data/washpo.csv data_cleaning/src/clean-washpo.R
	Rscript data_cleaning/src/clean-washpo.R

data_cleaning/data/vice-incident.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/incident_data.csv

data_cleaning/data/vice-subject.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/subject_data.csv



data_cleaning/output/washpo-explore.pdf: data_cleaning/src/washpo-explore.Rmd data_cleaning/data/washpo.csv
	Rscript -e "Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio/bin/pandoc'); rmarkdown::render(here::here('data_cleaning', 'src', 'washpo-explore.Rmd'))"
	mv data_cleaning/src/washpo-explore.pdf data_cleaning/output/