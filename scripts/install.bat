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
call :need_or_install javac EclipseAdoptium.Temurin.21.JDK "JDK"
if errorlevel 1 goto failed

where g++ >nul 2>nul
if not errorlevel 1 (
    echo [%ESC%[32mOK%ESC%[0m] g++ found
) else (
    echo [%ESC%[33mMISSING%ESC%[0m] g++
    if "%CHECK_ONLY%"=="0" (
        call :install_msys2_toolchain
        if errorlevel 1 goto failed
    )
)

if "%CHECK_ONLY%"=="1" (
    call :install_paths check
) else (
    call :install_paths
)
if errorlevel 1 goto failed
call :refresh_path

call :find_python
if errorlevel 1 (
    echo [%ESC%[33mMISSING%ESC%[0m] Python 3
    if "%CHECK_ONLY%"=="1" goto failed

    call :install_msys2_toolchain
    if errorlevel 1 goto failed
    call :refresh_path
    call :find_python
    if errorlevel 1 goto failed
)
echo [%ESC%[32mOK%ESC%[0m] Python found: %CP_PYTHON%

if "%CHECK_ONLY%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', '%ROOT%', 'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_SETUP_ROOT', '%ROOT%', 'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_PYTHON', '%CP_PYTHON%', 'User')"
    if errorlevel 1 goto failed

    set "CP_SETUP_ROOT=%ROOT%"
    call :install_cmd_macros
    if errorlevel 1 goto failed
) else (
    echo [%ESC%[38;5;183mCHECK%ESC%[0m] Skipping environment writes and DOSKEY install.
)

if exist "%ROOT%\.git" (
    git -C "%ROOT%" submodule update --init ac-library
    if errorlevel 1 goto failed
)

echo Verifying setup...
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

:install_msys2_toolchain
where winget >nul 2>nul
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] winget is required to install MSYS2 automatically.
    exit /b 1
)
winget install --id MSYS2.MSYS2 --exact --accept-package-agreements --accept-source-agreements
if errorlevel 1 exit /b %ERRORLEVEL%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $shell=@('C:\msys64\msys2_shell.cmd','D:\software\programming\msys2\msys2_shell.cmd') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1; if (-not $shell) { $cmd=Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue; if ($cmd) { $shell=$cmd.Source } }; if (-not $shell) { throw 'Could not find msys2_shell.cmd after installing MSYS2.' }; & $shell -mingw64 -defterm -no-start -here -c 'pacman -Syu --noconfirm'; if ($LASTEXITCODE -ne 0) { throw 'pacman system update failed.' }; & $shell -mingw64 -defterm -no-start -here -c 'pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python'; if ($LASTEXITCODE -ne 0) { throw 'pacman toolchain install failed.' }"
exit /b %ERRORLEVEL%

:install_paths
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $check='%~1' -ieq 'check'; $esc=[char]27; $c=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); $e=$c | Where-Object { Test-Path -LiteralPath $_ }; if ($check) { foreach ($p in $e) { Write-Host \"[$($esc)[38;5;183mCHECK$($esc)[0m] PATH candidate exists: $p\" }; exit 0 }; $u=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $u) { $u='' }; $parts=$u -split ';' | Where-Object { $_ }; foreach ($p in $e) { $a=$parts | Where-Object { $_.TrimEnd('\') -ieq $p.TrimEnd('\') }; if (-not $a) { $parts += $p; Write-Host \"[PATH] Added: $p\" } }; [Environment]::SetEnvironmentVariable('Path',($parts -join ';'),'User')"
exit /b %ERRORLEVEL%

:install_cmd_macros
set "MACROS=%ROOT%\scripts\cp_macros"
if not exist "%MACROS%" (
    echo Macro file not found: %MACROS%
    exit /b 1
)
if not defined CP_PYTHON call :find_python
if not defined CP_PYTHON (
    echo Could not find a usable Python executable.
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_SETUP_ROOT', '%ROOT%', 'User'); [Environment]::SetEnvironmentVariable('CP_PYTHON', '%CP_PYTHON%', 'User')"
if errorlevel 1 exit /b 1
set "CP_SETUP_ROOT=%ROOT%"
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

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:find_python
set "CP_PYTHON="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_PYTHON) { $c += $env:CP_PYTHON }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe','D:\software\programming\msys2\mingw64\bin\python.exe','D:\software\programming\msys2\ucrt64\bin\python.exe'); $w=where.exe python 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output $p; exit 0 } } }; exit 1"`) do set "CP_PYTHON=%%P"
if defined CP_PYTHON exit /b 0
exit /b 1

:verify
call :refresh_path
where git >nul 2>nul || exit /b 1
where nvim >nul 2>nul || exit /b 1
if not defined CP_PYTHON call :find_python
if not defined CP_PYTHON exit /b 1
where javac >nul 2>nul || exit /b 1
where g++ >nul 2>nul || exit /b 1
call :ensure_spinner
if errorlevel 1 exit /b 1

"%CP_PYTHON%" "%SPINNER_PY%" --label "Run C++ template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%ROOT%\template\cpp\solve.cpp"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Run Java template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%ROOT%\template\java\solve.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Run Python template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%ROOT%\template\python\solve.py"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand C++ template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" "%ROOT%\template\cpp\solve.cpp"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand Java template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" "%ROOT%\template\java\solve.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand Python template" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" "%ROOT%\template\python\solve.py"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded C++" --cwd "%ROOT%" --stdin-empty -- g++ -std=c++20 -O2 "%ROOT%\template\cpp\submit.cpp" -o "%TEMP%\cp_submit_test.exe"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded Java" --cwd "%ROOT%" --stdin-empty -- javac -encoding UTF-8 -d "%TEMP%" "%ROOT%\template\java\submit.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Parse expanded Python" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" -c "import ast, pathlib; ast.parse(pathlib.Path(r'%ROOT%\template\python\submit.py').read_text())"
if errorlevel 1 goto verify_failed

call :cleanup_verify
if errorlevel 1 exit /b 1

if exist "%ROOT%\.git" (
    git -C "%ROOT%" submodule status >nul
    if errorlevel 1 exit /b 1
)

echo [%ESC%[32mOK%ESC%[0m] Verification passed
exit /b 0

:verify_failed
call :cleanup_verify
exit /b 1

:ensure_spinner
set "SPINNER_PY=%TEMP%\cp_setup_spinner.py"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[IO.File]::WriteAllBytes('%SPINNER_PY%', [Convert]::FromBase64String('aW1wb3J0IGFyZ3BhcnNlCmltcG9ydCBzdWJwcm9jZXNzCmltcG9ydCBzeXMKaW1wb3J0IHRpbWUKZnJvbSBwYXRobGliIGltcG9ydCBQYXRoCgpQVVJQTEUgPSAiXDAzM1szODs1OzE4M20iClJFU0VUID0gIlwwMzNbMG0iCkZSQU1FUyA9IFsiXFwiLCAiLSIsICIvIiwgInwiXQoKCmRlZiBtYWluKCkgLT4gaW50OgogICAgcGFyc2VyID0gYXJncGFyc2UuQXJndW1lbnRQYXJzZXIoKQogICAgcGFyc2VyLmFkZF9hcmd1bWVudCgiLS1sYWJlbCIsIHJlcXVpcmVkPVRydWUpCiAgICBwYXJzZXIuYWRkX2FyZ3VtZW50KCItLWN3ZCIsIGRlZmF1bHQ9c3RyKFBhdGguY3dkKCkpKQogICAgcGFyc2VyLmFkZF9hcmd1bWVudCgiLS1zdGRpbi1lbXB0eSIsIGFjdGlvbj0ic3RvcmVfdHJ1ZSIpCiAgICBwYXJzZXIuYWRkX2FyZ3VtZW50KCJjb21tYW5kIiwgbmFyZ3M9YXJncGFyc2UuUkVNQUlOREVSKQogICAgYXJncyA9IHBhcnNlci5wYXJzZV9hcmdzKCkKICAgIGNvbW1hbmQgPSBhcmdzLmNvbW1hbmRbMTpdIGlmIGFyZ3MuY29tbWFuZCBhbmQgYXJncy5jb21tYW5kWzBdID09ICItLSIgZWxzZSBhcmdzLmNvbW1hbmQKICAgIGlmIG5vdCBjb21tYW5kOgogICAgICAgIHByaW50KCJzcGlubmVyOiBtaXNzaW5nIGNvbW1hbmQiLCBmaWxlPXN5cy5zdGRlcnIpCiAgICAgICAgcmV0dXJuIDEKICAgIHN0ZGluID0gc3VicHJvY2Vzcy5ERVZOVUxMIGlmIGFyZ3Muc3RkaW5fZW1wdHkgZWxzZSBOb25lCiAgICBwcm9jZXNzID0gc3VicHJvY2Vzcy5Qb3Blbihjb21tYW5kLCBjd2Q9YXJncy5jd2QsIHN0ZGluPXN0ZGluLCBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLCBzdGRlcnI9c3VicHJvY2Vzcy5QSVBFLCB0ZXh0PVRydWUpCiAgICBpbmRleCA9IDAKICAgIHdoaWxlIHByb2Nlc3MucG9sbCgpIGlzIE5vbmU6CiAgICAgICAgcHJpbnQoZiJcclt7UFVSUExFfVZFUklGWXtSRVNFVH1dIHtGUkFNRVNbaW5kZXggJSBsZW4oRlJBTUVTKV19IHthcmdzLmxhYmVsfSIsIGVuZD0iIiwgZmx1c2g9VHJ1ZSkKICAgICAgICB0aW1lLnNsZWVwKDAuMSkKICAgICAgICBpbmRleCArPSAxCiAgICBzdGRvdXQsIHN0ZGVyciA9IHByb2Nlc3MuY29tbXVuaWNhdGUoKQogICAgaWYgcHJvY2Vzcy5yZXR1cm5jb2RlID09IDA6CiAgICAgICAgcHJpbnQoZiJcclt7UFVSUExFfVZFUklGWXtSRVNFVH1dIGRvbmUge2FyZ3MubGFiZWx9IikKICAgICAgICByZXR1cm4gMAogICAgcHJpbnQoZiJcclt7UFVSUExFfVZFUklGWXtSRVNFVH1dIGZhaWxlZCB7YXJncy5sYWJlbH0iLCBmaWxlPXN5cy5zdGRlcnIpCiAgICBpZiBzdGRlcnI6CiAgICAgICAgcHJpbnQoc3RkZXJyLCBmaWxlPXN5cy5zdGRlcnIsIGVuZD0iIikKICAgIGlmIHN0ZG91dDoKICAgICAgICBwcmludChzdGRvdXQsIGZpbGU9c3lzLnN0ZGVyciwgZW5kPSIiKQogICAgcmV0dXJuIHByb2Nlc3MucmV0dXJuY29kZQoKCmlmIF9fbmFtZV9fID09ICJfX21haW5fXyI6CiAgICByYWlzZSBTeXN0ZW1FeGl0KG1haW4oKSkK'))"
exit /b %ERRORLEVEL%

:cleanup_verify
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
del "%TEMP%\cp_setup_spinner.py" >nul 2>nul
if exist "%ROOT%\libraries\python\my_libraries\__pycache__" rmdir /s /q "%ROOT%\libraries\python\my_libraries\__pycache__"
if exist "%ROOT%\template\python\__pycache__" rmdir /s /q "%ROOT%\template\python\__pycache__"
exit /b 0

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup install did not complete.
exit /b 1
