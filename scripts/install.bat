@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "CHECK_ONLY=0"
set "VERBOSE=0"
set "WINGET_ARGS=--exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity"
set "WINGET_QUIET_ARGS=%WINGET_ARGS% --silent"

:parse_args
if "%~1"=="" goto parsed_args
if /i "%~1"=="--check" (
    set "CHECK_ONLY=1"
    shift
    goto parse_args
)
if /i "%~1"=="--verbose" (
    set "VERBOSE=1"
    shift
    goto parse_args
)
echo [%ESC%[31mFAILED%ESC%[0m] Unknown argument: %~1
exit /b 1

:parsed_args

echo CP setup root:
echo %ROOT%
echo.

call :refresh_path

if "%CHECK_ONLY%"=="0" (
    call :install_paths
    if errorlevel 1 goto failed
    call :refresh_path
)

call :need_or_install nvim Neovim.Neovim "Neovim"
if errorlevel 1 goto failed
call :need_or_install javac EclipseAdoptium.Temurin.21.JDK "JDK"
if errorlevel 1 goto failed

where g++ >nul 2>nul
if not errorlevel 1 (
    call :print_found "g++"
) else (
    if "%CHECK_ONLY%"=="1" (
        echo [%ESC%[33mMISSING%ESC%[0m] g++
        goto failed
    )
    call :install_msys2_toolchain
    if errorlevel 1 goto failed
)

if "%CHECK_ONLY%"=="1" (
    call :install_paths check
) else (
    call :install_paths
)
if errorlevel 1 goto failed
call :refresh_path
call :find_gpp
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ was installed, but g++.exe was not found in known MSYS2 paths.
    goto failed
)

call :find_python
if not errorlevel 1 (
    rem Python is available.
) else if "%CHECK_ONLY%"=="1" (
    echo [%ESC%[33mMISSING%ESC%[0m] Python 3
    goto failed
) else (
    call :install_msys2_toolchain
    if errorlevel 1 goto failed
    call :refresh_path
    call :find_python
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Python was installed, but python.exe was not found in known MSYS2 paths.
        goto failed
    )
)

if "%CHECK_ONLY%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', '%ROOT%', 'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_SETUP_ROOT', '%ROOT%', 'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_PYTHON', '%CP_PYTHON%', 'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('CP_GPP', '%CP_GPP%', 'User')"
    if errorlevel 1 goto failed

    set "CP_SETUP_ROOT=%ROOT%"
    call :install_cmd_macros
    if errorlevel 1 goto failed
) else (
    echo [%ESC%[38;5;183mCHECK%ESC%[0m] Environment writes skipped.
)

if exist "%ROOT%\.git" where git >nul 2>nul
if not errorlevel 1 if exist "%ROOT%\.git" (
    echo.
    git -C "%ROOT%" submodule update --init libraries/ac-library
    if errorlevel 1 goto failed
    echo.
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
    exit /b 0
)

if "%CHECK_ONLY%"=="1" (
    echo [%ESC%[33mMISSING%ESC%[0m] %~3
    exit /b 0
)

call :require_winget
if errorlevel 1 exit /b 1

if "%VERBOSE%"=="1" (
    echo [%ESC%[38;5;153mINSTALL%ESC%[0m] %~3 via winget: %~2
    "%WINGET%" install --id %~2 %WINGET_ARGS%
) else (
    set "INSTALL_CMD=!WINGET! install --id %~2 %WINGET_QUIET_ARGS%"
    call :run_install_spinner "%~3 via winget: %~2" "" "%TEMP%\cp_setup_winget.log"
)
set "INSTALL_EXIT=%ERRORLEVEL%"
call :install_paths
if errorlevel 1 exit /b 1
call :refresh_path
where "%~1" >nul 2>nul
if not errorlevel 1 (
    exit /b 0
)
if not "%INSTALL_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for %~3.
    if not "%VERBOSE%"=="1" echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] %~3 was not found after winget install.
if not "%VERBOSE%"=="1" echo Log: %TEMP%\cp_setup_winget.log
exit /b 1

:print_found
echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1
exit /b 0

:require_winget
set "WINGET="
for /F "usebackq delims=" %%P in (`where winget 2^>nul`) do (
    if not defined WINGET set "WINGET=%%P"
)
if not defined WINGET if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" set "WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if defined WINGET (
    for %%I in ("%WINGET%") do set "PATH=%%~dpI;%PATH%"
    exit /b 0
)
echo [%ESC%[31mFAILED%ESC%[0m] winget was not found.
echo Install or update App Installer from Microsoft Store, open a new cmd.exe, then rerun this installer.
echo Store shortcut: start ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1
exit /b 1

:find_msys2_shell
set "MSYS2_SHELL="
if exist "C:\msys64\msys2_shell.cmd" set "MSYS2_SHELL=C:\msys64\msys2_shell.cmd"
if not defined MSYS2_SHELL if exist "D:\software\programming\msys2\msys2_shell.cmd" set "MSYS2_SHELL=D:\software\programming\msys2\msys2_shell.cmd"
if defined MSYS2_SHELL exit /b 0
for /F "usebackq delims=" %%P in (`where msys2_shell.cmd 2^>nul`) do (
    if not defined MSYS2_SHELL set "MSYS2_SHELL=%%P"
)
if defined MSYS2_SHELL exit /b 0
exit /b 1

:install_msys2_toolchain
call :require_winget
if errorlevel 1 exit /b 1
call :find_msys2_shell
if errorlevel 1 (
    if "%VERBOSE%"=="1" (
        echo [%ESC%[38;5;153mINSTALL%ESC%[0m] MSYS2 via winget: MSYS2.MSYS2
        "%WINGET%" install --id MSYS2.MSYS2 %WINGET_ARGS%
    ) else (
        set "INSTALL_CMD=!WINGET! install --id MSYS2.MSYS2 %WINGET_QUIET_ARGS%"
        call :run_install_spinner "MSYS2 via winget: MSYS2.MSYS2" "" "%TEMP%\cp_setup_winget.log"
    )
    set "INSTALL_EXIT=%ERRORLEVEL%"
    call :find_msys2_shell
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for MSYS2.
        if not "%VERBOSE%"=="1" echo Log: %TEMP%\cp_setup_winget.log
        exit /b 1
    )
)
if "%VERBOSE%"=="1" (
    echo [%ESC%[38;5;153mINSTALL%ESC%[0m] MSYS2 toolchain via pacman
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $shell=@('C:\msys64\msys2_shell.cmd','D:\software\programming\msys2\msys2_shell.cmd') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1; if (-not $shell) { $cmd=Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue; if ($cmd) { $shell=$cmd.Source } }; if (-not $shell) { throw 'Could not find msys2_shell.cmd after installing MSYS2.' }; $bash=Join-Path (Split-Path -Parent $shell) 'usr\bin\bash.exe'; if (-not (Test-Path -LiteralPath $bash)) { throw 'Could not find MSYS2 bash.exe after installing MSYS2.' }; $env:MSYSTEM='MINGW64'; $env:CHERE_INVOKING='enabled_from_arguments'; & $bash -lc 'pacman -Syu --noconfirm && pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python'; if ($LASTEXITCODE -ne 0) { throw 'pacman toolchain install failed.' }"
) else (
    call :run_pacman_spinner
)
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain install failed.
    if not "%VERBOSE%"=="1" echo Log: %TEMP%\cp_setup_pacman.log
    exit /b 1
)
exit /b %ERRORLEVEL%

:run_pacman_spinner
set "SPIN_PS=%TEMP%\cp_setup_pacman_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo $label = 'MSYS2 toolchain via pacman'
>> "%SPIN_PS%" echo $hint = 'this may take a while'
>> "%SPIN_PS%" echo $log = Join-Path $env:TEMP 'cp_setup_pacman.log'
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:TEMP ('cp_setup_pacman_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $install = '[' + $esc + '[38;5;153mINSTALL' + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $shell = $null
>> "%SPIN_PS%" echo foreach ($path in @('C:\msys64\msys2_shell.cmd','D:\software\programming\msys2\msys2_shell.cmd')) { if (Test-Path -LiteralPath $path) { $shell = $path; break } }
>> "%SPIN_PS%" echo if (-not $shell) { $cmd = Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue; if ($cmd) { $shell = $cmd.Source } }
>> "%SPIN_PS%" echo if (-not $shell) { 'Could not find msys2_shell.cmd after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($install + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $bash = Join-Path (Split-Path -Parent $shell) 'usr\bin\bash.exe'
>> "%SPIN_PS%" echo if (-not (Test-Path -LiteralPath $bash)) { 'Could not find MSYS2 bash.exe after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($install + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $pacman = 'pacman -Syu --noconfirm ^&^& pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python'
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $q + $bash + $q + ' -lc ' + $q + $pacman + $q + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off','set "MSYSTEM=MINGW64"','set "CHERE_INVOKING=enabled_from_arguments"',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $job = Start-Job -ScriptBlock { param($wrapper) ^& $env:ComSpec /d /c call $wrapper; $LASTEXITCODE } -ArgumentList $wrapper
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo while ($job.State -eq 'Running') { Write-Host -NoNewline ($cr + $install + ' ' + $frames[$i %% $frames.Count] + ' ' + $label + ' (' + $hint + ')'); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%SPIN_PS%" echo Remove-Job $job -Force
>> "%SPIN_PS%" echo $jobItems = @($jobResult)
>> "%SPIN_PS%" echo if ($jobItems.Count -eq 0) { $exitCode = 1 } else { $exitCode = [int]$jobItems[-1] }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0) { $result = 'OK' } else { $result = 'FAILED' }
>> "%SPIN_PS%" echo Write-Host ($cr + $install + ' ' + $result + ' ' + $label + '     ')
>> "%SPIN_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
del "%SPIN_PS%" >nul 2>nul
exit /b %SPIN_EXIT%

:run_install_spinner
set "SPIN_LABEL=%~1"
set "SPIN_HINT=%~2"
set "SPIN_LOG=%~3"
set "SPIN_PS=%TEMP%\cp_setup_install_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo $label = $env:SPIN_LABEL
>> "%SPIN_PS%" echo $hint = $env:SPIN_HINT
>> "%SPIN_PS%" echo $log = $env:SPIN_LOG
>> "%SPIN_PS%" echo $cmd = [string]$env:INSTALL_CMD
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:TEMP ('cp_setup_install_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $install = '[' + $esc + '[38;5;153mINSTALL' + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $cmd + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $job = Start-Job -ScriptBlock { param($wrapper) ^& $env:ComSpec /d /c call $wrapper; $LASTEXITCODE } -ArgumentList $wrapper
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo while ($job.State -eq 'Running') { $text = $install + ' ' + $frames[$i %% $frames.Count] + ' ' + $label; if ($hint) { $text += ' (' + $hint + ')' }; Write-Host -NoNewline ($cr + $text); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%SPIN_PS%" echo Remove-Job $job -Force
>> "%SPIN_PS%" echo $jobItems = @($jobResult)
>> "%SPIN_PS%" echo if ($jobItems.Count -eq 0) { $exitCode = 1 } else { $exitCode = [int]$jobItems[-1] }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0) { $result = 'OK' } else { $result = 'FAILED' }
>> "%SPIN_PS%" echo Write-Host ($cr + $install + ' ' + $result + ' ' + $label + '     ')
>> "%SPIN_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
del "%SPIN_PS%" >nul 2>nul
exit /b %SPIN_EXIT%

:install_paths
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $check='%~1' -ieq 'check'; $verbose='%VERBOSE%' -eq '1'; $esc=[char]27; $jdkBins=@(); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $jdkBins=Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $c=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin') + $jdkBins; $e=$c | Where-Object { Test-Path -LiteralPath $_ }; if ($check) { if ($verbose) { foreach ($p in $e) { Write-Host \"[$($esc)[38;5;183mCHECK$($esc)[0m] PATH candidate exists: $p\" } } else { Write-Host \"[$($esc)[38;5;183mCHECK$($esc)[0m] Environment paths\" }; exit 0 }; $u=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $u) { $u='' }; $known=@($env:LOCALAPPDATA + '\Microsoft\WindowsApps') + $c; $known=$known | Where-Object { $_ } | Sort-Object Length -Descending -Unique; $parts=New-Object System.Collections.Generic.List[string]; foreach ($raw in ($u -split ';')) { $s=$raw.Trim(); while ($s) { $hit=$null; $hitAt=-1; foreach ($k in $known) { $i=$s.IndexOf($k, [StringComparison]::OrdinalIgnoreCase); if ($i -ge 0 -and ($hitAt -lt 0 -or $i -lt $hitAt -or ($i -eq $hitAt -and $k.Length -gt $hit.Length))) { $hit=$k; $hitAt=$i } }; if (-not $hit) { $parts.Add($s); break }; if ($hitAt -gt 0) { $prefix=$s.Substring(0,$hitAt).Trim(); if ($prefix) { $parts.Add($prefix) } }; $parts.Add($hit); $s=$s.Substring($hitAt + $hit.Length).Trim() } }; foreach ($p in $e) { $parts.Add($p) }; $clean=New-Object System.Collections.Generic.List[string]; foreach ($p in $parts) { $v=$p.Trim().TrimEnd('\'); if (-not $v) { continue }; $exists=$false; foreach ($x in $clean) { if ($x.TrimEnd('\') -ieq $v) { $exists=$true; break } }; if (-not $exists) { $clean.Add($v) } }; if ($verbose) { foreach ($p in $e) { Write-Host \"[PATH] Ensured: $p\" } }; [Environment]::SetEnvironmentVariable('Path',($clean -join ';'),'User')"
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
exit /b 0

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:find_python
set "CP_PYTHON="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_PYTHON) { $c += $env:CP_PYTHON }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe','D:\software\programming\msys2\mingw64\bin\python.exe','D:\software\programming\msys2\ucrt64\bin\python.exe'); $w=where.exe python 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output $p; exit 0 } } }; exit 1"`) do set "CP_PYTHON=%%P"
if defined CP_PYTHON exit /b 0
exit /b 1

:find_gpp
set "CP_GPP="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_GPP) { $c += $env:CP_GPP }; $c += @('C:\msys64\mingw64\bin\g++.exe','C:\msys64\ucrt64\bin\g++.exe','D:\software\programming\msys2\mingw64\bin\g++.exe','D:\software\programming\msys2\ucrt64\bin\g++.exe'); $w=where.exe g++ 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output $p; exit 0 } } }; exit 1"`) do set "CP_GPP=%%P"
if defined CP_GPP (
    for %%I in ("%CP_GPP%") do set "PATH=%%~dpI;%PATH%"
    exit /b 0
)
exit /b 1

:verify
call :refresh_path
call :find_gpp
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ is not visible during verification.
    exit /b 1
)
where nvim >nul 2>nul
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] nvim is not visible during verification.
    exit /b 1
)
if not defined CP_PYTHON call :find_python
if not defined CP_PYTHON (
    echo [%ESC%[31mFAILED%ESC%[0m] Python is not visible during verification.
    exit /b 1
)
where javac >nul 2>nul
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] javac is not visible during verification.
    exit /b 1
)
call :ensure_spinner
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not create verification spinner.
    exit /b 1
)

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
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded C++" --cwd "%ROOT%" --stdin-empty -- "%CP_GPP%" -std=c++20 -O2 "%ROOT%\template\cpp\submit.cpp" -o "%TEMP%\cp_submit_test.exe"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded Java" --cwd "%ROOT%" --stdin-empty -- javac -encoding UTF-8 -d "%TEMP%" "%ROOT%\template\java\submit.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Parse expanded Python" --cwd "%ROOT%" --stdin-empty -- "%CP_PYTHON%" -c "import ast, pathlib; ast.parse(pathlib.Path(r'%ROOT%\template\python\submit.py').read_text())"
if errorlevel 1 goto verify_failed

call :cleanup_verify
if errorlevel 1 exit /b 1

if exist "%ROOT%\.git" where git >nul 2>nul
if not errorlevel 1 if exist "%ROOT%\.git" (
    git -C "%ROOT%" submodule status >nul
    if errorlevel 1 exit /b 1
)

echo [%ESC%[32mOK%ESC%[0m] Verification passed
exit /b 0

:verify_failed
call :cleanup_verify
exit /b 1

:ensure_spinner
set "SPINNER_PY=%TEMP%\cp_setup_spinner_%RANDOM%_%RANDOM%.py"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code=@('import argparse','import subprocess','import sys','import time','from pathlib import Path','','PURPLE = chr(27) + ''[38;5;183m''','RESET = chr(27) + ''[0m''','FRAMES = list(chr(92) + ''-/|'')','','def main() -> int:','    parser = argparse.ArgumentParser()','    parser.add_argument(''--label'', required=True)','    parser.add_argument(''--cwd'', default=str(Path.cwd()))','    parser.add_argument(''--stdin-empty'', action=''store_true'')','    parser.add_argument(''command'', nargs=argparse.REMAINDER)','    args = parser.parse_args()','    command = args.command[1:] if args.command and args.command[0] == ''--'' else args.command','    if not command:','        print(''spinner: missing command'', file=sys.stderr)','        return 1','    stdin = subprocess.DEVNULL if args.stdin_empty else None','    process = subprocess.Popen(command, cwd=args.cwd, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)','    index = 0','    while process.poll() is None:','        print(''\r[{}VERIFY{}] {} {}''.format(PURPLE, RESET, FRAMES[index %% len(FRAMES)], args.label), end='''', flush=True)','        time.sleep(0.1)','        index += 1','    stdout, stderr = process.communicate()','    if process.returncode == 0:','        print(''\r[{}VERIFY{}] OK {}     ''.format(PURPLE, RESET, args.label))','        return 0','    print(''\r[{}VERIFY{}] FAILED {}     ''.format(PURPLE, RESET, args.label), file=sys.stderr)','    if stderr:','        print(stderr, file=sys.stderr, end='''')','    if stdout:','        print(stdout, file=sys.stderr, end='''')','    return process.returncode','','if __name__ == ''__main__'':','    raise SystemExit(main())'); [IO.File]::WriteAllText('%SPINNER_PY%', ($code -join [Environment]::NewLine))"
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
if defined SPINNER_PY del "%SPINNER_PY%" >nul 2>nul
del "%TEMP%\cp_setup_spinner.py" >nul 2>nul
if exist "%ROOT%\libraries\python\my_libraries\__pycache__" rmdir /s /q "%ROOT%\libraries\python\my_libraries\__pycache__"
if exist "%ROOT%\template\python\__pycache__" rmdir /s /q "%ROOT%\template\python\__pycache__"
exit /b 0

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup install did not complete.
exit /b 1
