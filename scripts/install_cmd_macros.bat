@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "MACROS=%ROOT%\cmd\cmd_macros.txt"

if not exist "%MACROS%" (
    echo Macro file not found: %MACROS%
    exit /b 1
)

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
