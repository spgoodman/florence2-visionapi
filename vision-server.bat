@echo off
setlocal enabledelayedexpansion

REM vision-server.bat
REM
REM Usage: vision-server.bat [--host <host>] [--port <port>]
REM Example: vision-server.bat --host localhost --port 54880
REM Example (with default values): vision-server.bat
REM
REM Author: Steve Goodman (spgoodman)
REM Date: 2024-10-07
REM License: MIT
REM
REM This script is used to start the vision-server.py script with optional host and port arguments.
REM If a virtual environment is not found, it will create one and install the required packages.

cd /d "%~dp0"

if not exist ".venv" (
    echo No virtual environment found. Press any key to create virtual environment and attempt install of requirements or CTRL+C to exit.
    pause > nul
    python -m venv .venv
    if errorlevel 1 goto :error
    call .venv\Scripts\activate.bat
    if errorlevel 1 goto :error
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124
    if errorlevel 1 goto :error
    pip install -r requirements.txt
    if errorlevel 1 goto :error
) else (
    call .venv\Scripts\activate.bat
    if errorlevel 1 goto :error
)

python vision-server.py %*
if errorlevel 1 goto :error

echo.
echo Server has stopped. Press any key to exit.
pause > nul
exit /b 0

:error
echo.
echo An error occurred. Press any key to exit.
pause > nul
exit /b 1