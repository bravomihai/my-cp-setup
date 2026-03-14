@echo off

set "SRC=%~1"
set "DIR=%~dp1"
set "NAME=%~n1"

g++ -std=c++20 -O2 "%SRC%" -o "%DIR%%NAME%.exe"

if errorlevel 1 (
    echo Compile failed
    pause
    exit /b 1
)

if exist "%DIR%debug\input.txt" (
    start "" cmd /c "cd /d %DIR% && %NAME%.exe < debug\input.txt  & pause"
) else if exist "%DIR%input.txt" (
    start "" cmd /c "cd /d %DIR% && %NAME%.exe < input.txt & pause"
) else (
    start "" cmd /c "cd /d %DIR% && %NAME%.exe & echo pause"
)