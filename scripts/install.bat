@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "ORIGINAL_ARGS=%*"

set "CHECK_ONLY=0"
set "VERBOSE=0"
set "MISSING_COUNT=0"
set "STATE_KEY=HKCU\Software\my-cp-setup"
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

if "%CHECK_ONLY%"=="0" (
    call :ensure_admin
    if errorlevel 2 exit /b 0
    if errorlevel 1 exit /b 1
)
call :enable_ansi

echo CP setup root:
echo %ROOT%
echo.

call :refresh_path

if "%CHECK_ONLY%"=="0" (
    call :install_paths
    if errorlevel 1 goto failed
    call :refresh_path
)

if "%CHECK_ONLY%"=="1" (
    echo Checking main components...
) else (
    echo Installing main components...
)

call :need_git
if errorlevel 1 goto failed
call :need_or_install nvim Neovim.Neovim "Neovim" "Winget.Neovim" "FOUND_NVIM_PATH"
if errorlevel 1 goto failed
call :need_or_install javac EclipseAdoptium.Temurin.21.JDK "JDK" "Winget.JDK" "FOUND_JAVAC_PATH"
if errorlevel 1 goto failed

call :search_command "g++" "where.exe g++" "FOUND_GPP_PATH"
if not errorlevel 1 (
    call :find_gpp quiet
) else (
    if "%CHECK_ONLY%"=="1" (
        call :print_missing "g++"
    ) else (
        call :install_msys2_toolchain
        if errorlevel 1 goto failed
    )
)

if "%CHECK_ONLY%"=="1" if not "%MISSING_COUNT%"=="0" goto skip_gpp_validation
call :find_gpp quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ was installed, but g++.exe was not found in known MSYS2 paths.
    goto failed
)
:skip_gpp_validation

