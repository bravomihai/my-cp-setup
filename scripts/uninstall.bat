@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "ORIGINAL_ARGS=%*"

set "CHECK_ONLY=0"
set "ALL_MODE=0"
set "CAN_REMOVE_REPO=1"
set "CONFIG_REMOVED=0"
set "STATE_KEY=HKCU\Software\my-cp-setup"

:parse_args
if "%~1"=="" goto parsed_args
if /i "%~1"=="--check" (
    if "%ALL_MODE%"=="1" goto incompatible_args
    set "CHECK_ONLY=1"
    shift
    goto parse_args
)
if /i "%~1"=="--all" (
    if "%CHECK_ONLY%"=="1" goto incompatible_args
    set "ALL_MODE=1"
    shift
    goto parse_args
)
echo [%ESC%[31mFAILED%ESC%[0m] Unknown argument: %~1
exit /b 1

:incompatible_args
echo [%ESC%[31mFAILED%ESC%[0m] Use either --check or --all, not both.
exit /b 1

:parsed_args
if "%CHECK_ONLY%"=="0" (
    call :ensure_admin
    if errorlevel 2 exit /b 0
    if errorlevel 1 exit /b 1
)
call :enable_ansi
call :refresh_path

echo CP setup root:
echo %ROOT%
echo.

if "%CHECK_ONLY%"=="1" (
    call :check_state
    exit /b %ERRORLEVEL%
)

if "%ALL_MODE%"=="1" (
    call :remove_all_external_components
) else (
    call :remove_external_components
)
if errorlevel 1 goto failed

if "%ALL_MODE%"=="0" (
    echo.
    call :ask_yes_no "Remove CP setup configuration"
    if errorlevel 1 (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] CP setup configuration
        set "CAN_REMOVE_REPO=0"
        goto decide_repo_removal
    )
)

echo.
echo [%ESC%[38;5;183mCHECKING%ESC%[0m] CP setup configuration
call :remove_path_entries
if errorlevel 1 goto failed

call :remove_env_vars
if errorlevel 1 goto failed

call :remove_cmd_macros
if errorlevel 1 goto failed

call :clear_empty_state
set "CONFIG_REMOVED=1"

:decide_repo_removal
if "%ALL_MODE%"=="0" if not "%CAN_REMOVE_REPO%"=="1" goto repo_kept

echo.
call :ask_yes_no "Remove this CP setup folder too"
if not errorlevel 1 (
    reg delete "%STATE_KEY%" /f >nul 2>nul
    call :schedule_repo_removal
    if errorlevel 1 goto failed
    call :print_completion
    echo [%ESC%[38;5;153mREMOVING%ESC%[0m] CP setup folder shortly.
    echo Restart terminals so environment changes are visible everywhere.
    exit /b 0
)

echo.
call :print_completion
echo [%ESC%[38;5;244mKEPT%ESC%[0m] CP setup folder.
echo Restart terminals so environment changes are visible everywhere.
exit /b 0

:repo_kept
echo.
call :print_completion
echo [%ESC%[38;5;244mKEPT%ESC%[0m] CP setup folder because setup components or configuration were kept.
echo Restart terminals so environment changes are visible everywhere.
exit /b 0

:print_completion
if not "%CONFIG_REMOVED%"=="1" exit /b 0
if "%ALL_MODE%"=="1" (
    echo [%ESC%[32mDONE%ESC%[0m] All setup-managed components and configuration were removed.
) else (
    echo [%ESC%[32mDONE%ESC%[0m] CP setup configuration removed.
    echo External components you kept remain installed.
)
exit /b 0

:enable_ansi
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
exit /b 0

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:ensure_admin
powershell -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1"
if not errorlevel 1 exit /b 0

set "ELEVATE_PS=%TEMP%\cp_setup_uninstall_elevate_%RANDOM%_%RANDOM%.ps1"
set "ELEVATE_LOG=%TEMP%\cp_setup_uninstall_elevate.log"
set "ELEVATE_EXIT_FILE=%TEMP%\cp_setup_uninstall_elevate_exit_%RANDOM%_%RANDOM%.txt"
set "ELEVATE_STARTED_FILE=%TEMP%\cp_setup_uninstall_elevate_started_%RANDOM%_%RANDOM%.txt"
set "ELEVATE_CMD=%TEMP%\cp_setup_uninstall_elevate_%RANDOM%_%RANDOM%.cmd"
set "ELEVATE_DELETE_SIGNAL=%TEMP%\cp_setup_uninstall_delete_%RANDOM%_%RANDOM%.txt"
set "CP_UNINSTALL_SCRIPT=%~f0"
set "CP_UNINSTALL_ARGS=%ORIGINAL_ARGS%"
set "CP_UNINSTALL_CWD=%ROOT%"
set "CP_DELETE_SIGNAL=%ELEVATE_DELETE_SIGNAL%"
del "%ELEVATE_DELETE_SIGNAL%" >nul 2>nul
> "%ELEVATE_CMD%" echo @echo off
>> "%ELEVATE_CMD%" echo ^> "%ELEVATE_EXIT_FILE%" echo 900
>> "%ELEVATE_CMD%" echo cd /d "%CP_UNINSTALL_CWD%"
>> "%ELEVATE_CMD%" echo call "%CP_UNINSTALL_SCRIPT%" %CP_UNINSTALL_ARGS%
>> "%ELEVATE_CMD%" echo set "CP_SETUP_EXIT=%%ERRORLEVEL%%"
>> "%ELEVATE_CMD%" echo ^> "%ELEVATE_EXIT_FILE%" echo %%CP_SETUP_EXIT%%
>> "%ELEVATE_CMD%" echo if exist "%ELEVATE_DELETE_SIGNAL%" cd /d "%%TEMP%%"
>> "%ELEVATE_CMD%" echo if exist "%ELEVATE_DELETE_SIGNAL%" exit /b %%CP_SETUP_EXIT%%
>> "%ELEVATE_CMD%" echo echo.
>> "%ELEVATE_CMD%" echo echo Press any key to exit...
>> "%ELEVATE_CMD%" echo pause ^>nul
>> "%ELEVATE_CMD%" echo exit /b %%CP_SETUP_EXIT%%
> "%ELEVATE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ELEVATE_PS%" echo $requestLabel = 'Requesting administrator rights...'
>> "%ELEVATE_PS%" echo $uninstallLabel = 'Administrator rights granted, uninstalling...'
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
>> "%ELEVATE_PS%" echo $job = Start-Job -ScriptBlock { param($cmdPath,$cwd,$log,$startedFile) try { $p = Start-Process -FilePath $cmdPath -WorkingDirectory $cwd -Verb RunAs -PassThru; 'started' ^| Set-Content -LiteralPath $startedFile; $p.WaitForExit(); 0 } catch { $_ ^| Out-String ^| Set-Content -LiteralPath $log; 1 } } -ArgumentList $cmdPath,$env:CP_UNINSTALL_CWD,$log,$startedFile
>> "%ELEVATE_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%ELEVATE_PS%" echo $i = 0
>> "%ELEVATE_PS%" echo while ($job.State -eq 'Running') { if (Test-Path -LiteralPath $startedFile) { $label = $uninstallLabel } else { $label = $requestLabel }; Write-Host -NoNewline ($cr + $clear + $frames[$i %% $frames.Count] + ' ' + $label); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }
>> "%ELEVATE_PS%" echo $jobResult = Receive-Job -Wait $job
>> "%ELEVATE_PS%" echo Remove-Job $job -Force
>> "%ELEVATE_PS%" echo $items = @($jobResult)
>> "%ELEVATE_PS%" echo Remove-Item -LiteralPath $startedFile -ErrorAction SilentlyContinue
>> "%ELEVATE_PS%" echo if ($items.Count -eq 0 -or [int]$items[-1] -ne 0) {
>> "%ELEVATE_PS%" echo     $details = ''
>> "%ELEVATE_PS%" echo     if (Test-Path -LiteralPath $log) { $details = Get-Content -LiteralPath $log -Raw }
>> "%ELEVATE_PS%" echo     if ($details -match 'canceled by the user') { Write-Host ($cr + $clear + $red + 'Uninstall canceled by user.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo     if ($details -match 'Access is denied') { Write-Host ($cr + $clear + $red + 'Uninstall failed: administrator rights were denied.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo     Write-Host ($cr + $clear + $red + 'Uninstall failed while requesting administrator rights.' + $reset)
>> "%ELEVATE_PS%" echo     if ($details) { Write-Host $details }
>> "%ELEVATE_PS%" echo     exit 1
>> "%ELEVATE_PS%" echo }
>> "%ELEVATE_PS%" echo if (-not (Test-Path -LiteralPath $exitFile)) { Write-Host ($cr + $clear + $red + 'Uninstall failed: uninstaller did not report an exit code.' + $reset); exit 1 }
>> "%ELEVATE_PS%" echo $childExit = [int]((Get-Content -LiteralPath $exitFile -ErrorAction Stop ^| Select-Object -First 1).Trim())
>> "%ELEVATE_PS%" echo Remove-Item -LiteralPath $exitFile -ErrorAction SilentlyContinue
>> "%ELEVATE_PS%" echo if ($childExit -eq 0) { Write-Host ($cr + $clear + $green + 'Uninstall completed' + $reset); exit 0 }
>> "%ELEVATE_PS%" echo Write-Host ($cr + $clear + $red + ('Uninstall failed: elevated uninstaller exited with code ' + $childExit) + $reset)
>> "%ELEVATE_PS%" echo exit 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%ELEVATE_PS%"
set "ELEVATE_EXIT=%ERRORLEVEL%"
del "%ELEVATE_PS%" >nul 2>nul
del "%ELEVATE_CMD%" >nul 2>nul
set "SCHEDULE_EXIT=0"
if exist "%ELEVATE_DELETE_SIGNAL%" (
    cd /d "%TEMP%"
    set "CP_DELETE_SIGNAL="
    call :schedule_repo_removal
    set "SCHEDULE_EXIT=!ERRORLEVEL!"
)
del "%ELEVATE_DELETE_SIGNAL%" >nul 2>nul
if not "%ELEVATE_EXIT%"=="0" exit /b 1
if not "%SCHEDULE_EXIT%"=="0" exit /b 1
exit /b 2

:check_state
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $macros=Join-Path $root 'scripts\cp_macros'; $command='doskey /macrofile=\"'+$macros+'\"'; $key='HKCU:\Software\my-cp-setup'; $owned=@((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue).'Path.Entries' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }); $path=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($path -split ';' | ForEach-Object { $_.Trim().TrimEnd('\') } | Where-Object { $_ }); $foundPath=@($parts | Where-Object { $owned -icontains $_ }); $vars=@('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP') | ForEach-Object { $v=[Environment]::GetEnvironmentVariable($_,'User'); if ($v) { [pscustomobject]@{Name=$_;Value=$v} } }; $autorun=(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; $hasMacro=$autorun -and $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -ge 0; $esc=[char]27; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $missing='['+$esc+'[33mMISSING'+$esc+'[0m]'; $clear='['+$esc+'[38;5;114mCLEAR'+$esc+'[0m]'; if ($foundPath.Count) { Write-Host ($found+' PATH entries managed by setup') } else { Write-Host ($missing+' PATH entries managed by setup') }; foreach ($v in $vars) { Write-Host ($found+' '+$v.Name+'='+$v.Value) }; if (-not $vars) { Write-Host ($clear+' CP environment variables') }; if ($hasMacro) { Write-Host ($found+' CMD AutoRun loads cp_macros') } else { Write-Host ($clear+' CMD AutoRun for cp_macros') }"
if errorlevel 1 exit /b 1
for %%V in (Winget.Git Winget.Neovim Winget.JDK Winget.MSYS2 Pacman.Toolchain) do (
    call :state_has "%%V"
    if not errorlevel 1 echo [%ESC%[38;5;114mFOUND%ESC%[0m] %%V installed by this setup
)
exit /b 0

:remove_path_entries
powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $missing='['+$esc+'[33mMISSING'+$esc+'[0m]'; $owned=@((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue).'Path.Entries' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }); if (-not $owned.Count) { Write-Host ($missing+' User PATH entries managed by setup'); exit 0 }; $path=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $path) { $path='' }; $parts=@($path -split ';' | Where-Object { $_ }); $found=@($parts | Where-Object { $owned -icontains $_.Trim().TrimEnd('\') }); if (-not $found.Count) { Remove-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue; Write-Host ($missing+' User PATH entries managed by setup'); exit 0 }; $kept=@($parts | Where-Object { -not ($owned -icontains $_.Trim().TrimEnd('\')) }); [Environment]::SetEnvironmentVariable('Path',($kept -join ';'),'User'); Remove-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue; Write-Host ($removed+' User PATH entries managed by setup')"
exit /b %ERRORLEVEL%

:remove_env_vars
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $exact=@{XDG_CONFIG_HOME=$root; CP_SETUP_ROOT=$root}; foreach ($name in $exact.Keys) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if ($v -and $v.TrimEnd('\') -ieq $exact[$name].TrimEnd('\')) { [Environment]::SetEnvironmentVariable($name,$null,'User'); Write-Host ($removed+' '+$name) } }; $bases=@('C:\msys64','D:\software\programming\msys2'); foreach ($name in @('CP_PYTHON','CP_GPP')) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if (-not $v) { continue }; foreach ($base in $bases) { if ($v.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { [Environment]::SetEnvironmentVariable($name,$null,'User'); Write-Host ($removed+' '+$name); break } } }"
exit /b %ERRORLEVEL%

:remove_cmd_macros
set "MACROS=%ROOT%\scripts\cp_macros"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$macros=$env:MACROS; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $key='HKCU:\Software\Microsoft\Command Processor'; $command='doskey /macrofile=\"'+$macros+'\"'; $autorun=(Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; if ($autorun -and $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $pattern='(?i)(?:^\s*|\s*&\s*)'+[regex]::Escape($command)+'(?=\s*(?:&|$))'; $updated=[regex]::Replace($autorun,$pattern,'').Trim(); $updated=[regex]::Replace($updated,'^\s*&\s*',''); $updated=[regex]::Replace($updated,'\s*&\s*$',''); if ($updated) { Set-ItemProperty -Path $key -Name AutoRun -Value $updated } else { Remove-ItemProperty -Path $key -Name AutoRun -ErrorAction Stop }; Write-Host ($removed+' CMD AutoRun cp_macros') }"
exit /b %ERRORLEVEL%

:remove_external_components
call :state_has "Winget.Git"
if not errorlevel 1 (
    call :uninstall_git
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Git" "git"
)

call :state_has "Winget.Neovim"
if not errorlevel 1 (
    call :uninstall_winget_component "Neovim" "Neovim.Neovim" "nvim" "Winget.Neovim" "Neovim and generated LazyVim data"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Neovim" "nvim"
)

call :state_has "Winget.JDK"
if not errorlevel 1 (
    call :uninstall_winget_component "JDK" "EclipseAdoptium.Temurin.21.JDK" "javac" "Winget.JDK"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "JDK" "javac"
)

call :state_has "Winget.MSYS2"
if errorlevel 1 (
    call :report_unmanaged_msys2
    goto maybe_pacman
)
call :find_msys2_shell
if errorlevel 1 (
    call :print_missing "MSYS2"
    call :clear_state "Winget.MSYS2"
    call :clear_state "Pacman.Toolchain"
    echo.
    exit /b 0
)

call :ask_yes_no "Uninstall MSYS2 and its CP toolchain"
if errorlevel 1 (
    set "CAN_REMOVE_REPO=0"
    echo.
    goto maybe_pacman
)

call :remove_pacman_toolchain_if_present
if errorlevel 1 exit /b 1
call :uninstall_msys2
if errorlevel 1 exit /b 1
call :clear_state "Winget.MSYS2"
echo.
exit /b 0

:maybe_pacman
call :state_has "Pacman.Toolchain"
if errorlevel 1 exit /b 0
call :has_pacman_toolchain
if errorlevel 1 (
    call :print_missing "MSYS2 CP toolchain"
    call :clear_state "Pacman.Toolchain"
    echo.
    exit /b 0
)
call :uninstall_pacman_toolchain
exit /b %ERRORLEVEL%

:remove_all_external_components
call :state_has "Winget.Git"
if not errorlevel 1 (
    call :uninstall_git
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Git" "git"
)

call :state_has "Winget.Neovim"
if not errorlevel 1 (
    call :uninstall_winget_component "Neovim" "Neovim.Neovim" "nvim" "Winget.Neovim" "Neovim and generated LazyVim data"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Neovim" "nvim"
)

call :state_has "Winget.JDK"
if not errorlevel 1 (
    call :uninstall_winget_component "JDK" "EclipseAdoptium.Temurin.21.JDK" "javac" "Winget.JDK"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "JDK" "javac"
)

call :state_has "Winget.MSYS2"
if not errorlevel 1 (
    call :find_msys2_shell
    if errorlevel 1 (
        call :print_missing "MSYS2"
        call :clear_state "Winget.MSYS2"
        call :clear_state "Pacman.Toolchain"
        echo.
    ) else (
        call :remove_pacman_toolchain_if_present
        if errorlevel 1 exit /b 1
        call :uninstall_msys2
        if errorlevel 1 exit /b 1
        call :clear_state "Winget.MSYS2"
    )
    exit /b 0
)

call :report_unmanaged_msys2

call :state_has "Pacman.Toolchain"
if not errorlevel 1 (
    call :find_msys2_shell
    if errorlevel 1 (
        call :print_missing "MSYS2 CP toolchain"
        call :clear_state "Pacman.Toolchain"
        echo.
    ) else (
        call :uninstall_pacman_toolchain
        if errorlevel 1 exit /b 1
    )
) else if defined MSYS2_SHELL (
    call :has_pacman_toolchain
    if not errorlevel 1 (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 CP toolchain was not installed by CP setup.
        echo.
    )
)
exit /b 0

:uninstall_winget_component
call :search_command "%~1" "where.exe %~3" "FOUND_COMPONENT_PATH"
if errorlevel 1 (
    call :print_missing "%~1"
    call :clear_state "%~4"
    if "%ALL_MODE%"=="1" if /I "%~4"=="Winget.Neovim" call :remove_nvim_generated_data
    echo.
    exit /b 0
)

call :winget_has_package "%~2"
if errorlevel 1 (
    if "%ALL_MODE%"=="1" (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1 is not registered with winget.
        call :clear_state "%~4"
        echo.
        exit /b 0
    )
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1 is not registered with winget.
    call :clear_state "%~4"
    echo.
    exit /b 0
)

if "%ALL_MODE%"=="0" (
    set "UNINSTALL_PROMPT=%~5"
    if not defined UNINSTALL_PROMPT set "UNINSTALL_PROMPT=%~1"
    call :ask_yes_no "Uninstall !UNINSTALL_PROMPT!"
    if errorlevel 1 (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1
        set "CAN_REMOVE_REPO=0"
        echo.
        exit /b 0
    )
)

call :uninstall_winget_now "%~1" "%~2"
if errorlevel 1 exit /b 1
call :clear_state "%~4"
if /I "%~4"=="Winget.Neovim" (
    call :remove_nvim_generated_data
    if errorlevel 1 exit /b 1
)
echo.
exit /b 0

:report_unmanaged_command
call :search_command "%~1" "where.exe %~2" "UNMANAGED_COMPONENT_PATH"
if errorlevel 1 (
    call :print_missing "%~1"
    echo.
    exit /b 0
)
echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1 was not installed by CP setup.
echo.
exit /b 0

:report_unmanaged_msys2
call :find_msys2_shell
if errorlevel 1 (
    call :print_missing "MSYS2"
    echo.
    exit /b 0
)
echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 was not installed by CP setup.
echo.
exit /b 0

:uninstall_git
call :search_command "Git" "where.exe git" "FOUND_GIT_PATH"
if errorlevel 1 (
    call :print_missing "Git"
    call :clear_state "Winget.Git"
    echo.
    exit /b 0
)

for %%I in ("%FOUND_GIT_PATH%") do set "GIT_BIN=%%~dpI"
for %%I in ("%GIT_BIN%\..") do set "GIT_ROOT=%%~fI"
if not exist "%GIT_ROOT%\unins000.exe" goto uninstall_git_winget

if "%ALL_MODE%"=="0" (
    call :ask_yes_no "Uninstall Git"
    if errorlevel 1 (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] Git
        set "CAN_REMOVE_REPO=0"
        echo.
        exit /b 0
    )
)

set "UNINSTALL_CMD="%GIT_ROOT%\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
call :run_command_spinner "Git" "" "%TEMP%\cp_setup_git_uninstall.log" "UNINSTALLING" "UNINSTALLED"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Git native uninstall failed.
    echo Log: %TEMP%\cp_setup_git_uninstall.log
    exit /b 1
)
call :clear_state "Winget.Git"
echo.
exit /b 0

:uninstall_git_winget
call :uninstall_winget_component "Git" "Git.Git" "git" "Winget.Git"
exit /b %ERRORLEVEL%

:uninstall_winget_now
call :require_winget
if errorlevel 1 exit /b 1
set "UNINSTALL_CMD="%WINGET%" uninstall --id %~2 --exact --source winget --disable-interactivity --silent"
call :run_command_spinner "%~1" "" "%TEMP%\cp_setup_winget_uninstall.log" "UNINSTALLING" "UNINSTALLED"
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] winget uninstall failed for %~1.
echo Log: %TEMP%\cp_setup_winget_uninstall.log
exit /b 1

:uninstall_msys2
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_ROOT=%%~dpI"
if exist "%MSYS2_ROOT%uninstall.exe" (
    set "UNINSTALL_CMD="%MSYS2_ROOT%uninstall.exe" purge --confirm-command"
    call :run_command_spinner "MSYS2" "" "%TEMP%\cp_setup_msys2_uninstall.log" "UNINSTALLING" "UNINSTALLED"
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 native uninstall failed.
        echo Log: %TEMP%\cp_setup_msys2_uninstall.log
        exit /b 1
    )
    call :verify_msys2_removed
    exit /b !ERRORLEVEL!
)
call :winget_has_package "MSYS2.MSYS2"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 has no native uninstaller and is not registered with winget.
    exit /b 1
)
call :uninstall_winget_now "MSYS2" "MSYS2.MSYS2"
if errorlevel 1 exit /b 1
call :verify_msys2_removed
exit /b %ERRORLEVEL%

:verify_msys2_removed
if exist "%MSYS2_ROOT%msys2_shell.cmd" (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 files remain at %MSYS2_ROOT%
    exit /b 1
)
call :require_winget
if errorlevel 1 exit /b 1
call :winget_has_package "MSYS2.MSYS2"
if not errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 remains registered with winget.
    exit /b 1
)
exit /b 0

:uninstall_pacman_toolchain
if "%ALL_MODE%"=="0" (
    call :ask_yes_no "Remove the CP toolchain from MSYS2"
    if errorlevel 1 (
        echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 CP toolchain
        set "CAN_REMOVE_REPO=0"
        echo.
        exit /b 0
    )
)

call :remove_pacman_toolchain_now
exit /b %ERRORLEVEL%

:remove_pacman_toolchain_if_present
call :state_has "Pacman.Toolchain"
if errorlevel 1 exit /b 0
call :has_pacman_toolchain
if errorlevel 1 (
    call :print_missing "MSYS2 CP toolchain"
    call :clear_state "Pacman.Toolchain"
    echo.
    exit /b 0
)
call :remove_pacman_toolchain_now
exit /b %ERRORLEVEL%

:remove_pacman_toolchain_now

call :find_msys2_shell
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was not found; the toolchain cannot be removed with pacman.
    exit /b 1
)
set "PACMAN_COMMAND=pacman -Qq mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff 2>/dev/null | xargs -r pacman -Rns --noconfirm"
call :run_pacman_spinner "UNINSTALLING" "UNINSTALLED"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain uninstall failed.
    echo Log: %TEMP%\cp_setup_pacman_uninstall.log
    exit /b 1
)
call :clear_state "Pacman.Toolchain"
echo.
exit /b 0

:state_has
reg query "%STATE_KEY%" /v "%~1" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_state
reg delete "%STATE_KEY%" /v "%~1" /f >nul 2>nul
exit /b 0

:print_missing
echo [%ESC%[33mMISSING%ESC%[0m] %~1
exit /b 0

:clear_empty_state
for %%V in (Path.Entries Winget.Git Winget.Neovim Winget.JDK Winget.MSYS2 Pacman.Toolchain) do (
    call :state_has "%%V"
    if not errorlevel 1 exit /b 0
)
reg delete "%STATE_KEY%" /f >nul 2>nul
exit /b 0

:remove_nvim_generated_data
powershell -NoProfile -ExecutionPolicy Bypass -Command "$esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $target=Join-Path $env:LOCALAPPDATA 'nvim-data'; if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop; Write-Host ($removed+' '+$target) }"
exit /b %ERRORLEVEL%

:ask_yes_no
setlocal EnableExtensions EnableDelayedExpansion
:ask_yes_no_again
set "ANSWER="
set /p "ANSWER=%~1? [Y/N]: "
for %%A in (y ye yes yeah) do if /I "!ANSWER!"=="%%A" (
    endlocal
    exit /b 0
)
for %%A in (n no nah) do if /I "!ANSWER!"=="%%A" (
    endlocal
    exit /b 1
)
echo [%ESC%[33mINVALID%ESC%[0m] Please answer yes or no.
goto ask_yes_no_again

:require_winget
set "WINGET="
for /F "usebackq delims=" %%P in (`where winget 2^>nul`) do if not defined WINGET set "WINGET=%%P"
if not defined WINGET if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" set "WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if defined WINGET exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] winget was not found.
exit /b 1

:winget_has_package
call :require_winget
if errorlevel 1 exit /b 1
set "WINGET_LIST=%TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.txt"
"%WINGET%" list --id %~1 --exact --source winget --disable-interactivity > "%WINGET_LIST%" 2>nul
findstr /I /C:"%~1" "%WINGET_LIST%" >nul
set "WINGET_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST%" >nul 2>nul
exit /b %WINGET_EXIT%

:find_msys2_shell
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

:has_pacman_toolchain
call :find_msys2_shell
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
set "PACMAN_CHECKER=%TEMP%\cp_setup_find_pacman_%RANDOM%_%RANDOM%.cmd"
> "%PACMAN_CHECKER%" echo @echo off
>> "%PACMAN_CHECKER%" echo "%MSYS2_BASH%" -lc "pacman -Qq mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff 2^> /dev/null ^| grep -q ."
>> "%PACMAN_CHECKER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%PACMAN_CHECKER%"""
call :search_command "MSYS2 CP toolchain" "@env" "PACMAN_TOOLCHAIN"
set "PACMAN_CHECK_EXIT=!ERRORLEVEL!"
del "%PACMAN_CHECKER%" >nul 2>nul
exit /b !PACMAN_CHECK_EXIT!

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
>> "%SEARCH_PS%" echo if ($exitCode -eq 0) { Write-Host ($cr + $clear + $found + ' ' + $label) } else { Write-Host -NoNewline ($cr + $clear) }
>> "%SEARCH_PS%" echo exit $exitCode
powershell -NoProfile -ExecutionPolicy Bypass -File "%SEARCH_PS%"
set "SEARCH_EXIT=%ERRORLEVEL%"
set "SEARCH_VALUE="
for /F "usebackq delims=" %%P in ("%SEARCH_RESULT_FILE%") do if not defined SEARCH_VALUE set "SEARCH_VALUE=%%P"
del "%SEARCH_PS%" >nul 2>nul
del "%SEARCH_RESULT_FILE%" >nul 2>nul
endlocal & set "%~3=%SEARCH_VALUE%" & exit /b %SEARCH_EXIT%

:run_command_spinner
set "SPIN_LABEL=%~1"
set "SPIN_HINT=%~2"
set "SPIN_LOG=%~3"
set "SPIN_ACTION=%~4"
set "SPIN_SUCCESS=%~5"
set "SPIN_PS=%TEMP%\cp_setup_command_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo $label = $env:SPIN_LABEL
>> "%SPIN_PS%" echo $hint = $env:SPIN_HINT
>> "%SPIN_PS%" echo $log = $env:SPIN_LOG
>> "%SPIN_PS%" echo $cmd = [string]$env:UNINSTALL_CMD
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:TEMP ('cp_setup_command_' + [guid]::NewGuid().ToString('N') + '.cmd')
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

:run_pacman_spinner
set "PACMAN_ACTION=%~1"
set "PACMAN_SUCCESS=%~2"
set "SPIN_PS=%TEMP%\cp_setup_pacman_uninstall_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo $label = 'MSYS2 CP toolchain via pacman'
>> "%SPIN_PS%" echo $hint = 'this may take a while'
>> "%SPIN_PS%" echo $log = Join-Path $env:TEMP 'cp_setup_pacman_uninstall.log'
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:TEMP ('cp_setup_pacman_uninstall_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:PACMAN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:PACMAN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $bash = Join-Path (Split-Path -Parent $env:MSYS2_SHELL) 'usr\bin\bash.exe'
>> "%SPIN_PS%" echo if (-not (Test-Path -LiteralPath $bash)) { 'Could not find MSYS2 bash.exe.' ^| Set-Content -LiteralPath $log; Write-Host ($action + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $q + $bash + $q + ' -lc ' + $q + $env:PACMAN_COMMAND + $q + ' 1^>' + $q + $log + $q + ' 2^>^&1')
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

:schedule_repo_removal
set "CP_DELETE_ROOT=%ROOT%"
set "DELETE_CMD=%TEMP%\cp_setup_delete_%RANDOM%_%RANDOM%.cmd"
if defined CP_DELETE_SIGNAL (
    > "%CP_DELETE_SIGNAL%" echo ready
    cd /d "%TEMP%"
    exit /b 0
)
cd /d "%TEMP%"
> "%DELETE_CMD%" echo @echo off
>> "%DELETE_CMD%" echo cd /d "%%TEMP%%"
>> "%DELETE_CMD%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 2; $root=[IO.Path]::GetFullPath($env:CP_DELETE_ROOT); $marker=Join-Path $root 'scripts\install.bat'; if ($root -eq [IO.Path]::GetPathRoot($root) -or -not (Test-Path -LiteralPath $marker)) { exit 1 }; $parent=Split-Path -Parent $root; $name=Split-Path -Leaf $root; $staged=$null; for ($i=0; $i -lt 20; $i++) { $candidate=Join-Path $parent ('.'+$name+'.deleting-'+[guid]::NewGuid().ToString('N')); try { Move-Item -LiteralPath $root -Destination $candidate -ErrorAction Stop; $staged=$candidate; break } catch { Start-Sleep -Milliseconds 500 } }; if (-not $staged) { Write-Host '[FAILED] CP setup folder is still in use. Close terminals opened in it, then delete it manually.'; exit 1 }; for ($i=0; $i -lt 20; $i++) { try { Remove-Item -LiteralPath $staged -Recurse -Force -ErrorAction Stop; exit 0 } catch { Start-Sleep -Milliseconds 500 } }; Write-Host ('[FAILED] CP setup cleanup folder remains at '+$staged); exit 1"
>> "%DELETE_CMD%" echo set "CP_DELETE_SELF=%%~f0"
>> "%DELETE_CMD%" echo start "" /b powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Milliseconds 500; Remove-Item -LiteralPath $env:CP_DELETE_SELF -Force -ErrorAction SilentlyContinue"
start "" /b "%ComSpec%" /d /c call "%DELETE_CMD%"
exit /b %ERRORLEVEL%

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
exit /b 1
