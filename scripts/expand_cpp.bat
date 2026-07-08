@echo off
setlocal

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"

if "%~1"=="" (
    echo Usage: expand_cpp.bat path\to\file.cpp
    exit /b 1
)

REM source file
set "SRC=%~f1"
set "DIR=%~dp1"
set "EXT=%~x1"

REM repo root
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

REM libraries
set "CPLIB=%ROOT%\libraries\cpp\my_libraries\cp.hpp"
set "DEBUGLIB=%ROOT%\libraries\cpp\my_libraries\debug.cpp"
set "ACL=%ROOT%\ac-library"

REM temp + output
set "TMP=%DIR%solve_expand.cpp"
set "OUT=%DIR%submit.cpp"
set "LOG=%DIR%solve_expand.log"

if /i not "%EXT%"==".cpp" (
    echo [%ESC%[31mEXPAND FAILED%ESC%[0m] Unsupported file type: %EXT%
    exit /b 1
)

if not exist "%SRC%" (
    echo [%ESC%[31mEXPAND FAILED%ESC%[0m] File not found: %SRC%
    exit /b 1
)

if not exist "%CPLIB%" (
    echo [%ESC%[31mEXPAND FAILED%ESC%[0m] Missing library: %CPLIB%
    exit /b 1
)

if not exist "%DEBUGLIB%" (
    echo [%ESC%[31mEXPAND FAILED%ESC%[0m] Missing library: %DEBUGLIB%
    exit /b 1
)

if not exist "%ACL%\expander.py" (
    echo [%ESC%[31mEXPAND FAILED%ESC%[0m] Missing AtCoder Library expander: %ACL%\expander.py
    exit /b 1
)

REM concat header + source
(
    type "%DEBUGLIB%"
    echo.
    type "%CPLIB%"
    echo.
    type "%SRC%"
) > "%TMP%"
if errorlevel 1 goto failed

REM remove include + pragma once
findstr /v "my_libraries/cp.hpp" "%TMP%" | findstr /v "debug.cpp" | findstr /v "#pragma once" > "%TMP%.clean"
if errorlevel 1 goto failed
move /y "%TMP%.clean" "%TMP%" >nul
if errorlevel 1 goto failed

REM run ACL expander
cd /d "%ACL%"
python expander.py -c "%TMP%" > "%OUT%" 2> "%LOG%"
if errorlevel 1 goto failed

REM copy result to clipboard
type "%OUT%" | clip >nul
if errorlevel 1 goto failed

REM cleanup
del "%TMP%" >nul 2>nul
del "%LOG%" >nul 2>nul

echo [%ESC%[32mDONE%ESC%[0m] submit.cpp generated
endlocal
exit /b 0

:failed
del "%TMP%" >nul 2>nul
del "%TMP%.clean" >nul 2>nul
if exist "%LOG%" type "%LOG%"
del "%LOG%" >nul 2>nul
echo [%ESC%[31mEXPAND FAILED%ESC%[0m]
endlocal
exit /b 1
