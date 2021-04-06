data/washpo.csv:
	wget -O $@ https://github.com/washingtonpost/data-police-shootings/releases/download/v0.1/fatal-police-shootings-data.csv

data/vice-incident.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/incident_data.csv

data/vice-subject.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/subject_data.csv