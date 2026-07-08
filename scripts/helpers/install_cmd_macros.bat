@echo off
setlocal

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "MACROS=%ROOT%\cmd\cp_macros"

if not exist "%MACROS%" (
    echo Macro file not found: %MACROS%
    exit /b 1
)

if not defined CP_PYTHON (
    for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\helpers\find_python.ps1"`) do set "CP_PYTHON=%%P"
)

if not defined CP_PYTHON (
    echo Could not find a usable Python executable.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_SETUP_ROOT', '%ROOT%', 'User'); [Environment]::SetEnvironmentVariable('CP_PYTHON', '%CP_PYTHON%', 'User')"
if errorlevel 1 exit /b 1

set "CP_SETUP_ROOT=%ROOT%"
del "%ROOT%\cmd\cmd_macros.local.txt" >nul 2>nul

reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "doskey /macrofile=\"%MACROS%\"" /f >nul
if errorlevel 1 (
    echo Failed to update cmd AutoRun.
    exit /b 1
)

doskey /macrofile="%MACROS%"

echo Installed DOSKEY macros from:
echo %MACROS%
echo.
echo New cmd.exe windows will load them automatically.
exit /b 0
