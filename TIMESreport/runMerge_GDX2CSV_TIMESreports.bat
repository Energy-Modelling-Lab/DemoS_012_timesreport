@echo off
:: We want to set %pathMODEL% dynamically based on the directory where
:: the batch file is located, you can use the %~dp0 variable, which
:: represents the full path of the batch file.
set "pathMODEL=%~dp0"

:: Merge all sceanrio GDX files into a common GDX file containing all scenario results
gdxmerge.exe %pathMODEL%GDX\*_TIMESreport.gdx "OUTPUT=%pathMODEL%GDX\timesreport_compare.gdx"

:: Dump GDX as cvs-filen defining new heading
gdxdump  %pathMODEL%GDX\timesreport_compare.gdx format=csv symb=timesreport output=%pathMODEL%compare_timesreport.csv noHeader header=scenario,sector,topic,attr,process,commodity,timeslice,regionFrom,regionTo,year,vntg,units,currency,value

:: del %pathMODEL%timesreport_compare.gdx

::echo Closed >RunTerminated

:: pause
