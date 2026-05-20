@echo off
setlocal enabledelayedexpansion

sow:: Use the passed working directory, or fall back to parent tempData
if "%~1"=="" (
    set "outdir=%~dp0..\tempData"
) else (
    set "outdir=%~1"
)

:: Read title.txt from the working directory
set "line="
for /f "usebackq delims=" %%i in ("%outdir%\title.txt") do (
    set "line=%%i"
)

:: Extract the parts between the square brackets
for /f "tokens=2,4 delims=[]" %%a in ("!line!") do (
    set "part1=%%a"
    set "part2=%%b"
)

:: Trim spaces from part1
set "part1=!part1:~1,-1!"

:: Trim trailing spaces from part2
for /f "tokens=*" %%x in ("!part2!") do set "part2=%%x"

:: Check if part2 contains a tilde (parametric scenario)
echo !part2! | findstr /C:"~" >nul
if !errorlevel! equ 0 (
    for /f "tokens=1,2 delims=~" %%x in ("!part2!") do (
        set "scen_name=%%x"
        set "sow_num=%%y"
    )
    set "sow_num=!sow_num: =!"
    echo SET scen_desc "Scenario description" /'!scen_name!' '!part1!'/; > "%outdir%\create_scen_desc_set.gms"
    echo SET sow "Parametric scenario number" /!sow_num!/; >> "%outdir%\create_scen_desc_set.gms"
) else (
    echo SET scen_desc "Scenario description" /'!part2!' '!part1!'/; > "%outdir%\create_scen_desc_set.gms"
)

echo GAMS file created successfully.
