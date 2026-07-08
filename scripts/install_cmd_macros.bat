@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "TEMPLATE=%ROOT%\cmd\cmd_macros.txt"
set "MACROS=%ROOT%\cmd\cmd_macros.local.txt"

if not exist "%TEMPLATE%" (
    echo Macro template not found: %TEMPLATE%
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$root = '%ROOT%'; (Get-Content -Raw -LiteralPath '%TEMPLATE%').Replace('__ROOT__', $root) | Set-Content -LiteralPath '%MACROS%' -NoNewline"
if errorlevel 1 (
    echo Failed to generate macro file.
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
