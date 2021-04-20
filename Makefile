# Obtaining the data and cleaning it
data_cleaning/data/washpo.csv:
	wget -O $@ https://github.com/washingtonpost/data-police-shootings/releases/download/v0.1/fatal-police-shootings-data.csv

data_cleaning/output/washpo-clean.csv: data_cleaning/data/washpo.csv data_cleaning/src/clean-washpo.R
	Rscript data_cleaning/src/clean-washpo.R

data_cleaning/data/vice-incident.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/incident_data.csv

data_cleaning/data/vice-subject.csv:
	wget -O $@ https://raw.githubusercontent.com/vicenews/shot-by-cops/master/subject_data.csv

data_cleaning/output/vice-clean.csv: data_cleaning/data/vice-incident.csv data_cleaning/src/clean-vice.R
	Rscript data_cleaning/src/clean-vice.R

# Sym link the cleaned data to the folder for creating test and train AND then create test/train splits
create_test_train/data/washpo-clean.csv: data_cleaning/output/washpo-clean.csv
	cd create_test_train/data && ln -s ../../data_cleaning/output/washpo-clean.csv washpo-clean.csv

create_test_train/data/vice-clean.csv: data_cleaning/output/vice-clean.csv
	cd create_test_train/data && ln -s ../../data_cleaning/output/vice-clean.csv vice-clean.csv

create_test_train/output/raceTrain.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/raceTest.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/fatalTrain.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/fatalTest.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/raceTrainStd.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/raceTestStd.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/fatalTrainStd.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

create_test_train/output/fatalTestStd.RData: create_test_train/data/washpo-clean.csv create_test_train/data/vice-clean.csv create_test_train/src/create-test-train.R
	Rscript create_test_train/src/create-test-train.R

# Explore the train portion of our data
data_cleaning/output/washpo-explore.pdf: data_cleaning/src/washpo-explore.Rmd create_test_train/output/raceTrain.RData
	Rscript -e "Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio/bin/pandoc'); rmarkdown::render(here::here('data_cleaning', 'src', 'washpo-explore.Rmd'))"
	mv data_cleaning/src/washpo-explore.pdf data_cleaning/output/

data_cleaning/output/vice-explore.pdf: data_cleaning/src/vice-explore.Rmd create_test_train/output/raceTrain.RData create_test_train/output/fatalTrain.RData
	Rscript -e "Sys.setenv(RSTUDIO_PANDOC='/usr/lib/rstudio/bin/pandoc'); rmarkdown::render(here::here('data_cleaning', 'src', 'vice-explore.Rmd'))"
	mv data_cleaning/src/vice-explore.pdf data_cleaning/output/

# Sym link the test/train data to our hyperparameter tuning folder AND then create hyperparameter tunings
hyperparameter_tuning/data/raceTrainStd.RData: create_test_train/output/raceTrainStd.RData
	cd hyperparameter_tuning/data && ln -s ../../create_test_train/output/raceTrainStd.RData raceTrainStd.RData

hyperparameter_tuning/data/fatalTrainStd.RData: create_test_train/output/fatalTrainStd.RData
	cd hyperparameter_tuning/data && ln -s ../../create_test_train/output/fatalTrainStd.RData fatalTrainStd.RData

hyperparameter_tuning/output/tunedXgbs.RData: hyperparameter_tuning/src/tune_hyperparams.R hyperparameter_tuning/data/raceTrainStd.RData hyperparameter_tuning/data/fatalTrainStd.RData
	Rscript hyperparameter_tuning/src/tune_hyperparams.R

hyperparameter_tuning/output/tunedRfs.RData: hyperparameter_tuning/src/tune_hyperparams.R hyperparameter_tuning/data/raceTrainStd.RData hyperparameter_tuning/data/fatalTrainStd.RData
	Rscript hyperparameter_tuning/src/tune_hyperparams.R

hyperparameter_tuning/output/tunedSvms.RData: hyperparameter_tuning/src/tune_hyperparams.R hyperparameter_tuning/data/raceTrainStd.RData hyperparameter_tuning/data/fatalTrainStd.RData
	Rscript hyperparameter_tuning/src/tune_hyperparams.R

