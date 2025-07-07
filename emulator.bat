@echo off

REM Set your emulator path here - modify this line if needed
set EMULATOR_CMD="C:\Users\mtmazurik\AppData\Local\Android\Sdk\emulator\emulator.exe"

echo Android Stable Device Emulator Launcher
echo 1. Device (GPU angle indirect)
echo 2. Device (GPU host) 
echo 3. Device (GPU Swiftshader indirect)
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto stable
if "%choice%"=="2" goto stable2
if "%choice%"=="3" goto swift

echo Invalid choice. Please enter 1, 2, or 3.
pause
goto end

:stable
echo Launching Stable (angle indirect) Device...
%EMULATOR_CMD% -avd stable_device -gpu angle_indirect -memory 1024
goto end

:stable2
echo Launching Stable Device (host)...
%EMULATOR_CMD% -avd stable_device -gpu host -memory 1024
goto end

:swift
echo Launching stable (gpu swiftshader indirect) Device...
%EMULATOR_CMD% -avd stable_device -gpu swiftshader_indirect -memory 1024
goto end

:end
pause