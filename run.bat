@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: World-Class Windows Restart Scheduler
:: Version: 2.0 (2026)
:: Features: Auto-Elevation, Task Scheduler Integration, Logging, Validation
:: ==============================================================================

:: Configuration
set "TASK_NAME=WorldClassSystemRestart"
set "LOG_FILE=%~dp0RestartScheduler.log"
set "SCRIPT_VERSION=2.0"

:: Ensure we are in the correct directory
pushd "%~dp0"

:: ------------------------------------------------------------------------------
:: 1. ADMINISTRATIVE PRIVILEGE CHECK & AUTO-ELEVATION
:: ------------------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ------------------------------------------------------------------------------
:: 2. INITIALIZATION & UI SETUP
:: ------------------------------------------------------------------------------
title World-Class Restart Scheduler v%SCRIPT_VERSION%
color 0B

:MAIN_MENU
cls
echo ================================================================================
echo                      WORLD-CLASS RESTART SCHEDULER v%SCRIPT_VERSION%
echo ================================================================================
echo.
echo  [1] Schedule Restart at Specific Time (e.g., 03:00 AM)
echo  [2] Schedule Restart After Delay (e.g., 60 minutes)
echo  [3] View Scheduled Restart Status
echo  [4] Cancel ALL Pending Restarts
echo  [5] View Activity Log
echo  [6] Exit
echo.
echo ================================================================================
echo.

choice /C 123456 /N /M "Select an option [1-6]: "
if errorlevel 6 goto EXIT_SCRIPT
if errorlevel 5 goto VIEW_LOG
if errorlevel 4 goto CANCEL_RESTART
if errorlevel 3 goto VIEW_STATUS
if errorlevel 2 goto SCHEDULE_DELAY
if errorlevel 1 goto SCHEDULE_TIME

:: ------------------------------------------------------------------------------
:: 3. SUBROUTINES
:: ------------------------------------------------------------------------------

:SCHEDULE_TIME
cls
echo ================================================================================
echo                      SCHEDULE RESTART AT SPECIFIC TIME
echo ================================================================================
echo.
echo  Enter the time in 24-hour format (HH:MM). 
echo  Example: 02:30 for 2:30 AM, or 14:30 for 2:30 PM.
echo.
set /p "TARGET_TIME=Enter time (HH:MM): "

:: Validate Time Format (00:00 to 23:59)
echo !TARGET_TIME! | findstr /R "^([01][0-9]|2[0-3]):[0-5][0-9]$" >nul
if !errorlevel! neq 0 (
    echo.
    echo  [ERROR] Invalid time format. Please use HH:MM (24-hour format).
    pause
    goto MAIN_MENU
)

:: Create the Scheduled Task
echo.
echo  [*] Creating scheduled task for !TARGET_TIME! ...
schtasks /create /tn "%TASK_NAME%" /tr "shutdown.exe /r /f /t 60 /c \"System restart initiated by World-Class Scheduler. Please save your work.\"" /sc once /st !TARGET_TIME! /ru "System" /f >nul 2>&1

if !errorlevel! equ 0 (
    call :LOG "SUCCESS: Scheduled restart at !TARGET_TIME!"
    echo.
    echo  [SUCCESS] Restart successfully scheduled for !TARGET_TIME!
    echo  The system will restart even if this window is closed.
) else (
    call :LOG "ERROR: Failed to schedule task at !TARGET_TIME!"
    echo.
    echo  [ERROR] Failed to create scheduled task. Check permissions.
)
pause
goto MAIN_MENU

:SCHEDULE_DELAY
cls
echo ================================================================================
echo                      SCHEDULE RESTART AFTER DELAY
echo ================================================================================
echo.
set /p "DELAY_MINS=Enter delay in minutes: "

:: Validate numeric input
echo !DELAY_MINS! | findstr /R "^[0-9][0-9]*$" >nul
if !errorlevel! neq 0 (
    echo.
    echo  [ERROR] Invalid input. Please enter a whole number.
    pause
    goto MAIN_MENU
)

set /a DELAY_SECS=!DELAY_MINS! * 60

echo.
echo  [*] Initiating shutdown countdown for !DELAY_MINS! minutes...
shutdown /r /f /t !DELAY_SECS! /c "Delayed restart initiated by World-Class Scheduler." >nul 2>&1

if !errorlevel! equ 0 (
    call :LOG "SUCCESS: Scheduled delayed restart in !DELAY_MINS! minutes (!DELAY_SECS! seconds)."
    echo.
    echo  [SUCCESS] Restart scheduled in !DELAY_MINS! minutes.
    echo  A Windows notification will appear 5 minutes before restart.
) else (
    call :LOG "ERROR: Failed to initiate delayed restart."
    echo.
    echo  [ERROR] Failed to schedule delayed restart.
)
pause
goto MAIN_MENU

:VIEW_STATUS
cls
echo ================================================================================
echo                      CURRENT RESTART STATUS
echo ================================================================================
echo.
echo  --- Task Scheduler Status ---
schtasks /query /tn "%TASK_NAME%" /fo LIST 2>nul
if !errorlevel! neq 0 echo  [INFO] No scheduled task named "%TASK_NAME%" found.

echo.
echo  --- Active Shutdown Countdown ---
:: Check if a shutdown is currently pending by looking for shutdown.exe in tasklist with /r flag
tasklist /fi "imagename eq shutdown.exe" 2>nul | find /i "shutdown.exe" >nul
if !errorlevel! equ 0 (
    echo  [WARNING] A Windows shutdown/restart countdown is currently ACTIVE.
) else (
    echo  [INFO] No active Windows shutdown countdown detected.
)
echo.
pause
goto MAIN_MENU

:CANCEL_RESTART
cls
echo ================================================================================
echo                      CANCEL PENDING RESTARTS
echo ================================================================================
echo.
echo  [*] Attempting to cancel all pending restarts...
echo.

:: 1. Cancel Task Scheduler task
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo  [OK] Task Scheduler job "%TASK_NAME%" deleted.
    call :LOG "SUCCESS: Cancelled scheduled task."
) else (
    echo  [INFO] No Task Scheduler job "%TASK_NAME%" found to delete.
)

:: 2. Abort any active shutdown countdown
shutdown /a >nul 2>&1
if !errorlevel! equ 0 (
    echo  [OK] Active Windows shutdown countdown aborted.
    call :LOG "SUCCESS: Aborted active shutdown countdown."
) else (
    echo  [INFO] No active shutdown countdown was running.
)

echo.
echo  [SUCCESS] All pending restarts have been cancelled.
pause
goto MAIN_MENU

:VIEW_LOG
cls
echo ================================================================================
echo                      ACTIVITY LOG
echo ================================================================================
echo.
if exist "%LOG_FILE%" (
    type "%LOG_FILE%"
) else (
    echo  [INFO] No log file found yet.
)
echo.
echo ================================================================================
pause
goto MAIN_MENU

:LOG
:: Subroutine to write timestamped entries to the log file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "LOG_DATE=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%"
set "LOG_TIME=%datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%"
echo [%LOG_DATE% %LOG_TIME%] %* >> "%LOG_FILE%"
goto :eof

:EXIT_SCRIPT
cls
echo ================================================================================
echo  Thank you for using the World-Class Restart Scheduler.
echo  System is now safe to close.
echo ================================================================================
timeout /t 2 >nul
exit /b