# Sym link the tuned hyperparameter data AND training/test data to our train and predict folder, then create our trained models and predictions
train_and_predict/data/tunedSvms.RData: hyperparameter_tuning/output/tunedSvms.RData
	cd train_and_predict/data && ln -s ../../hyperparameter_tuning/output/tunedSvms.RData tunedSvms.RData

train_and_predict/data/tunedRfs.RData: hyperparameter_tuning/output/tunedRfs.RData
	cd train_and_predict/data && ln -s ../../hyperparameter_tuning/output/tunedRfs.RData tunedRfs.RData

train_and_predict/data/tunedXgbs.RData: hyperparameter_tuning/output/tunedXgbs.RData
	cd train_and_predict/data && ln -s ../../hyperparameter_tuning/output/tunedXgbs.RData tunedXgbs.RData

train_and_predict/data/raceTrainStd.RData: create_test_train/output/raceTrainStd.RData
	cd train_and_predict/data && ln -s ../../create_test_train/output/raceTrainStd.RData raceTrainStd.RData

train_and_predict/data/fatalTrainStd.RData: create_test_train/output/fatalTrainStd.RData
	cd train_and_predict/data && ln -s ../../create_test_train/output/fatalTrainStd.RData fatalTrainStd.RData

train_and_predict/data/raceTestStd.RData: create_test_train/output/raceTestStd.RData
	cd train_and_predict/data && ln -s ../../create_test_train/output/raceTestStd.RData raceTestStd.RData

train_and_predict/data/fatalTestStd.RData: create_test_train/output/fatalTestStd.RData
	cd train_and_predict/data && ln -s ../../create_test_train/output/fatalTestStd.RData fatalTestStd.RData

train_and_predict/output/trainedSvms.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedSvms.RData
	Rscript train_and_predict/src/train_predict.R

train_and_predict/output/trainedRfs.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedRfs.RData
	Rscript train_and_predict/src/train_predict.R

train_and_predict/output/trainedXgbs.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedXgbs.RData
	Rscript train_and_predict/src/train_predict.R

train_and_predict/output/svmPredictions.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedSvms.RData
	Rscript train_and_predict/src/train_predict.R

train_and_predict/output/rfPredictions.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedRfs.RData
	Rscript train_and_predict/src/train_predict.R

train_and_predict/output/xgbPredictions.RData: train_and_predict/src/train_predict.R train_and_predict/data/tunedXgbs.RData
	Rscript train_and_predict/src/train_predict.R

# Sym link the trained models into the create graphs and figures so we can check the diagnostics and feature importance
# Sym link the predictions
# Sym link the test data to calculate naive accuracy
# Sym link the train data to create descriptive tables
create_graphs_tables/data/trainedRfs.RData: train_and_predict/output/trainedRfs.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/trainedRfs.RData trainedRfs.RData

create_graphs_tables/data/trainedXgbs.RData: train_and_predict/output/trainedXgbs.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/trainedXgbs.RData trainedXgbs.RData

create_graphs_tables/data/trainedXgbs.RData: train_and_predict/output/trainedXgbs.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/trainedXgbs.RData trainedXgbs.RData

create_graphs_tables/data/fatalTest.RData: create_test_train/output/fatalTest.RData
	cd create_graphs_tables/data && ln -s ../../create_test_train/output/fatalTest.RData fatalTest.RData

create_graphs_tables/data/raceTest.RData: create_test_train/output/raceTest.RData
	cd create_graphs_tables/data && ln -s ../../create_test_train/output/raceTest.RData raceTest.RData

create_graphs_tables/data/svmPredictions.RData: train_and_predict/output/svmPredictions.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/svmPredictions.RData svmPredictions.RData

create_graphs_tables/data/rfPredictions.RData: train_and_predict/output/rfPredictions.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/rfPredictions.RData rfPredictions.RData

create_graphs_tables/data/xgbPredictions.RData: train_and_predict/output/xgbPredictions.RData
	cd create_graphs_tables/data && ln -s ../../train_and_predict/output/xgbPredictions.RData xgbPredictions.RData

create_graphs_tables/data/raceTrain.RData: create_test_train/output/raceTrain.RData
	cd create_graphs_tables/data && ln -s ../../create_test_train/output/raceTrain.RData

create_graphs_tables/data/fatalTrain.RData: create_test_train/output/fatalTrain.RData
	cd create_graphs_tables/data && ln -s ../../create_test_train/output/fatalTrain.RData

################################################### create entry for creating plots and tables