@echo off
setlocal EnableDelayedExpansion

:: ===================================================
:: AUTOMATIC ADMIN ELEVATION & PATH FIX
:: ===================================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    cd /d "%~dp0"

:: ===================================================
:: CONFIGURATION PATHS
:: ===================================================
title FFXI 18-Box Alliance Control Center (User-Paced)
set "POL_DIR=C:\Program Files (x86)\PlayOnline\SquareEnix\PlayOnlineViewer\usr\all"

:: ===================================================
:: FIRST CHECK: USER MENU SCOPE SELECTION
:: ===================================================
:MAIN_MENU
cls
echo ===================================================
echo            FFXI ALLIANCE MULTIBOX ENGINE            
echo ===================================================
echo  [1] Launch Party 1 Only (Chars 01-06)
echo  [2] Launch Party 2 Only (Chars 07-12)
echo  [3] Launch Party 3 Only (Chars 13-18)
echo  [A] Launch FULL ALLIANCE (All 18 Characters)
echo  [C] Launch a CUSTOM list of accounts
echo ===================================================
choice /c 123AC /m "Select party scope layout: "
set scopeselection=%errorlevel%

set "queuelist="
if %scopeselection%==1 set "queuelist=01 02 03 04 05 06 " & goto RUN_QUEUE
if %scopeselection%==2 set "queuelist=07 08 09 10 11 12 " & goto RUN_QUEUE
if %scopeselection%==3 set "queuelist=13 14 15 16 17 18 " & goto RUN_QUEUE
if %scopeselection%==4 set "queuelist=01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 " & goto RUN_QUEUE
if %scopeselection%==5 goto BUILD_CUSTOM

echo Invalid selection.
timeout /t 3
exit

:: ===================================================
:: SECOND CHECK: INTERACTIVE ALLIANCE QUEUE BUILDER
:: ===================================================
:BUILD_CUSTOM
cls
echo ===================================================
echo             ALLIANCE CUSTOM QUEUE BUILDER          
echo ===================================================
echo  Select characters to queue up in execution order.
echo  Press [S] when your list is completely built to START.
echo ===================================================
echo  PARTY 1: [A]=01  [B]=02  [C]=03  [D]=04  [E]=05  [F]=06
echo  PARTY 2: [G]=07  [H]=08  [I]=09  [J]=10  [K]=11  [L]=12
echo  PARTY 3: [M]=13  [N]=14  [O]=15  [P]=16  [Q]=17  [R]=18
echo ===================================================

:CHOOSE_LOOP
choice /c ABCDEFGHIJKLMNOPQRS /m "Current Queue [ !queuelist! ] - Add next or [S]tart: "

if errorlevel 19 goto RUN_QUEUE
if errorlevel 18 set "queuelist=!queuelist!18 " & goto CHOOSE_LOOP
if errorlevel 17 set "queuelist=!queuelist!17 " & goto CHOOSE_LOOP
if errorlevel 16 set "queuelist=!queuelist!16 " & goto CHOOSE_LOOP
if errorlevel 15 set "queuelist=!queuelist!15 " & goto CHOOSE_LOOP
if errorlevel 14 set "queuelist=!queuelist!14 " & goto CHOOSE_LOOP
if errorlevel 13 set "queuelist=!queuelist!13 " & goto CHOOSE_LOOP
if errorlevel 12 set "queuelist=!queuelist!12 " & goto CHOOSE_LOOP
if errorlevel 11 set "queuelist=!queuelist!11 " & goto CHOOSE_LOOP
if errorlevel 10 set "queuelist=!queuelist!10 " & goto CHOOSE_LOOP
if errorlevel 9  set "queuelist=!queuelist!09 " & goto CHOOSE_LOOP
if errorlevel 8  set "queuelist=!queuelist!08 " & goto CHOOSE_LOOP
if errorlevel 7  set "queuelist=!queuelist!07 " & goto CHOOSE_LOOP
if errorlevel 6  set "queuelist=!queuelist!06 " & goto CHOOSE_LOOP
if errorlevel 5  set "queuelist=!queuelist!05 " & goto CHOOSE_LOOP
if errorlevel 4  set "queuelist=!queuelist!04 " & goto CHOOSE_LOOP
if errorlevel 3  set "queuelist=!queuelist!03 " & goto CHOOSE_LOOP
if errorlevel 2  set "queuelist=!queuelist!02 " & goto CHOOSE_LOOP
if errorlevel 1  set "queuelist=!queuelist!01 " & goto CHOOSE_LOOP
goto CHOOSE_LOOP

