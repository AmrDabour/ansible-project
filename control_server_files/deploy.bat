@echo off
REM Simple Note App Ansible Deployment Script for Windows
REM This script provides easy deployment from Windows environments using WSL or Git Bash

setlocal EnableDelayedExpansion

echo.
echo ========================================
echo  Simple Note App Ansible Deployment
echo ========================================
echo.

REM Check if we're running in a Unix-like environment
where bash >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: bash is not available in PATH
    echo.
    echo Please install one of the following:
    echo  1. Windows Subsystem for Linux (WSL)
    echo  2. Git Bash
    echo  3. Cygwin
    echo.
    echo Or run this from the Ansible controller server directly.
    pause
    exit /b 1
)

REM Get the command line arguments
set "ARGS="
:loop
if "%~1"=="" goto :continue
set "ARGS=!ARGS! %~1"
shift
goto :loop
:continue

REM Run the bash script with the arguments
echo Running: bash deploy.sh !ARGS!
echo.
bash deploy.sh !ARGS!

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo  Deployment completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo  Deployment failed! Check the output above.
    echo ========================================
)

echo.
pause 