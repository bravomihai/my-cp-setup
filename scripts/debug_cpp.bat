@echo off
setlocal

set "SRC=%~1"
set "DIR=%~dp1"
set "NAME=%~n1"

cd /d "%DIR%"

echo Compiling with debug symbols...
g++ -std=c++20 -g "%SRC%" -o "%NAME%.exe"

if errorlevel 1 (
    echo Compile failed
    pause
    exit /b 1
)

echo.
echo Starting gdb...
echo.

gdb "%NAME%.exe"

endlocal