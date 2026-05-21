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
title FFXI 6-Box Control Center (User-Paced)
set "POL_DIR=C:\Program Files (x86)\PlayOnline\SquareEnix\PlayOnlineViewer\usr\all"

:: ===================================================
:: USER MENU PROMPT
:: ===================================================
cls
echo ===================================================
echo             FFXI MULTIBOX CONTROL CENTER          
echo ===================================================
echo  [1] Launch Account 1
echo  [2] Launch Account 2
echo  [3] Launch Account 3
echo  [4] Launch Account 4
echo  [5] Launch Account 5
echo  [6] Launch Account 6
echo  [A] Launch FULL TEAM (Sequential)
echo  [C] Launch a CUSTOM list of accounts
echo ===================================================
choice /c 123456AC /m "Select loading routine: "
set selection=%errorlevel%

set "queuelist="
if %selection%==1 set "queuelist=1 " & goto RUN_QUEUE
if %selection%==2 set "queuelist=2 " & goto RUN_QUEUE
if %selection%==3 set "queuelist=3 " & goto RUN_QUEUE
if %selection%==4 set "queuelist=4 " & goto RUN_QUEUE
if %selection%==5 set "queuelist=5 " & goto RUN_QUEUE
if %selection%==6 set "queuelist=6 " & goto RUN_QUEUE
if %selection%==7 set "queuelist=1 2 3 4 5 6 " & goto RUN_QUEUE
if %selection%==8 goto BUILD_CUSTOM

echo Invalid selection.
timeout /t 3
exit

:: ===================================================
:: INTERACTIVE TEAM QUEUE BUILDER
:: ===================================================
:BUILD_CUSTOM
cls
echo ===================================================
echo               CUSTOM TEAM QUEUE BUILDER            
echo ===================================================
echo  Select characters to queue up in execution order.
echo  Press [S] when your list is completely built to START.
echo ===================================================
echo  [1]=Char 1  [2]=Char 2  [3]=Char 3  [4]=Char 4  [5]=Char 5  [6]=Char 6
echo ===================================================
:CHOOSE_LOOP
choice /c 123456S /m "Current Queue [ !queuelist! ] - Add next or [S]tart: "
set "keystroke=%errorlevel%"

if %keystroke%==7 goto RUN_QUEUE
if %keystroke%==1 set "queuelist=%queuelist%1 "
if %keystroke%==2 set "queuelist=%queuelist%2 "
if %keystroke%==3 set "queuelist=%queuelist%3 "
if %keystroke%==4 set "queuelist=%queuelist%4 "
if %keystroke%==5 set "queuelist=%queuelist%5 "
if %keystroke%==6 set "queuelist=%queuelist%6 "
goto CHOOSE_LOOP

:: ==========================================
:: DYNAMIC PROCESSING ENGINE (STRING TAPE)
:: ==========================================
:RUN_QUEUE
if "%queuelist%"=="" goto END
echo.
echo Starting manual-paced team launch sequence...
set "LAST_FILE=0"

:PROCESS_QUEUE_STEP
if "!queuelist!"=="" goto END
set "current=!queuelist:~0,1!"

if "!current!"==" " set "queuelist=!queuelist:~1!" & goto PROCESS_QUEUE_STEP
if "!current!"=="" goto END

echo ---------------------------------------------------
echo Processing Team Account Slot [!current!]...

set "NEED_FILE=1"
set "POL_INDEX=First"

if "!current!"=="1" set "NEED_FILE=1" & set "POL_INDEX=First"
if "!current!"=="2" set "NEED_FILE=1" & set "POL_INDEX=Second"
if "!current!"=="3" set "NEED_FILE=1" & set "POL_INDEX=Third"
if "!current!"=="4" set "NEED_FILE=1" & set "POL_INDEX=Fourth"
if "!current!"=="5" set "NEED_FILE=2" & set "POL_INDEX=First"
if "!current!"=="6" set "NEED_FILE=2" & set "POL_INDEX=Second"

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
echo Once this character is safely logged in, focus this window...
pause

set "queuelist=!queuelist:~2!"
goto PROCESS_QUEUE_STEP

:END
echo.
echo Launch operation completed successfully.
timeout /t 5
exit