@echo off
setlocal EnableExtensions

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "CHECK_ONLY=0"
if /i "%~1"=="--check" set "CHECK_ONLY=1"

echo CP setup root:
echo %ROOT%
echo.

call :need_or_install git Git.Git "Git"
if errorlevel 1 goto failed
call :need_or_install nvim Neovim.Neovim "Neovim"
if errorlevel 1 goto failed
call :need_or_install python Python.Python.3.12 "Python 3"
if errorlevel 1 goto failed
call :need_or_install javac EclipseAdoptium.Temurin.21.JDK "JDK"
if errorlevel 1 goto failed

where g++ >nul 2>nul
if not errorlevel 1 (
    echo [%ESC%[32mOK%ESC%[0m] g++ found
) else (
    echo [%ESC%[33mMISSING%ESC%[0m] g++
    if "%CHECK_ONLY%"=="0" (
        where winget >nul 2>nul
        if errorlevel 1 (
            echo [%ESC%[31mFAILED%ESC%[0m] winget is required to install MSYS2 automatically.
            goto failed
        )
        winget install --id MSYS2.MSYS2 --exact --accept-package-agreements --accept-source-agreements
        if errorlevel 1 goto failed
        powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\install_msys2_toolchain.ps1"
        if errorlevel 1 goto failed
    )
)

if "%CHECK_ONLY%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\install_paths.ps1" -Root "%ROOT%" -Check
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\install_paths.ps1" -Root "%ROOT%"
)
if errorlevel 1 goto failed
call :refresh_path

if "%CHECK_ONLY%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', '%ROOT%', 'User')"
    if errorlevel 1 goto failed

    call "%ROOT%\scripts\install_cmd_macros.bat"
    if errorlevel 1 goto failed
) else (
    echo [CHECK] Skipping environment writes and DOSKEY install.
)

if exist "%ROOT%\.git" (
    git -C "%ROOT%" submodule update --init ac-library
    if errorlevel 1 goto failed
)

call :verify
if errorlevel 1 goto failed

echo.
echo [%ESC%[32mDONE%ESC%[0m] CP setup is ready.
echo Restart terminals so updated User PATH and XDG_CONFIG_HOME are visible everywhere.
exit /b 0

:need_or_install
where "%~1" >nul 2>nul
if not errorlevel 1 (
    echo [%ESC%[32mOK%ESC%[0m] %~3 found
    exit /b 0
)

echo [%ESC%[33mMISSING%ESC%[0m] %~3
if "%CHECK_ONLY%"=="1" exit /b 0

where winget >nul 2>nul
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] winget is required to install %~3 automatically.
    exit /b 1
)

winget install --id %~2 --exact --accept-package-agreements --accept-source-agreements
exit /b %ERRORLEVEL%

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:verify
call :refresh_path
where git >nul 2>nul || exit /b 1
where nvim >nul 2>nul || exit /b 1
where python >nul 2>nul || exit /b 1
where javac >nul 2>nul || exit /b 1
where g++ >nul 2>nul || exit /b 1

python "%ROOT%\scripts\run.py" "%ROOT%\template\cpp\solve.cpp" >nul 2>nul
if errorlevel 1 exit /b 1
python "%ROOT%\scripts\run.py" "%ROOT%\template\java\solve.java" >nul 2>nul
if errorlevel 1 exit /b 1
python "%ROOT%\scripts\run.py" "%ROOT%\template\python\solve.py" >nul 2>nul
if errorlevel 1 exit /b 1
python "%ROOT%\scripts\expand.py" "%ROOT%\template\cpp\solve.cpp" >nul 2>nul
if errorlevel 1 exit /b 1
python "%ROOT%\scripts\expand.py" "%ROOT%\template\java\solve.java" >nul 2>nul
if errorlevel 1 exit /b 1
python "%ROOT%\scripts\expand.py" "%ROOT%\template\python\solve.py" >nul 2>nul
if errorlevel 1 exit /b 1
g++ -std=c++20 -O2 "%ROOT%\template\cpp\submit.cpp" -o "%TEMP%\cp_submit_test.exe"
if errorlevel 1 exit /b 1
javac -encoding UTF-8 -d "%TEMP%" "%ROOT%\template\java\submit.java"
if errorlevel 1 exit /b 1
python -c "import ast, pathlib; ast.parse(pathlib.Path(r'%ROOT%\template\python\submit.py').read_text())"
if errorlevel 1 exit /b 1

del "%ROOT%\template\cpp\submit.cpp" >nul 2>nul
del "%ROOT%\template\java\submit.java" >nul 2>nul
del "%ROOT%\template\python\submit.py" >nul 2>nul
del "%ROOT%\template\cpp\solve.exe" >nul 2>nul
del "%ROOT%\template\java\solve.class" >nul 2>nul
del "%TEMP%\solve.class" >nul 2>nul
del "%TEMP%\Cp.class" >nul 2>nul
del "%TEMP%\Cp$FastScanner.class" >nul 2>nul
del "%TEMP%\Cp$Timer.class" >nul 2>nul
del "%TEMP%\cp_submit_test.exe" >nul 2>nul
if exist "%ROOT%\libraries\python\my_libraries\__pycache__" rmdir /s /q "%ROOT%\libraries\python\my_libraries\__pycache__"
if exist "%ROOT%\template\python\__pycache__" rmdir /s /q "%ROOT%\template\python\__pycache__"

if exist "%ROOT%\.git" (
    git -C "%ROOT%" submodule status >nul
    if errorlevel 1 exit /b 1
)

echo [%ESC%[32mOK%ESC%[0m] Verification passed
exit /b 0

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup install did not complete.
exit /b 1
