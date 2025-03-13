@echo off
setlocal enabledelayedexpansion
set "filepath=%~dp0"

:: Read the content of file.txt
set "line="
for /f "delims=" %%i in (%filepath%\..\tempData\title.txt) do (
    set "line=%%i"
)

:: Extract the parts between the square brackets
for /f "tokens=2,4 delims=[]" %%a in ("!line!") do (
    set "part1=%%a"
    set "part2=%%b"
)

:: Trim any leading or trailing spaces
set "part1=!part1:~1,-1!"

:: Create the GAMS file with the desired content
echo SET scen_desc "Scenario description" /'!part2!' '!part1!'/; > %filepath%..\tempData\create_scen_desc_set.gms

echo GAMS file created successfully.