:: ==========================================
:: DYNAMIC PROCESSING ENGINE (STRING TAPE)
:: ==========================================
:RUN_QUEUE
if "%queuelist%"=="" goto END
echo.
echo Starting manual-paced alliance launch sequence...
set "LAST_FILE=0"

:PROCESS_QUEUE_STEP
if "!queuelist!"=="" goto END

set "current=!queuelist:~0,2!"

if "!current!"=="  " set "queuelist=!queuelist:~2!" & goto PROCESS_QUEUE_STEP
if "!current!"=="" goto END

echo ---------------------------------------------------
echo Processing Alliance Account Slot [!current!]...

set "NEED_FILE=1"
set "POL_INDEX=First"

if "!current!"=="01" set "NEED_FILE=1" & set "POL_INDEX=First"
if "!current!"=="02" set "NEED_FILE=1" & set "POL_INDEX=Second"
if "!current!"=="03" set "NEED_FILE=1" & set "POL_INDEX=Third"
if "!current!"=="04" set "NEED_FILE=2" & set "POL_INDEX=First"
if "!current!"=="05" set "NEED_FILE=2" & set "POL_INDEX=Second"
if "!current!"=="06" set "NEED_FILE=2" & set "POL_INDEX=Third"

if "!current!"=="07" set "NEED_FILE=3" & set "POL_INDEX=First"
if "!current!"=="08" set "NEED_FILE=3" & set "POL_INDEX=Second"
if "!current!"=="09" set "NEED_FILE=3" & set "POL_INDEX=Third"
if "!current!"=="10" set "NEED_FILE=4" & set "POL_INDEX=First"
if "!current!"=="11" set "NEED_FILE=4" & set "POL_INDEX=Second"
if "!current!"=="12" set "NEED_FILE=4" & set "POL_INDEX=Third"

if "!current!"=="13" set "NEED_FILE=5" & set "POL_INDEX=First"
if "!current!"=="14" set "NEED_FILE=5" & set "POL_INDEX=Second"
if "!current!"=="15" set "NEED_FILE=5" & set "POL_INDEX=Third"
if "!current!"=="16" set "NEED_FILE=6" & set "POL_INDEX=First"
if "!current!"=="17" set "NEED_FILE=6" & set "POL_INDEX=Second"
if "!current!"=="18" set "NEED_FILE=6" & set "POL_INDEX=Third"

:: CONDITIONAL SAFETY CHECK & FILE COPY PASS
if !LAST_FILE! EQU 0 (
    echo First initialization pass. Pushing profile group !NEED_FILE!...
    copy /y "%POL_DIR%\login_w.!NEED_FILE!.bin" "%POL_DIR%\login_w.bin" >nul
    timeout /t 4 /nobreak
    goto LAUNCH_CLIENT
)

if !LAST_FILE! EQU !NEED_FILE! (
    echo Profile match verified ^(login_w.!NEED_FILE!.bin already active^). Skipping profile write loop...
    goto LAUNCH_CLIENT
)

echo [!] Profile swap checkpoint detected ^(login_w.!LAST_FILE!.bin -^> login_w.!NEED_FILE!.bin^).
echo     Make sure the previous PlayOnline window has finished initializing.
pause
echo Pushing profile group !NEED_FILE! to PlayOnline...
copy /y "%POL_DIR%\login_w.!NEED_FILE!.bin" "%POL_DIR%\login_w.bin" >nul
timeout /t 4 /nobreak

:LAUNCH_CLIENT
set "LAST_FILE=!NEED_FILE!"
echo Launching Character Slot !current!...
start "" autoPOL.exe --character !POL_INDEX!

echo.
echo [CHECKPOINT] Character !current! initiated. 
echo Once this window is safely loaded to character selection or into the world, focus here...
pause

set "queuelist=!queuelist:~3!"
goto PROCESS_QUEUE_STEP

:: ==========================================
:: EXIT PROTOCOL
:: ==========================================
:END
echo.
echo Alliance launch operation completed successfully.
timeout /t 5
exit