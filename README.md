*===========================================================================================
*  Copyright (C) 2024 Kristoffer S. Andersen (kristoffer@energymodellinglab.com)
*                Energy modelling lab (https://energymodellinglab.com/).
*
*  This software is  open source: you can redistribute it and/or modify it
*  under the terms of the GNU General Public License v3.0 (see file NOTICE-GPLv3.txt).
*  For further information, visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
*
*  This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*==========================================================================================

This repo represents work in progress related to developing a generic gams script for reporting results from a TIMES model in a long form  (i.e., pivot ready format). 
The repo is based on the TIMES DemoS_012 model accompaing VEDA. The demo model has been extend by adding the following files: 

#1. \TIMESreport\timesreport.gms
GAMS script which collects data from TIMES gdx output file into a pivot ready format

#2. Sets-DemoModels.xlsx (updated)
Updated to include process and commodity group set used for reporting in #1

#3. SysSettings.xlsx (updated)
Updated to include definition to include ~TFM_COMGRP, which creates COM_GMAP set description into the raw gdx TIMES output file.

#4. Scen_Z_TIMESReport.xlsx (updated)
Creates PRC_GMAP and writes process and commodity group set description into the raw gdx TIMES output file
Scenario file is used to run the GAMS script automatically after solving the TIMES model

#5. \TIMESreport\runMerge_GDX2CSV_TIMESreports.bat
File that merges TIMESreport gdx files across different scenario runs and outputs a CSV files 

#6. \TIMESreport\TIMESreport_DemoS_012.xlsx
Excel file which based on the csv-file from #5 shows results from TIMES using pivot tables.

Additional documentation of the scripts will be added on an ongoing basis. If you have commments or suggestions please let me know.

Best regards,

Kristoffer


