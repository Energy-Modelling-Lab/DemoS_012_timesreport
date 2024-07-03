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

#1. \TIMESreport\timesreport_DemoS_012.gms
GAMS script which collects data from TIMES gdx output file into a pivot ready format

#2. Sets-DemoModels.xlsx (updated)
Updated to include process group set used for reporting in #1

#3. \SuppXLS\Scen_Z_PRC_GMAP2GDX_WRITE.xlsx
Scenario file that ensure that process group set from #2 are included in TIMES-GDX output gdx file

#4. \SuppXLS\Scen_Z_TIMESReport.xlsx
Scenario file is used to run the GAMS script automatically after solving the TIMES model

#5. \TIMESreport\runMerge_GDX2CSV_TIMESreports.bat
File that merges TIMESreport gdx files across different scenario runs and outputs a CSV files 

#6. \TIMESreport\TIMESreport_DemoS_012.xlsx
Excel file which based on the csv-file from #5 shows results from TIMES using pivot tables.

#7. Finally the case definitions in the demo_model has been updated to include #3 and #4. 

Additional documentation of the scripts will be added asap. If you have commments or suggestions please let me know.

Best regards,

Kristoffer


