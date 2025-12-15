@echo off
:: We want to set %pathMODEL% dynamically based on the directory where
:: the batch file is located, you can use the %~dp0 variable, which
:: represents the full path of the batch file.
set "filepath=%~dp0"

:: Merge all sceanrio GDX files into a common GDX file containing all scenario results
gdxmerge.exe %filepath%..\GDX\*_TIMESreport.gdx "OUTPUT=%filepath%..\GDX\compare_timesreport.gdx"

:: Dump GDX as cvs-filen defining new headin
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=timesreport     output=%filepath%..\compare_timesreport.csv noHeader header=filename,scen,sector,subsector,service,techgroup,comgroup,topic,attr,prc,com,timeslice,regionFrom,regionTo,year,vntg,units,cur,value
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=scen_desc       output=%filepath%..\compare_scen_desc.csv      CSVSetText  noHeader header=filename,scen,scen_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=prc_desc        output=%filepath%..\compare_prc_desc.csv       CSVSetText  noHeader header=filename,region,prc,prc_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=com_desc        output=%filepath%..\compare_com_desc.csv       CSVSetText  noHeader header=filename,region,com,com_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=sector_desc     output=%filepath%..\compare_sector_desc.csv    CSVSetText  noHeader header=filename,sector,sector_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=service_desc    output=%filepath%..\compare_service_desc.csv   CSVSetText  noHeader header=filename,service,service_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=subsector_desc  output=%filepath%..\compare_subsector_desc.csv CSVSetText  noHeader header=filename,subsector,subsector_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=techgroup_desc  output=%filepath%..\compare_techgroup_desc.csv CSVSetText  noHeader header=filename,techgroup,techgroup_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=comgroup_desc   output=%filepath%..\compare_comgroup_desc.csv  CSVSetText  noHeader header=filename,comgroup,comgroup_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=attr_desc       output=%filepath%..\compare_attr_desc.csv      CSVSetText  noHeader header=filename,attr,attr_desc
gdxdump   %filepath%..\GDX\compare_timesreport.gdx format=csv symb=topic_desc      output=%filepath%..\compare_topic_desc.csv     CSVSetText  noHeader header=filename,topic,topic_desc


del %filepath%..\GDX\compare_timesreport.gdx

::echo Closed >RunTerminated

:: pause