call :find_python
if errorlevel 1 (
    if "%CHECK_ONLY%"=="1" (
        call :print_missing "Python 3"
    ) else (
        call :install_msys2_toolchain
        if errorlevel 1 goto failed
        call :refresh_path
        call :find_python quiet
        if errorlevel 1 (
            echo [%ESC%[31mFAILED%ESC%[0m] Python was installed, but python.exe was not found in known MSYS2 paths.
            goto failed
        )
    )
)

call :ensure_ruff
if errorlevel 1 goto failed

if "%CHECK_ONLY%"=="1" (
    if "%VERBOSE%"=="1" (
        call :install_paths check
        if errorlevel 1 goto failed
    ) else (
        call :check_env_paths
    )
) else (
    call :install_paths
)
if errorlevel 1 goto failed
call :refresh_path

if exist "%ROOT%\.git" (
    echo.
    if "%CHECK_ONLY%"=="1" (
        echo Checking libraries...
        call :check_ac_library
    ) else (
        echo Installing libraries...
        call :update_ac_library_if_needed
    )
    if errorlevel 1 goto failed
    echo.
)

if "%CHECK_ONLY%"=="1" if not "%MISSING_COUNT%"=="0" goto check_missing

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
)

echo Verifying setup...
call :verify
if errorlevel 1 goto failed

echo.
echo [%ESC%[32mDONE%ESC%[0m] CP setup is ready.
echo Restart terminals so updated User PATH and XDG_CONFIG_HOME are visible everywhere.
exit /b 0

:check_missing
echo.
echo [%ESC%[33mMISSING%ESC%[0m] Some components are not available.
echo Run scripts\install.bat without --check to install missing components.
exit /b 1

:enable_ansi
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Namespace Native -Name Console -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern System.IntPtr GetStdHandle(int nStdHandle); [DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out int lpMode); [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, int dwMode);'; $h=[Native.Console]::GetStdHandle(-11); $mode=0; if ([Native.Console]::GetConsoleMode($h,[ref]$mode)) { [Native.Console]::SetConsoleMode($h,$mode -bor 4) | Out-Null }" >nul 2>nul
exit /b 0

:ensure_admin
powershell -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1"
if not errorlevel 1 exit /b 0

set "ELEVATE_PS=%TEMP%\cp_setup_elevate_%RANDOM%_%RANDOM%.ps1"
set "ELEVATE_LOG=%TEMP%\cp_setup_elevate.log"
set "ELEVATE_EXIT_FILE=%TEMP%\cp_setup_elevate_exit_%RANDOM%_%RANDOM%.txt"
set "ELEVATE_STARTED_FILE=%TEMP%\cp_setup_elevate_started_%RANDOM%_%RANDOM%.txt"
set "ELEVATE_CMD=%TEMP%\cp_setup_elevate_%RANDOM%_%RANDOM%.cmd"
set "CP_INSTALL_SCRIPT=%~f0"
set "CP_INSTALL_ARGS=%ORIGINAL_ARGS%"
set "CP_INSTALL_CWD=%ROOT%"
> "%ELEVATE_CMD%" echo @echo off
>> "%ELEVATE_CMD%" echo ^> "%ELEVATE_EXIT_FILE%" echo 900
>> "%ELEVATE_CMD%" echo cd /d "%CP_INSTALL_CWD%"
>> "%ELEVATE_CMD%" echo call "%CP_INSTALL_SCRIPT%" %CP_INSTALL_ARGS%
>> "%ELEVATE_CMD%" echo set "CP_SETUP_EXIT=%%ERRORLEVEL%%"
>> "%ELEVATE_CMD%" echo ^> "%ELEVATE_EXIT_FILE%" echo %%CP_SETUP_EXIT%%
>> "%ELEVATE_CMD%" echo echo.
>> "%ELEVATE_CMD%" echo echo Press any key to exit...
>> "%ELEVATE_CMD%" echo pause ^>nul
>> "%ELEVATE_CMD%" echo exit /b %%CP_SETUP_EXIT%%
> "%ELEVATE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ELEVATE_PS%" echo $requestLabel = 'Requesting administrator rights...'
>> "%ELEVATE_PS%" echo $installLabel = 'Administrator rights granted, installing...'
>> "%ELEVATE_PS%" echo $log = $env:ELEVATE_LOG
>> "%ELEVATE_PS%" echo $esc = [char]27
>> "%ELEVATE_PS%" echo $cr = [char]13
>> "%ELEVATE_PS%" echo $clear = $esc + '[2K'
>> "%ELEVATE_PS%" echo $green = $esc + '[38;5;114m'
>> "%ELEVATE_PS%" echo $red = $esc + '[31m'
>> "%ELEVATE_PS%" echo $reset = $esc + '[0m'
>> "%ELEVATE_PS%" echo $exitFile = $env:ELEVATE_EXIT_FILE
>> "%ELEVATE_PS%" echo $startedFile = $env:ELEVATE_STARTED_FILE
>> "%ELEVATE_PS%" echo Remove-Item -LiteralPath $log,$exitFile,$startedFile -ErrorAction SilentlyContinue
>> "%ELEVATE_PS%" echo $cmdPath = $env:ELEVATE_CMD
>> "%ELEVATE_PS%" echo $job = Start-Job -ScriptBlock { param($cmdPath,$cwd,$log,$startedFile) try { $p = Start-Process -FilePath $cmdPath -WorkingDirectory $cwd -Verb RunAs -PassThru; 'started' ^| Set-Content -LiteralPath $startedFile; $p.WaitForExit(); 0 } catch { $_ ^| Out-String ^| Set-Content -LiteralPath $log; 1 } } -ArgumentList $cmdPath,$env:CP_INSTALL_CWD,$log,$startedFile
>> "%ELEVATE_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%ELEVATE_PS%" echo $i = 0
>> "%ELEVATE_PS%" echo while ($job.State -eq 'Running') { if (Test-Path -LiteralPath $startedFile) { $label = $installLabel } else { $label = $requestLabel }; Write-Host -NoNewline ($cr + $clear + $frames[$i %% $frames.Count] + ' ' + $label); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%ELEVATE_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%ELEVATE_PS%" echo Remove-Job $job -Force
>> "%ELEVATE_PS%" echo $items = @($jobResult)
>> "%ELEVATE_PS%" echo Remove-Item -LiteralPath $startedFile -ErrorAction SilentlyContinue
>> "%ELEVATE_PS%" echo if ($items.Count -eq 0 -or [int]$items[-1] -ne 0) {
>> "%ELEVATE_PS%" echo     $details = ''
>> "%ELEVATE_PS%" echo     if (Test-Path -LiteralPath $log) { $details = Get-Content -LiteralPath $log -Raw }
>> "%ELEVATE_PS%" echo     if ($details -match 'canceled by the user') { Write-Host ($cr + $clear + $red + 'Install canceled by user.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo     if ($details -match 'Access is denied') { Write-Host ($cr + $clear + $red + 'Install failed: administrator rights were denied.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo     Write-Host ($cr + $clear + $red + 'Install failed while requesting administrator rights.' + $reset)
>> "%ELEVATE_PS%" echo     if ($details) { Write-Host $details }
>> "%ELEVATE_PS%" echo     exit 1
>> "%ELEVATE_PS%" echo }
>> "%ELEVATE_PS%" echo if (-not (Test-Path -LiteralPath $exitFile)) { Write-Host ($cr + $clear + $red + 'Install failed: installer did not report an exit code.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo $childExit = [int]((Get-Content -LiteralPath $exitFile -ErrorAction Stop ^| Select-Object -First 1).Trim())
>> "%ELEVATE_PS%" echo Remove-Item -LiteralPath $exitFile -ErrorAction SilentlyContinue
>> "%ELEVATE_PS%" echo if ($childExit -eq 0) { Write-Host ($cr + $clear + $green + 'Install completed (see README for more info)' + $reset); exit 0 }
>> "%ELEVATE_PS%" echo Write-Host ($cr + $clear + $red + ('Install failed: elevated installer exited with code ' + $childExit) + $reset)
>> "%ELEVATE_PS%" echo exit 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%ELEVATE_PS%"
set "ELEVATE_EXIT=%ERRORLEVEL%"
del "%ELEVATE_PS%" >nul 2>nul
del "%ELEVATE_CMD%" >nul 2>nul
if not "%ELEVATE_EXIT%"=="0" (
    exit /b 1
)
exit /b 2

:need_git
call :search_command "Git" "where.exe git" "FOUND_GIT_PATH"
if not errorlevel 1 exit /b 0

if "%CHECK_ONLY%"=="1" (
    call :print_missing "Git"
    exit /b 0
)

call :require_winget
if errorlevel 1 exit /b 1

set "INSTALL_CMD=!WINGET! install --id Git.Git %WINGET_QUIET_ARGS%"
call :run_install_spinner "Git via winget: Git.Git" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :install_paths
if errorlevel 1 exit /b 1
call :refresh_path
call :find_command "git" "FOUND_GIT_PATH"
if not errorlevel 1 (
    if "%INSTALL_EXIT%"=="0" (
        call :record_component "Winget.Git"
        if "%VERBOSE%"=="1" echo   %FOUND_GIT_PATH%
    )
    exit /b 0
)
if not "%INSTALL_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for Git.
    echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] Git was not found after winget install.
echo Log: %TEMP%\cp_setup_winget.log
exit /b 1

:need_or_install
call :search_command "%~3" "where.exe %~1" "FOUND_TOOL_PATH"
if not errorlevel 1 (
    if not "%~5"=="" set "%~5=%FOUND_TOOL_PATH%"
    exit /b 0
)

if "%CHECK_ONLY%"=="1" (
    call :print_missing "%~3"
    exit /b 0
)

call :require_winget
if errorlevel 1 exit /b 1

set "INSTALL_CMD=!WINGET! install --id %~2 %WINGET_QUIET_ARGS%"
call :run_install_spinner "%~3 via winget: %~2" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :install_paths
if errorlevel 1 exit /b 1
call :refresh_path
call :find_command "%~1" "FOUND_TOOL_PATH"
if not errorlevel 1 (
    if "%INSTALL_EXIT%"=="0" (
        call :record_component "%~4"
        if "%VERBOSE%"=="1" echo   %FOUND_TOOL_PATH%
    )
    if not "%~5"=="" set "%~5=%FOUND_TOOL_PATH%"
    exit /b 0
)
if not "%INSTALL_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for %~3.
    echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] %~3 was not found after winget install.
echo Log: %TEMP%\cp_setup_winget.log
exit /b 1

:print_found
echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1
exit /b 0

:print_found_path
if "%VERBOSE%"=="1" (
    echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1: %~2
) else (
    call :print_found "%~1"
)
exit /b 0

:print_found_where
set "FOUND_PATH="
if "%VERBOSE%"=="1" (
    for /F "usebackq delims=" %%P in (`where "%~2" 2^>nul`) do (
        if not defined FOUND_PATH set "FOUND_PATH=%%P"
    )
    if defined FOUND_PATH (
        call :print_found_path "%~1" "!FOUND_PATH!"
    ) else (
        call :print_found "%~1"
    )
) else (
    call :print_found "%~1"
)
exit /b 0

:find_command
setlocal EnableExtensions EnableDelayedExpansion
set "FOUND_PATH="
for /F "usebackq delims=" %%P in (`where.exe "%~1" 2^>nul`) do if not defined FOUND_PATH set "FOUND_PATH=%%P"
if defined FOUND_PATH (
    endlocal & set "%~2=%FOUND_PATH%" & exit /b 0
)
endlocal & set "%~2=" & exit /b 1

:print_missing
set /A MISSING_COUNT+=1
echo [%ESC%[33mMISSING%ESC%[0m] %~1
exit /b 0

:search_command
setlocal EnableExtensions EnableDelayedExpansion
set "SEARCH_LABEL=%~1"
if /i "%~2"=="@env" (
    set "SEARCH_COMMAND=!SEARCH_COMMAND_INPUT!"
) else (
    set "SEARCH_COMMAND=%~2"
)
set "SEARCH_RESULT_FILE=%TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.txt"
set "SEARCH_PS=%TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.ps1"
> "%SEARCH_PS%" echo $label = $env:SEARCH_LABEL
>> "%SEARCH_PS%" echo $command = $env:SEARCH_COMMAND
>> "%SEARCH_PS%" echo $output = $env:SEARCH_RESULT_FILE
>> "%SEARCH_PS%" echo $esc = [char]27
>> "%SEARCH_PS%" echo $cr = [char]13
>> "%SEARCH_PS%" echo $clear = $esc + '[2K'
>> "%SEARCH_PS%" echo $searching = '[' + $esc + '[38;5;183mSEARCHING' + $esc + '[0m]'
>> "%SEARCH_PS%" echo $found = '[' + $esc + '[38;5;114mFOUND' + $esc + '[0m]'
>> "%SEARCH_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SEARCH_PS%" echo $job = Start-Job -ScriptBlock { param($command) $items = @(^& $env:ComSpec /d /c $command 2^>$null); [pscustomobject]@{ ExitCode = $LASTEXITCODE; Items = $items } } -ArgumentList $command
>> "%SEARCH_PS%" echo $i = 0
>> "%SEARCH_PS%" echo do { Write-Host -NoNewline ($cr + $clear + $searching + ' ' + $frames[$i %% $frames.Count] + ' ' + $label); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ } while ($job.State -eq 'Running')
>> "%SEARCH_PS%" echo $result = Receive-Job -Wait $job
>> "%SEARCH_PS%" echo Remove-Job $job -Force
>> "%SEARCH_PS%" echo $items = @($result.Items)
>> "%SEARCH_PS%" echo if ($items.Count) { [IO.File]::WriteAllLines($output,[string[]]$items) } else { [IO.File]::WriteAllText($output,'') }
>> "%SEARCH_PS%" echo $exitCode = [int]$result.ExitCode
>> "%SEARCH_PS%" echo if ($exitCode -eq 0) { $suffix = ''; if ($env:VERBOSE -eq '1' -and $items.Count) { $suffix = ': ' + $items[0] }; Write-Host ($cr + $clear + $found + ' ' + $label + $suffix) } else { Write-Host -NoNewline ($cr + $clear) }
>> "%SEARCH_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SEARCH_PS%"
set "SEARCH_EXIT=%ERRORLEVEL%"
set "SEARCH_VALUE="
for /F "usebackq delims=" %%P in ("%SEARCH_RESULT_FILE%") do if not defined SEARCH_VALUE set "SEARCH_VALUE=%%P"
del "%SEARCH_PS%" >nul 2>nul
del "%SEARCH_RESULT_FILE%" >nul 2>nul
endlocal & set "%~3=%SEARCH_VALUE%" & exit /b %SEARCH_EXIT%

:check_ac_library
call :ac_library_needs_update
if errorlevel 1 exit /b 1
if "%AC_LIBRARY_NEEDS_UPDATE%"=="1" call :print_missing "ac-library update"
exit /b 0

:update_ac_library_if_needed
call :ac_library_needs_update
if errorlevel 1 exit /b 1
if "%AC_LIBRARY_NEEDS_UPDATE%"=="0" exit /b 0
call :update_ac_library
exit /b %ERRORLEVEL%

:ac_library_needs_update
set "AC_LIBRARY_NEEDS_UPDATE=0"
if not defined FOUND_GIT_PATH exit /b 0
if not exist "%ROOT%\.gitmodules" exit /b 0
set "AC_LIBRARY_PATH=%ROOT%\libraries\ac-library"
if not exist "%AC_LIBRARY_PATH%\.git" (
    set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
set "AC_LIBRARY_LOCAL="
for /F "usebackq delims=" %%P in (`git -C "%AC_LIBRARY_PATH%" rev-parse HEAD 2^>nul`) do if not defined AC_LIBRARY_LOCAL set "AC_LIBRARY_LOCAL=%%P"
if not defined AC_LIBRARY_LOCAL (
    set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
call :search_command "ac-library" "git -C ""%AC_LIBRARY_PATH%"" ls-remote origin HEAD" "AC_LIBRARY_REMOTE"
if errorlevel 1 (
    set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
for /F "tokens=1" %%P in ("%AC_LIBRARY_REMOTE%") do set "AC_LIBRARY_REMOTE=%%P"
if /i not "%AC_LIBRARY_LOCAL%"=="%AC_LIBRARY_REMOTE%" set "AC_LIBRARY_NEEDS_UPDATE=1"
exit /b 0

:update_ac_library
if not defined FOUND_GIT_PATH exit /b 0
if not exist "%ROOT%\.gitmodules" exit /b 0
set "INSTALL_CMD=git -C "%ROOT%" submodule update --init --remote libraries/ac-library"
call :run_install_spinner "ac-library submodule" "" "%TEMP%\cp_setup_git.log"
set "AC_LIBRARY_EXIT=!ERRORLEVEL!"
if not "!AC_LIBRARY_EXIT!"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library submodule update failed.
    echo Log: %TEMP%\cp_setup_git.log
    exit /b 1
)
exit /b 0

:check_env_paths
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $esc=[char]27; $cr=[char]13; $clear=$esc+'[2K'; $check='['+$esc+'[38;5;183mCHECKING'+$esc+'[0m]'; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $failed='['+$esc+'[31mFAILED'+$esc+'[0m]'; $job=Start-Job -ScriptBlock { param($root) $c=@((Join-Path $root 'scripts'),'C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); $e=$c | Where-Object { Test-Path -LiteralPath $_ }; if (@($e).Count -gt 0) { 0 } else { 1 } } -ArgumentList $root; $frames=@([char]92,'-','/','|'); $i=0; while ($job.State -eq 'Running') { Write-Host -NoNewline ($cr+$clear+$check+' '+$frames[$i %% $frames.Count]+' Environment paths'); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }; $items=@(Receive-Job -Wait $job); Remove-Job $job -Force; if ($items.Count -eq 0) { $exitCode=1 } else { $exitCode=[int]$items[-1] }; if ($exitCode -eq 0) { Write-Host ($cr+$clear+$found+' Environment paths') } else { Write-Host ($cr+$clear+$failed+' Environment paths') }; exit $exitCode"
exit /b %ERRORLEVEL%

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
if /i "%~1"=="quiet" goto locate_msys2_shell
if defined MSYS2_SHELL exit /b 0
set "MSYS2_FINDER=%TEMP%\cp_setup_find_msys2_%RANDOM%_%RANDOM%.cmd"
> "%MSYS2_FINDER%" echo @echo off
>> "%MSYS2_FINDER%" echo if exist "C:\msys64\msys2_shell.cmd" ^(
>> "%MSYS2_FINDER%" echo     echo C:\msys64\msys2_shell.cmd
>> "%MSYS2_FINDER%" echo     exit /b 0
>> "%MSYS2_FINDER%" echo ^)
>> "%MSYS2_FINDER%" echo if exist "D:\software\programming\msys2\msys2_shell.cmd" ^(
>> "%MSYS2_FINDER%" echo     echo D:\software\programming\msys2\msys2_shell.cmd
>> "%MSYS2_FINDER%" echo     exit /b 0
>> "%MSYS2_FINDER%" echo ^)
>> "%MSYS2_FINDER%" echo where.exe msys2_shell.cmd
>> "%MSYS2_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%MSYS2_FINDER%"""
call :search_command "MSYS2" "@env" "MSYS2_SHELL"
set "MSYS2_EXIT=!ERRORLEVEL!"
del "%MSYS2_FINDER%" >nul 2>nul
exit /b !MSYS2_EXIT!

:locate_msys2_shell
set "MSYS2_SHELL="
if exist "C:\msys64\msys2_shell.cmd" set "MSYS2_SHELL=C:\msys64\msys2_shell.cmd"
if not defined MSYS2_SHELL if exist "D:\software\programming\msys2\msys2_shell.cmd" set "MSYS2_SHELL=D:\software\programming\msys2\msys2_shell.cmd"
if defined MSYS2_SHELL exit /b 0
for /F "usebackq delims=" %%P in (`where msys2_shell.cmd 2^>nul`) do if not defined MSYS2_SHELL set "MSYS2_SHELL=%%P"
if defined MSYS2_SHELL exit /b 0
exit /b 1

:install_msys2_toolchain
call :require_winget
if errorlevel 1 exit /b 1
call :find_msys2_shell
if errorlevel 1 (
    set "INSTALL_CMD=!WINGET! install --id MSYS2.MSYS2 %WINGET_QUIET_ARGS%"
    call :run_install_spinner "MSYS2 via winget: MSYS2.MSYS2" "" "%TEMP%\cp_setup_winget.log"
    set "INSTALL_EXIT=%ERRORLEVEL%"
    call :find_msys2_shell quiet
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for MSYS2.
        echo Log: %TEMP%\cp_setup_winget.log
        exit /b 1
    )
    if "%INSTALL_EXIT%"=="0" (
        call :record_component "Winget.MSYS2"
        if "%VERBOSE%"=="1" echo   %MSYS2_SHELL%
    )
)
set "PACMAN_COMMAND=pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff"
call :run_pacman_spinner "INSTALLING" "INSTALLED"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain install failed.
    echo Log: %TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :record_component "Pacman.Toolchain"
exit /b %ERRORLEVEL%

:run_pacman_spinner
set "PACMAN_ACTION=%~1"
set "PACMAN_SUCCESS=%~2"
if not defined PACMAN_ACTION set "PACMAN_ACTION=INSTALLING"
if not defined PACMAN_SUCCESS set "PACMAN_SUCCESS=INSTALLED"
set "SPIN_PS=%TEMP%\cp_setup_pacman_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo $label = 'MSYS2 toolchain via pacman'
>> "%SPIN_PS%" echo $hint = 'this may take a while'
>> "%SPIN_PS%" echo $log = Join-Path $env:TEMP 'cp_setup_pacman.log'
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:TEMP ('cp_setup_pacman_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:PACMAN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:PACMAN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $shell = $null
>> "%SPIN_PS%" echo foreach ($path in @('C:\msys64\msys2_shell.cmd','D:\software\programming\msys2\msys2_shell.cmd')) { if (Test-Path -LiteralPath $path) { $shell = $path; break } }
>> "%SPIN_PS%" echo if (-not $shell) { $cmd = Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue; if ($cmd) { $shell = $cmd.Source } }
>> "%SPIN_PS%" echo if (-not $shell) { 'Could not find msys2_shell.cmd after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($action + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $bash = Join-Path (Split-Path -Parent $shell) 'usr\bin\bash.exe'
>> "%SPIN_PS%" echo if (-not (Test-Path -LiteralPath $bash)) { 'Could not find MSYS2 bash.exe after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($action + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $pacman = $env:PACMAN_COMMAND
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $q + $bash + $q + ' -lc ' + $q + $pacman + $q + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off','set "MSYSTEM=MINGW64"','set "CHERE_INVOKING=enabled_from_arguments"',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $job = Start-Job -ScriptBlock { param($wrapper) ^& $env:ComSpec /d /c call $wrapper; $LASTEXITCODE } -ArgumentList $wrapper
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo while ($job.State -eq 'Running') { Write-Host -NoNewline ($cr + $clear + $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label + ' (' + $hint + ')'); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%SPIN_PS%" echo Remove-Job $job -Force
>> "%SPIN_PS%" echo $jobItems = @($jobResult)
>> "%SPIN_PS%" echo if ($jobItems.Count -eq 0) { $exitCode = 1 } else { $exitCode = [int]$jobItems[-1] }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0) { Write-Host ($cr + $clear + $success + ' ' + $label) } else { Write-Host ($cr + $clear + '[' + $esc + '[31mFAILED' + $esc + '[0m] ' + $label) }
>> "%SPIN_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
del "%SPIN_PS%" >nul 2>nul
exit /b %SPIN_EXIT%

:run_install_spinner
set "SPIN_LABEL=%~1"
set "SPIN_HINT=%~2"
set "SPIN_LOG=%~3"
set "SPIN_ACTION=%~4"
set "SPIN_SUCCESS=%~5"
if not defined SPIN_ACTION set "SPIN_ACTION=INSTALLING"
if not defined SPIN_SUCCESS set "SPIN_SUCCESS=INSTALLED"
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
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:SPIN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:SPIN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $cmd + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $job = Start-Job -ScriptBlock { param($wrapper) ^& $env:ComSpec /d /c call $wrapper; $LASTEXITCODE } -ArgumentList $wrapper
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo while ($job.State -eq 'Running') { $text = $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label; if ($hint) { $text += ' (' + $hint + ')' }; Write-Host -NoNewline ($cr + $clear + $text); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%SPIN_PS%" echo Remove-Job $job -Force
>> "%SPIN_PS%" echo $jobItems = @($jobResult)
>> "%SPIN_PS%" echo if ($jobItems.Count -eq 0) { $exitCode = 1 } else { $exitCode = [int]$jobItems[-1] }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0) { Write-Host ($cr + $clear + $success + ' ' + $label) } else { Write-Host ($cr + $clear + '[' + $esc + '[31mFAILED' + $esc + '[0m] ' + $label) }
>> "%SPIN_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
del "%SPIN_PS%" >nul 2>nul
exit /b %SPIN_EXIT%

:install_paths
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $check='%~1' -ieq 'check'; $verbose='%VERBOSE%' -eq '1'; $esc=[char]27; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $jdkBins=@(); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $jdkBins=Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $c=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin') + $jdkBins; $e=$c | Where-Object { Test-Path -LiteralPath $_ }; if ($check) { if ($verbose) { Write-Host ($found+' Environment paths:'); foreach ($p in $e) { Write-Host ('  '+$p) } } else { Write-Host \"[$($esc)[38;5;183mCHECKING$($esc)[0m] Environment paths\" }; exit 0 }; $u=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $u) { $u='' }; $known=@($env:LOCALAPPDATA + '\Microsoft\WindowsApps') + $c; $known=$known | Where-Object { $_ } | Sort-Object Length -Descending -Unique; $parts=New-Object System.Collections.Generic.List[string]; foreach ($raw in ($u -split ';')) { $s=$raw.Trim(); while ($s) { $hit=$null; $hitAt=-1; foreach ($k in $known) { $i=$s.IndexOf($k, [StringComparison]::OrdinalIgnoreCase); if ($i -ge 0 -and ($hitAt -lt 0 -or $i -lt $hitAt -or ($i -eq $hitAt -and $k.Length -gt $hit.Length))) { $hit=$k; $hitAt=$i } }; if (-not $hit) { $parts.Add($s); break }; if ($hitAt -gt 0) { $prefix=$s.Substring(0,$hitAt).Trim(); if ($prefix) { $parts.Add($prefix) } }; $parts.Add($hit); $s=$s.Substring($hitAt + $hit.Length).Trim() } }; foreach ($p in $e) { $parts.Add($p) }; $clean=New-Object System.Collections.Generic.List[string]; foreach ($p in $parts) { $v=$p.Trim().TrimEnd('\'); if (-not $v) { continue }; $exists=$false; foreach ($x in $clean) { if ($x.TrimEnd('\') -ieq $v) { $exists=$true; break } }; if (-not $exists) { $clean.Add($v) } }; [Environment]::SetEnvironmentVariable('Path',($clean -join ';'),'User')"
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\Microsoft\Command Processor'; if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }; $command='doskey /macrofile=\"'+$env:MACROS+'\"'; $current=(Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; if (-not $current) { Set-ItemProperty -Path $key -Name AutoRun -Value $command } elseif ($current.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -lt 0) { Set-ItemProperty -Path $key -Name AutoRun -Value ($current.TrimEnd()+' & '+$command) }"
if errorlevel 1 (
    echo Failed to update cmd AutoRun.
    exit /b 1
)
doskey /macrofile="%MACROS%"
exit /b 0

:record_component
if "%~1"=="" exit /b 0
reg add "%STATE_KEY%" /v "%~1" /t REG_DWORD /d 1 /f >nul
exit /b %ERRORLEVEL%

:ensure_ruff
call :search_command "Ruff" "where.exe ruff" "FOUND_RUFF_PATH"
if not errorlevel 1 exit /b 0
if "%CHECK_ONLY%"=="1" (
    call :print_missing "Ruff"
    exit /b 0
)
call :install_msys2_toolchain
exit /b %ERRORLEVEL%

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:find_python
if /i "%~1"=="quiet" goto locate_python
set "PYTHON_FINDER=%TEMP%\cp_setup_find_python_%RANDOM%_%RANDOM%.cmd"
> "%PYTHON_FINDER%" echo @echo off
>> "%PYTHON_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_PYTHON) { $c += $env:CP_PYTHON }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe','D:\software\programming\msys2\mingw64\bin\python.exe','D:\software\programming\msys2\ucrt64\bin\python.exe'); $w=where.exe python 2^>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2^>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p)) { Write-Output $p; exit 0 } }; exit 1"
>> "%PYTHON_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%PYTHON_FINDER%"""
call :search_command "Python" "@env" "CP_PYTHON"
set "FIND_EXIT=!ERRORLEVEL!"
del "%PYTHON_FINDER%" >nul 2>nul
exit /b !FIND_EXIT!

:locate_python
set "CP_PYTHON="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_PYTHON) { $c += $env:CP_PYTHON }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe','D:\software\programming\msys2\mingw64\bin\python.exe','D:\software\programming\msys2\ucrt64\bin\python.exe'); $w=where.exe python 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output $p; exit 0 } } }; exit 1"`) do set "CP_PYTHON=%%P"
if defined CP_PYTHON exit /b 0
exit /b 1

:find_gpp
if /i "%~1"=="quiet" goto locate_gpp
set "GPP_FINDER=%TEMP%\cp_setup_find_gpp_%RANDOM%_%RANDOM%.cmd"
> "%GPP_FINDER%" echo @echo off
>> "%GPP_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_GPP) { $c += $env:CP_GPP }; $c += @('C:\msys64\mingw64\bin\g++.exe','C:\msys64\ucrt64\bin\g++.exe','D:\software\programming\msys2\mingw64\bin\g++.exe','D:\software\programming\msys2\ucrt64\bin\g++.exe'); $w=where.exe g++ 2^>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p)) { Write-Output $p; exit 0 } }; exit 1"
>> "%GPP_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%GPP_FINDER%"""
call :search_command "g++" "@env" "CP_GPP"
set "FIND_EXIT=!ERRORLEVEL!"
del "%GPP_FINDER%" >nul 2>nul
if not "!FIND_EXIT!"=="0" exit /b !FIND_EXIT!
for %%I in ("%CP_GPP%") do set "PATH=%%~dpI;%PATH%"
exit /b 0

:locate_gpp
set "CP_GPP="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=@(); if ($env:CP_GPP) { $c += $env:CP_GPP }; $c += @('C:\msys64\mingw64\bin\g++.exe','C:\msys64\ucrt64\bin\g++.exe','D:\software\programming\msys2\mingw64\bin\g++.exe','D:\software\programming\msys2\ucrt64\bin\g++.exe'); $w=where.exe g++ 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output $p; exit 0 } } }; exit 1"`) do set "CP_GPP=%%P"
if defined CP_GPP (
    for %%I in ("%CP_GPP%") do set "PATH=%%~dpI;%PATH%"
    exit /b 0
)
exit /b 1

:verify
if not defined CP_GPP (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ is not visible during verification.
    exit /b 1
)
if not defined FOUND_NVIM_PATH (
    echo [%ESC%[31mFAILED%ESC%[0m] nvim is not visible during verification.
    exit /b 1
)
if not defined CP_PYTHON (
    echo [%ESC%[31mFAILED%ESC%[0m] Python is not visible during verification.
    exit /b 1
)
if not defined FOUND_JAVAC_PATH (
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

echo [%ESC%[38;5;114mVERIFIED%ESC%[0m] Verification passed
exit /b 0

:verify_failed
call :cleanup_verify
exit /b 1

:ensure_spinner
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "Join-Path $env:TEMP ('cp_setup_spinner_' + [guid]::NewGuid().ToString('N') + '.py')"`) do set "SPINNER_PY=%%P"
> "%SPINNER_PY%" echo import argparse
>> "%SPINNER_PY%" echo import ctypes
>> "%SPINNER_PY%" echo import subprocess
>> "%SPINNER_PY%" echo import sys
>> "%SPINNER_PY%" echo import time
>> "%SPINNER_PY%" echo from pathlib import Path
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo ESC = chr(27)
>> "%SPINNER_PY%" echo PURPLE = ESC + "[38;5;183m"
>> "%SPINNER_PY%" echo GREEN = ESC + "[38;5;114m"
>> "%SPINNER_PY%" echo RED = ESC + "[31m"
>> "%SPINNER_PY%" echo RESET = ESC + "[0m"
>> "%SPINNER_PY%" echo CLEAR = ESC + "[2K"
>> "%SPINNER_PY%" echo FRAMES = [chr(92), "-", "/", chr(124)]
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo def enable_ansi():
>> "%SPINNER_PY%" echo     if not sys.platform == "win32":
>> "%SPINNER_PY%" echo         return
>> "%SPINNER_PY%" echo     kernel32 = ctypes.windll.kernel32
>> "%SPINNER_PY%" echo     handle = kernel32.GetStdHandle(-11)
>> "%SPINNER_PY%" echo     mode = ctypes.c_uint32()
>> "%SPINNER_PY%" echo     if kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
>> "%SPINNER_PY%" echo         kernel32.SetConsoleMode(handle, mode.value ^| 4)
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo def main() -^> int:
>> "%SPINNER_PY%" echo     enable_ansi()
>> "%SPINNER_PY%" echo     parser = argparse.ArgumentParser()
>> "%SPINNER_PY%" echo     parser.add_argument("--label", required=True)
>> "%SPINNER_PY%" echo     parser.add_argument("--cwd", default=str(Path.cwd()))
>> "%SPINNER_PY%" echo     parser.add_argument("--stdin-empty", action="store_true")
>> "%SPINNER_PY%" echo     parser.add_argument("command", nargs=argparse.REMAINDER)
>> "%SPINNER_PY%" echo     args = parser.parse_args()
>> "%SPINNER_PY%" echo     command = args.command[1:] if args.command and args.command[0] == "--" else args.command
>> "%SPINNER_PY%" echo     if not command:
>> "%SPINNER_PY%" echo         print("spinner: missing command", file=sys.stderr)
>> "%SPINNER_PY%" echo         return 1
>> "%SPINNER_PY%" echo     stdin = subprocess.DEVNULL if args.stdin_empty else None
>> "%SPINNER_PY%" echo     process = subprocess.Popen(command, cwd=args.cwd, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
>> "%SPINNER_PY%" echo     index = 0
>> "%SPINNER_PY%" echo     while process.poll() is None:
>> "%SPINNER_PY%" echo         print("\r{}[{}VERIFYING{}] {} {}".format(CLEAR, PURPLE, RESET, FRAMES[index %% len(FRAMES)], args.label), end="", flush=True)
>> "%SPINNER_PY%" echo         time.sleep(0.1)
>> "%SPINNER_PY%" echo         index += 1
>> "%SPINNER_PY%" echo     stdout, stderr = process.communicate()
>> "%SPINNER_PY%" echo     if process.returncode == 0:
>> "%SPINNER_PY%" echo         print("\r{}[{}VERIFIED{}] {}".format(CLEAR, GREEN, RESET, args.label))
>> "%SPINNER_PY%" echo         return 0
>> "%SPINNER_PY%" echo     print("\r{}[{}FAILED{}] {}".format(CLEAR, RED, RESET, args.label), file=sys.stderr)
>> "%SPINNER_PY%" echo     if stderr:
>> "%SPINNER_PY%" echo         print(stderr, file=sys.stderr, end="")
>> "%SPINNER_PY%" echo     if stdout:
>> "%SPINNER_PY%" echo         print(stdout, file=sys.stderr, end="")
>> "%SPINNER_PY%" echo     return process.returncode
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo if __name__ == "__main__":
>> "%SPINNER_PY%" echo     raise SystemExit(main())
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
