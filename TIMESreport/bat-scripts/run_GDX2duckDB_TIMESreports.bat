@echo off
:main
echo Running your main tasks...
set "filepath=%~dp0"
cd "%filepath%.."
:: Set modelname used by the R script
Rscript -e "source('create_times_db_multiple_scenarios.R')"

::pause







