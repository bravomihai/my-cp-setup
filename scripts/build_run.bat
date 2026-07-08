@echo off
setlocal EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"

if "%~1"=="" (
    echo Usage: build_run.bat path\to\file.cpp^|file.java^|file.py
    echo Compiles when needed and runs using debug\input.txt, input.txt, or stdin.
    exit /b 1
)

if /i "%~1"=="__run" (
    set "SRC=%~f2"
) else (
    set "SRC=%~f1"
)

set "DIR=%~dp1"
set "NAME=%~n1"
set "EXT=%~x1"
if /i "%~1"=="__run" (
    set "DIR=%~dp2"
    set "NAME=%~n2"
    set "EXT=%~x2"
)

for %%I in ("%~dp0..") do set "ROOT=%%~fI"

if not exist "%SRC%" (
    echo File not found: %SRC%
    exit /b 1
)

if /i not "%EXT%"==".cpp" if /i not "%EXT%"==".java" if /i not "%EXT%"==".py" (
    echo Unsupported file type: %EXT%
    echo Supported: .cpp, .java, .py
    exit /b 1
)

if /i not "%~1"=="__run" (
    start "" cmd /c call "%~f0" __run "%SRC%" ^& echo. ^& echo Press any key to exit... ^& pause ^>nul
    exit /b 0
)

set "INPUT="
if exist "%DIR%debug\input.txt" (
    set "INPUT=%DIR%debug\input.txt"
) else if exist "%DIR%input.txt" (
    set "INPUT=%DIR%input.txt"
)

cd /d "%DIR%"

if /i "%EXT%"==".cpp" (
    g++ -std=c++20 -O2 -I"%ROOT%\libraries\cpp" -I"%ROOT%\ac-library" "%SRC%" -o "%DIR%%NAME%.exe"
    if errorlevel 1 goto compile_failed
    if defined INPUT (
        "%DIR%%NAME%.exe" < "%INPUT%"
    ) else (
        "%DIR%%NAME%.exe"
    )
    if errorlevel 1 goto run_failed
    goto done
)

if /i "%EXT%"==".java" (
    set "JAVABUILD=%TEMP%\cp_java_%RANDOM%_%RANDOM%"
    mkdir "!JAVABUILD!" >nul 2>nul
    javac -encoding UTF-8 -cp "%ROOT%\libraries\java;%DIR%." -sourcepath "%ROOT%\libraries\java;%DIR%." -d "!JAVABUILD!" "%SRC%"
    if errorlevel 1 goto compile_failed
    if defined INPUT (
        java -cp "!JAVABUILD!;%ROOT%\libraries\java" "%NAME%" < "%INPUT%"
    ) else (
        java -cp "!JAVABUILD!;%ROOT%\libraries\java" "%NAME%"
    )
    set "RUNERR=%ERRORLEVEL%"
    rmdir /s /q "!JAVABUILD!" >nul 2>nul
    if not "!RUNERR!"=="0" goto run_failed
    goto done
)

if /i "%EXT%"==".py" (
    set "PYTHONPATH=%ROOT%\libraries\python;%PYTHONPATH%"
    if defined INPUT (
        python "%SRC%" < "%INPUT%"
    ) else (
        python "%SRC%"
    )
    if errorlevel 1 goto run_failed
    goto done
)

:compile_failed
echo [%ESC%[31mCOMPILE FAILED%ESC%[0m]
exit /b 1

:run_failed
echo [%ESC%[31mFAILED%ESC%[0m]
exit /b 1

:done
echo [%ESC%[32mDONE%ESC%[0m]
exit /b 0
