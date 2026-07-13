@echo off
setlocal EnableExtensions DisableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "ORIGINAL_ARGS=%*"

set "CHECK_ONLY=0"
set "ALL_MODE=0"
set "CAN_REMOVE_REPO=1"
set "CONFIG_REMOVED=0"
set "REMOVE_REPO=0"
set "STATE_KEY=HKCU\Software\my-cp-setup"
set "STATE_SCHEMA=4"
set "MASON_TOOLS=pyright jdtls google-java-format clangd"
set "PACMAN_PACKAGES_ALLOWED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff"

call :validate_setup_root
if errorlevel 1 exit /b 1
setlocal EnableDelayedExpansion

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
call :check_state_root
if errorlevel 1 exit /b 1
call :enable_ansi "%CHECK_ONLY%"
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

call :has_setup_configuration
set "CONFIG_STATUS=!ERRORLEVEL!"
set "CONFIG_FOUND=1"
set "CONFIG_STATUS_ABOVE=0"
if "!CONFIG_STATUS!"=="2" goto configuration_failed
if "!CONFIG_STATUS!"=="1" set "CONFIG_FOUND=0"

if "%ALL_MODE%"=="1" goto configuration_ready
if "%CONFIG_FOUND%"=="0" goto configuration_ready
echo.
call :ask_yes_no "Remove CP setup configuration"
if errorlevel 1 goto configuration_kept
set "CONFIG_STATUS_ABOVE=1"
call :replace_configuration_status_above "REMOVING" "38;5;153"
goto configuration_remove

:configuration_kept
call :replace_configuration_status_above "KEPT" "38;5;244"
set "CAN_REMOVE_REPO=0"
goto decide_repo_removal

:configuration_ready
if "%CONFIG_FOUND%"=="1" call :replace_configuration_status "REMOVING" "38;5;153"

:configuration_remove
call :remove_setup_configuration
if errorlevel 1 goto configuration_failed

if "%CONFIG_FOUND%"=="0" goto configuration_missing
if "%CONFIG_STATUS_ABOVE%"=="1" goto configuration_removed_above
call :replace_configuration_status "REMOVED" "38;5;114"
goto configuration_finished

:configuration_removed_above
call :replace_configuration_status_above "REMOVED" "38;5;114"
goto configuration_finished

:configuration_missing
call :replace_configuration_status "MISSING" "33"

:configuration_finished
call :clear_empty_state
set "CONFIG_REMOVED=1"
if "%CONFIG_STATUS_ABOVE%"=="1" goto decide_repo_removal
echo.

:decide_repo_removal
if not "%CAN_REMOVE_REPO%"=="1" goto repo_kept

echo.
call :ask_yes_no "Remove this CP setup folder too"
if errorlevel 1 goto repo_kept_by_choice
echo [%ESC%[38;5;153mREMOVING%ESC%[0m] CP setup folder after the uninstaller closes.
reg delete "%STATE_KEY%" /f >nul 2>nul
set "REMOVE_REPO=1"
goto finish_uninstall

:repo_kept_by_choice
echo [%ESC%[38;5;244mKEPT%ESC%[0m] CP setup folder.
goto finish_uninstall

:repo_kept
echo.
echo [%ESC%[38;5;244mKEPT%ESC%[0m] CP setup folder because setup components or configuration were kept.
goto finish_uninstall

:finish_uninstall
echo.
call :print_completion
echo Restart terminals so environment changes are visible everywhere.
call :wait_to_finish
if "%REMOVE_REPO%"=="0" exit /b 0
call :schedule_repo_removal
if errorlevel 1 goto failed
exit /b 0

:configuration_failed
goto failed

:validate_setup_root
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:ROOT; if ($root -notmatch '^[A-Za-z]:\\') { exit 1 }; foreach ($code in @(33,37,38,59,60,62,94,124)) { if ($root.IndexOf([char]$code) -ge 0) { exit 1 } }; foreach ($name in @('TEMP','LOCALAPPDATA','APPDATA')) { $value=[Environment]::GetEnvironmentVariable($name); if ($value -and $value.IndexOf([char]33) -ge 0) { exit 2 } }; exit 0"
if not errorlevel 1 exit /b 0
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] TEMP, LOCALAPPDATA, and APPDATA paths cannot contain exclamation marks.
    echo Move the affected profile or temporary directory before running this uninstaller.
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] The setup path cannot contain CMD metacharacters.
echo Use a local drive path without exclamation marks, percent signs, ampersands, semicolons, pipes, angle brackets, or carets.
exit /b 1

:check_state_root
powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\'); $stored=$null; if (Test-Path -LiteralPath $key) { $stored=(Get-ItemProperty -Path $key -Name 'Install.Root' -ErrorAction SilentlyContinue).'Install.Root' }; if (-not $stored) { $stored=[Environment]::GetEnvironmentVariable('CP_SETUP_ROOT','User') }; if ($stored -and $stored.TrimEnd('\') -ine $root) { Write-Host ('[FAILED] This setup is managed from: '+$stored); Write-Host 'Run uninstall.bat from that folder.'; exit 1 }; exit 0"
exit /b %ERRORLEVEL%

:has_setup_configuration
set "CONFIG_ROOT=%ROOT%"
set "MACROS=%ROOT%\scripts\cp_macros"
reg query "%STATE_KEY%" /v "Config.Managed" >nul 2>nul
if errorlevel 1 (
    set "CONFIG_MANAGED=0"
) else (
    set "CONFIG_MANAGED=1"
)
set "CONFIG_CHECK_PS=%TEMP%\cp_setup_config_check_%RANDOM%_%RANDOM%.ps1"
> "%CONFIG_CHECK_PS%" echo $ErrorActionPreference = 'Stop'
>> "%CONFIG_CHECK_PS%" echo try {
>> "%CONFIG_CHECK_PS%" echo     $root = $env:CONFIG_ROOT
>> "%CONFIG_CHECK_PS%" echo     $macros = $env:MACROS
>> "%CONFIG_CHECK_PS%" echo     $command = 'doskey /macrofile="' + $macros + '"'
>> "%CONFIG_CHECK_PS%" echo     $key = 'HKCU:\Software\my-cp-setup'
>> "%CONFIG_CHECK_PS%" echo     $stateManaged = $env:CONFIG_MANAGED -eq '1'
>> "%CONFIG_CHECK_PS%" echo     $ownedValue = ^(Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue^).'Path.Entries'
>> "%CONFIG_CHECK_PS%" echo     $owned = @^(^)
>> "%CONFIG_CHECK_PS%" echo     foreach ^($entry in $ownedValue^) { if ^($entry^) { $owned += $entry.TrimEnd^('\'^) } }
>> "%CONFIG_CHECK_PS%" echo     $path = [Environment]::GetEnvironmentVariable^('Path','User'^)
>> "%CONFIG_CHECK_PS%" echo     if ^($null -eq $path^) { $path = '' }
>> "%CONFIG_CHECK_PS%" echo     $parts = @^(^)
>> "%CONFIG_CHECK_PS%" echo     foreach ^($entry in ^($path -split ';'^)^) { $candidate = $entry.Trim^(^).TrimEnd^('\'^); if ^($candidate^) { $parts += $candidate } }
>> "%CONFIG_CHECK_PS%" echo     $hasPath = $false
>> "%CONFIG_CHECK_PS%" echo     foreach ^($entry in $parts^) { if ^($owned -icontains $entry^) { $hasPath = $true; break } }
>> "%CONFIG_CHECK_PS%" echo     $hasRootEnvironment = $false
>> "%CONFIG_CHECK_PS%" echo     foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT'^)^) { $value = [Environment]::GetEnvironmentVariable^($name,'User'^); if ^($value -and $value.TrimEnd^('\'^) -ieq $root.TrimEnd^('\'^)^) { $hasRootEnvironment = $true; break } }
>> "%CONFIG_CHECK_PS%" echo     $hasWrittenEnvironment = $false
>> "%CONFIG_CHECK_PS%" echo     foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) { $written = ^(Get-ItemProperty -Path $key -Name ^('Env.' + $name + '.Written'^) -ErrorAction SilentlyContinue^).^('Env.' + $name + '.Written'^); $value = [Environment]::GetEnvironmentVariable^($name,'User'^); if ^($written -and $value -eq $written^) { $hasWrittenEnvironment = $true; break } }
>> "%CONFIG_CHECK_PS%" echo     $autorun = ^(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue^).AutoRun
>> "%CONFIG_CHECK_PS%" echo     $hasMacros = $autorun -and $autorun.IndexOf^($command,[StringComparison]::OrdinalIgnoreCase^) -ge 0
>> "%CONFIG_CHECK_PS%" echo     if ^($hasPath -or $hasRootEnvironment -or $hasWrittenEnvironment -or $hasMacros -or $stateManaged^) { exit 0 }
>> "%CONFIG_CHECK_PS%" echo     exit 1
>> "%CONFIG_CHECK_PS%" echo } catch { exit 2 }
set "CONFIG_CHECKER=%TEMP%\cp_setup_config_check_%RANDOM%_%RANDOM%.cmd"
> "%CONFIG_CHECKER%" echo @echo off
>> "%CONFIG_CHECKER%" echo powershell -NoProfile -ExecutionPolicy Bypass -File "%CONFIG_CHECK_PS%"
>> "%CONFIG_CHECKER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%CONFIG_CHECKER%"""
call :search_command "CP setup configuration" "@env" "CONFIG_CHECK_VALUE" "CHECKING" "CHECKING" "38;5;183" "1"
set "CONFIG_CHECK_EXIT=!ERRORLEVEL!"
del "%CONFIG_CHECKER%" >nul 2>nul
del "%CONFIG_CHECK_PS%" >nul 2>nul
exit /b !CONFIG_CHECK_EXIT!

:replace_configuration_status
<nul set /p "=%ESC%[2K%ESC%[1G[%ESC%[%~2m%~1%ESC%[0m] CP setup configuration"
exit /b 0

:replace_configuration_status_above
<nul set /p "=%ESC%[2A%ESC%[2K%ESC%[1G[%ESC%[%~2m%~1%ESC%[0m] CP setup configuration%ESC%[2B%ESC%[1G"
exit /b 0

:print_completion
if "%ALL_MODE%"=="1" if "%CAN_REMOVE_REPO%"=="1" (
    echo [%ESC%[32mDONE%ESC%[0m] All setup-managed components and configuration were removed.
    exit /b 0
)
set "COMPLETION_MESSAGE=Uninstall finished."
if "%CONFIG_FOUND%"=="1" if "%CONFIG_REMOVED%"=="1" set "COMPLETION_MESSAGE=CP setup configuration removed."
echo [%ESC%[32mDONE%ESC%[0m] %COMPLETION_MESSAGE%
if "%CAN_REMOVE_REPO%"=="0" echo Components or configuration you kept remain installed.
exit /b 0

:wait_to_finish
echo.
echo Press any key to finish...
pause >nul
exit /b 0

:enable_ansi
if not "%~1"=="1" reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
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
>> "%ELEVATE_CMD%" echo set "CP_DELETE_SIGNAL=%ELEVATE_DELETE_SIGNAL%"
>> "%ELEVATE_CMD%" echo call "%CP_UNINSTALL_SCRIPT%" %CP_UNINSTALL_ARGS%
>> "%ELEVATE_CMD%" echo set "CP_SETUP_EXIT=%%ERRORLEVEL%%"
>> "%ELEVATE_CMD%" echo ^> "%ELEVATE_EXIT_FILE%" echo %%CP_SETUP_EXIT%%
>> "%ELEVATE_CMD%" echo if exist "%ELEVATE_DELETE_SIGNAL%" cd /d "%%TEMP%%"
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
call :has_setup_configuration
set "CHECK_CONFIG_STATUS=!ERRORLEVEL!"
if "!CHECK_CONFIG_STATUS!"=="2" (
    echo.
    exit /b 1
)
if "!CHECK_CONFIG_STATUS!"=="1" (
    call :replace_configuration_status "MISSING" "33"
) else (
    call :replace_configuration_status "FOUND" "38;5;114"
)
echo.
for %%V in (Winget.Git Winget.Neovim Winget.Node Winget.JDK Winget.MSYS2 Pacman.Toolchain) do (
    call :state_has "%%V"
    if not errorlevel 1 echo [%ESC%[38;5;114mFOUND%ESC%[0m] %%V installed by this setup
)
exit /b 0

:remove_setup_configuration
call :remove_managed_mason_packages
if errorlevel 1 exit /b 1
call :remove_nvim_generated_data
if errorlevel 1 exit /b 1
set "CONFIG_ROOT=%ROOT%"
set "MACROS=%ROOT%\scripts\cp_macros"
set "CONFIG_CLEANUP_PS=%TEMP%\cp_setup_config_cleanup_%RANDOM%_%RANDOM%.ps1"
> "%CONFIG_CLEANUP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%CONFIG_CLEANUP_PS%" echo $key = 'HKCU:\Software\my-cp-setup'
>> "%CONFIG_CLEANUP_PS%" echo $root = $env:CONFIG_ROOT
>> "%CONFIG_CLEANUP_PS%" echo $macros = $env:MACROS
>> "%CONFIG_CLEANUP_PS%" echo $ownedValue = ^(Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue^).'Path.Entries'
>> "%CONFIG_CLEANUP_PS%" echo $owned = @^(^)
>> "%CONFIG_CLEANUP_PS%" echo foreach ^($entry in $ownedValue^) { if ^($entry^) { $owned += $entry.Trim^(^).TrimEnd^('\'^) } }
>> "%CONFIG_CLEANUP_PS%" echo $path = [Environment]::GetEnvironmentVariable^('Path','User'^)
>> "%CONFIG_CLEANUP_PS%" echo if ^($null -eq $path^) { $path = '' }
>> "%CONFIG_CLEANUP_PS%" echo $pathWritten = ^(Get-ItemProperty -Path $key -Name 'Path.Written' -ErrorAction SilentlyContinue^).'Path.Written'
>> "%CONFIG_CLEANUP_PS%" echo $pathBeforeProperty = Get-ItemProperty -Path $key -Name 'Path.Before' -ErrorAction SilentlyContinue
>> "%CONFIG_CLEANUP_PS%" echo if ^($null -ne $pathWritten -and $path -eq $pathWritten -and $null -ne $pathBeforeProperty^) { [Environment]::SetEnvironmentVariable^('Path',$pathBeforeProperty.'Path.Before','User'^) } elseif ^($owned.Count^) { $kept = @^($path -split ';' ^| Where-Object { $_ -and $owned -inotcontains $_.Trim^(^).TrimEnd^('\'^) }^); [Environment]::SetEnvironmentVariable^('Path',^($kept -join ';'^),'User'^) }
>> "%CONFIG_CLEANUP_PS%" echo foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) {
>> "%CONFIG_CLEANUP_PS%" echo     $writtenName = 'Env.' + $name + '.Written'
>> "%CONFIG_CLEANUP_PS%" echo     $beforeName = 'Env.' + $name + '.Before'
>> "%CONFIG_CLEANUP_PS%" echo     $hadName = 'Env.' + $name + '.HadValue'
>> "%CONFIG_CLEANUP_PS%" echo     $written = ^(Get-ItemProperty -Path $key -Name $writtenName -ErrorAction SilentlyContinue^).$writtenName
>> "%CONFIG_CLEANUP_PS%" echo     $current = [Environment]::GetEnvironmentVariable^($name,'User'^)
>> "%CONFIG_CLEANUP_PS%" echo     if ^($null -eq $written^) { if ^($name -eq 'XDG_CONFIG_HOME' -or $name -eq 'CP_SETUP_ROOT'^) { $written = $root } elseif ^($name -eq 'CP_PYTHON' -or $name -eq 'CP_GPP'^) { $managed = ^(Get-ItemProperty -Path $key -Name 'Config.Managed' -ErrorAction SilentlyContinue^).'Config.Managed'; if ^($null -ne $managed^) { $written = $current } } }
>> "%CONFIG_CLEANUP_PS%" echo     if ^($null -ne $written -and $current -eq $written^) { $had = ^(Get-ItemProperty -Path $key -Name $hadName -ErrorAction SilentlyContinue^).$hadName; if ^($had -eq 1^) { $before = ^(Get-ItemProperty -Path $key -Name $beforeName -ErrorAction SilentlyContinue^).$beforeName; [Environment]::SetEnvironmentVariable^($name,$before,'User'^) } else { [Environment]::SetEnvironmentVariable^($name,$null,'User'^) } }
>> "%CONFIG_CLEANUP_PS%" echo }
>> "%CONFIG_CLEANUP_PS%" echo $command = 'doskey /macrofile="' + $macros + '"'
>> "%CONFIG_CLEANUP_PS%" echo $autoKey = 'HKCU:\Software\Microsoft\Command Processor'
>> "%CONFIG_CLEANUP_PS%" echo $autorun = ^(Get-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue^).AutoRun
>> "%CONFIG_CLEANUP_PS%" echo $autoWritten = ^(Get-ItemProperty -Path $key -Name 'AutoRun.Written' -ErrorAction SilentlyContinue^).'AutoRun.Written'
>> "%CONFIG_CLEANUP_PS%" echo $autoHad = ^(Get-ItemProperty -Path $key -Name 'AutoRun.HadValue' -ErrorAction SilentlyContinue^).'AutoRun.HadValue'
>> "%CONFIG_CLEANUP_PS%" echo if ^($autoWritten -and $autorun -eq $autoWritten^) { if ^($autoHad -eq 1^) { $autoBefore = ^(Get-ItemProperty -Path $key -Name 'AutoRun.Before' -ErrorAction SilentlyContinue^).'AutoRun.Before'; Set-ItemProperty -Path $autoKey -Name AutoRun -Value $autoBefore } else { Remove-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue } } elseif ^($autorun^) {
>> "%CONFIG_CLEANUP_PS%" echo     $index = $autorun.IndexOf^($command,[StringComparison]::OrdinalIgnoreCase^)
>> "%CONFIG_CLEANUP_PS%" echo     if ^($index -ge 0^) {
>> "%CONFIG_CLEANUP_PS%" echo         $before = $autorun.Substring^(0,$index^); $after = $autorun.Substring^($index + $command.Length^)
>> "%CONFIG_CLEANUP_PS%" echo         if ^($before.EndsWith^(' ^& ',[StringComparison]::Ordinal^)^) { $before = $before.Substring^(0,$before.Length - 3^) } elseif ^($after.StartsWith^(' ^& ',[StringComparison]::Ordinal^)^) { $after = $after.Substring^(3^) }
>> "%CONFIG_CLEANUP_PS%" echo         $kept = ^($before + $after^).Trim^(^)
>> "%CONFIG_CLEANUP_PS%" echo         if ^($kept^) { Set-ItemProperty -Path $autoKey -Name AutoRun -Value $kept } else { Remove-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue }
>> "%CONFIG_CLEANUP_PS%" echo     }
>> "%CONFIG_CLEANUP_PS%" echo }
>> "%CONFIG_CLEANUP_PS%" echo if ^($autoWritten -and $autorun -and $autorun.StartsWith^($autoWritten + ' ^& ',[StringComparison]::OrdinalIgnoreCase^)^) { $suffix = $autorun.Substring^($autoWritten.Length + 3^); if ^($autoHad -eq 1^) { $autoBefore = ^(Get-ItemProperty -Path $key -Name 'AutoRun.Before' -ErrorAction SilentlyContinue^).'AutoRun.Before'; Set-ItemProperty -Path $autoKey -Name AutoRun -Value ^($autoBefore + ' ^& ' + $suffix^) } else { Set-ItemProperty -Path $autoKey -Name AutoRun -Value $suffix } }
>> "%CONFIG_CLEANUP_PS%" echo $consoleKey = 'HKCU:\Console'; $console = Get-ItemProperty -Path $consoleKey -Name VirtualTerminalLevel -ErrorAction SilentlyContinue; $consoleHad = ^(Get-ItemProperty -Path $key -Name 'Console.VirtualTerminal.HadValue' -ErrorAction SilentlyContinue^).'Console.VirtualTerminal.HadValue'; if ^($null -ne $console -and $console.VirtualTerminalLevel -eq 1^) { if ^($consoleHad -eq 1^) { $consoleBefore = ^(Get-ItemProperty -Path $key -Name 'Console.VirtualTerminal.Before' -ErrorAction SilentlyContinue^).'Console.VirtualTerminal.Before'; Set-ItemProperty -Path $consoleKey -Name VirtualTerminalLevel -Value $consoleBefore } else { Remove-ItemProperty -Path $consoleKey -Name VirtualTerminalLevel -ErrorAction SilentlyContinue } }
>> "%CONFIG_CLEANUP_PS%" echo foreach ^($property in @^('Path.Entries','Path.Before','Path.Written','AutoRun.HadValue','AutoRun.Before','AutoRun.Written','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Config.Managed','Config.MutationStarted','Snapshot.Complete'^)^) { Remove-ItemProperty -Path $key -Name $property -ErrorAction SilentlyContinue }
>> "%CONFIG_CLEANUP_PS%" echo foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) { foreach ^($suffix in @^('HadValue','Before','Written'^)^) { Remove-ItemProperty -Path $key -Name ^('Env.' + $name + '.' + $suffix^) -ErrorAction SilentlyContinue } }
>> "%CONFIG_CLEANUP_PS%" echo exit 0
set "CONFIG_CLEANUP_LOG=%TEMP%\cp_setup_config_cleanup.log"
del "%CONFIG_CLEANUP_LOG%" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%CONFIG_CLEANUP_PS%" > "%CONFIG_CLEANUP_LOG%" 2>&1
set "CONFIG_CLEANUP_EXIT=!ERRORLEVEL!"
del "%CONFIG_CLEANUP_PS%" >nul 2>nul
if not "!CONFIG_CLEANUP_EXIT!"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup configuration cleanup failed.
    echo Log: !CONFIG_CLEANUP_LOG!
    exit /b 1
)
del "%CONFIG_CLEANUP_LOG%" >nul 2>nul
exit /b 0

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

call :state_has "Winget.Node"
if not errorlevel 1 (
    call :uninstall_winget_component "Node.js LTS" "OpenJS.NodeJS.LTS" "node" "Winget.Node"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Node.js LTS" "node"
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
call :winget_has_package "MSYS2.MSYS2"
if errorlevel 2 exit /b 1
if errorlevel 1 (
    call :print_missing "MSYS2"
    call :clear_state "Winget.MSYS2"
    echo.
    goto maybe_pacman
)

call :ask_yes_no "Uninstall MSYS2 and its CP toolchain"
if errorlevel 1 (
    set "CAN_REMOVE_REPO=0"
    echo.
    goto maybe_pacman
)

call :uninstall_msys2
if errorlevel 1 exit /b 1
call :clear_state "Winget.MSYS2"
call :clear_pacman_state
echo.
exit /b 0

:maybe_pacman
call :state_has "Pacman.Toolchain"
if errorlevel 1 exit /b 0
call :has_pacman_toolchain
if errorlevel 2 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 packages because exact setup ownership is unavailable.
    set "CAN_REMOVE_REPO=0"
    echo.
    exit /b 0
)
if errorlevel 1 (
    call :print_missing "MSYS2 CP toolchain"
    call :clear_pacman_state
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

call :state_has "Winget.Node"
if not errorlevel 1 (
    call :uninstall_winget_component "Node.js LTS" "OpenJS.NodeJS.LTS" "node" "Winget.Node"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Node.js LTS" "node"
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
    call :winget_has_package "MSYS2.MSYS2"
    if errorlevel 2 exit /b 1
    if errorlevel 1 (
        call :print_missing "MSYS2"
        call :clear_state "Winget.MSYS2"
        echo.
    ) else (
        call :uninstall_msys2
        if errorlevel 1 exit /b 1
        call :clear_state "Winget.MSYS2"
        call :clear_pacman_state
        echo.
        exit /b 0
    )
)

call :report_unmanaged_msys2

call :state_has "Pacman.Toolchain"
if not errorlevel 1 (
    call :find_msys2_shell
    if errorlevel 1 (
        call :print_missing "MSYS2 CP toolchain"
        call :clear_pacman_state
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
call :require_winget
if errorlevel 1 exit /b 1
call :winget_has_package "%~2"
if errorlevel 2 exit /b 1
if errorlevel 1 (
    call :print_missing "%~1"
    call :clear_state "%~4"
    if /I "%~4"=="Winget.Neovim" call :remove_managed_mason_packages
    if /I "%~4"=="Winget.Neovim" call :remove_nvim_generated_data
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

if /I "%~4"=="Winget.Neovim" (
    call :remove_managed_mason_packages
    if errorlevel 1 exit /b 1
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
call :winget_has_package "MSYS2.MSYS2"
if errorlevel 2 exit /b 1
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 is not registered with winget.
    exit /b 1
)
set "MANAGED_MSYS2_SHELL="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-ItemProperty -Path 'HKCU:\Software\my-cp-setup' -Name 'Winget.MSYS2.Path' -ErrorAction SilentlyContinue).'Winget.MSYS2.Path'"`) do if not defined MANAGED_MSYS2_SHELL set "MANAGED_MSYS2_SHELL=%%P"
call :uninstall_winget_now "MSYS2" "MSYS2.MSYS2"
if errorlevel 1 exit /b 1
call :verify_msys2_removed
exit /b %ERRORLEVEL%

:verify_msys2_removed
if defined MANAGED_MSYS2_SHELL if exist "%MANAGED_MSYS2_SHELL%" (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 files remain at %MANAGED_MSYS2_SHELL%
    exit /b 1
)
call :require_winget
if errorlevel 1 exit /b 1
call :winget_has_package "MSYS2.MSYS2"
if errorlevel 2 exit /b 1
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

:remove_pacman_toolchain_now
call :load_managed_pacman_packages
if errorlevel 1 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 packages because exact setup ownership is unavailable.
    set "CAN_REMOVE_REPO=0"
    exit /b 0
)
call :find_msys2_shell
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was not found; the toolchain cannot be removed with pacman.
    exit /b 1
)
set "PACMAN_COMMAND=pacman -Qq -- %PACMAN_PACKAGES% 2>/dev/null | xargs -r pacman -Rns --noconfirm --"
call :run_pacman_spinner "UNINSTALLING" "UNINSTALLED"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain uninstall failed.
    echo Log: %TEMP%\cp_setup_pacman_uninstall.log
    exit /b 1
)
call :clear_pacman_state
echo.
exit /b 0

:load_managed_pacman_packages
set "PACMAN_PACKAGES="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$allowed=@($env:PACMAN_PACKAGES_ALLOWED -split ' ' | Where-Object { $_ }); $p=@((Get-ItemProperty -Path 'HKCU:\Software\my-cp-setup' -Name 'Pacman.Packages' -ErrorAction SilentlyContinue).'Pacman.Packages' | Where-Object { $_ }); foreach ($name in $p) { if ($allowed -inotcontains $name) { exit 1 } }; if ($p.Count) { $p -join ' ' }"`) do if not defined PACMAN_PACKAGES set "PACMAN_PACKAGES=%%P"
if defined PACMAN_PACKAGES exit /b 0
exit /b 1

:state_has
reg query "%STATE_KEY%" /v "%~1" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_state
reg delete "%STATE_KEY%" /v "%~1" /f >nul 2>nul
reg delete "%STATE_KEY%" /v "%~1.Path" /f >nul 2>nul
exit /b 0

:clear_pacman_state
reg delete "%STATE_KEY%" /v "Pacman.Toolchain" /f >nul 2>nul
reg delete "%STATE_KEY%" /v "Pacman.Packages" /f >nul 2>nul
reg delete "%STATE_KEY%" /v "Pacman.Shell.Path" /f >nul 2>nul
exit /b 0

:print_missing
echo [%ESC%[33mMISSING%ESC%[0m] %~1
exit /b 0

:clear_empty_state
for %%V in (Path.Entries Config.Managed Winget.Git Winget.Neovim Winget.Node Winget.JDK Winget.MSYS2 Pacman.Toolchain Pacman.Packages) do (
    call :state_has "%%V"
    if not errorlevel 1 exit /b 0
)
reg delete "%STATE_KEY%" /f >nul 2>nul
exit /b 0

:remove_nvim_generated_data
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $existed=(Get-ItemProperty -Path $key -Name 'NvimData.Existed' -ErrorAction SilentlyContinue).'NvimData.Existed'; $target=[IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'nvim-data')); $expected=[IO.Path]::GetFullPath($env:LOCALAPPDATA).TrimEnd('\')+'\nvim-data'; if ($existed -eq 0 -and $target -ieq $expected -and (Test-Path -LiteralPath $target)) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop; $esc=[char]27; Write-Host ('['+$esc+'[38;5;114mREMOVED'+$esc+'[0m] '+$target) }; $jdtlsExisted=(Get-ItemProperty -Path $key -Name 'JdtlsWorkspace.Existed' -ErrorAction SilentlyContinue).'JdtlsWorkspace.Existed'; $jdtls=(Get-ItemProperty -Path $key -Name 'JdtlsWorkspace.Path' -ErrorAction SilentlyContinue).'JdtlsWorkspace.Path'; if ($jdtlsExisted -eq 0 -and $jdtls) { $workspaceRoot=[IO.Path]::GetFullPath((Join-Path $target 'jdtls-workspaces')); $prefix=$workspaceRoot.TrimEnd('\')+'\'; $full=[IO.Path]::GetFullPath($jdtls); if (-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $full) -notmatch '^cp-[0-9a-f]{16}$') { throw ('Unsafe JDT LS workspace path: '+$full) }; if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop } }; foreach ($name in @('NvimData.Existed','Nvim.BootstrapStarted','Mason.Packages.Before','Mason.Packages','JdtlsWorkspace.Existed','JdtlsWorkspace.Path')) { Remove-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue }; exit 0"
exit /b %ERRORLEVEL%

:remove_managed_mason_packages
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $allowed=@($env:MASON_TOOLS -split ' ' | Where-Object { $_ }); $owned=@((Get-ItemProperty -Path $key -Name 'Mason.Packages' -ErrorAction SilentlyContinue).'Mason.Packages' | Where-Object { $_ }); $existed=(Get-ItemProperty -Path $key -Name 'NvimData.Existed' -ErrorAction SilentlyContinue).'NvimData.Existed'; if (-not $owned.Count -or $existed -eq 0) { exit 0 }; $mason=[IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'nvim-data\mason')); $packagesRoot=[IO.Path]::GetFullPath((Join-Path $mason 'packages')); $packagesPrefix=$packagesRoot.TrimEnd('\')+'\'; foreach ($name in $owned) { if ($allowed -inotcontains $name -or $name -in @('.','..') -or $name -notmatch '^[A-Za-z0-9._-]+$') { throw ('Unsafe Mason package name: '+$name) }; $package=[IO.Path]::GetFullPath((Join-Path $packagesRoot $name)); if (-not $package.StartsWith($packagesPrefix,[StringComparison]::OrdinalIgnoreCase)) { throw ('Unsafe Mason package path: '+$package) }; $receipt=Join-Path $package 'mason-receipt.json'; if (Test-Path -LiteralPath $receipt) { $data=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json; foreach ($group in @('bin','share','opt')) { $links=$data.links.$group; if ($links) { foreach ($property in $links.PSObject.Properties) { $base=Join-Path $mason $group; $target=[IO.Path]::GetFullPath((Join-Path $base $property.Name)); if ($target.StartsWith(([IO.Path]::GetFullPath($base).TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue } } } } }; if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force -ErrorAction Stop } }; Remove-ItemProperty -Path $key -Name 'Mason.Packages' -ErrorAction SilentlyContinue; $esc=[char]27; Write-Host ('['+$esc+'[38;5;114mREMOVED'+$esc+'[0m] setup-managed Mason packages')"
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
if errorlevel 1 exit /b 2
set "WINGET_LIST=%TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.txt"
"%WINGET%" list --id %~1 --exact --source winget --disable-interactivity > "%WINGET_LIST%" 2>nul
set "WINGET_QUERY_EXIT=%ERRORLEVEL%"
if "%WINGET_QUERY_EXIT%"=="-1978335212" (
    del "%WINGET_LIST%" >nul 2>nul
    exit /b 1
)
if not "%WINGET_QUERY_EXIT%"=="0" (
    del "%WINGET_LIST%" >nul 2>nul
    echo [%ESC%[31mFAILED%ESC%[0m] winget could not query installed package %~1.
    exit /b 2
)
findstr /I /C:"%~1" "%WINGET_LIST%" >nul
set "WINGET_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST%" >nul 2>nul
exit /b %WINGET_EXIT%

:find_msys2_shell
if defined MSYS2_SHELL exit /b 0
set "MSYS2_FINDER=%TEMP%\cp_setup_find_msys2_%RANDOM%_%RANDOM%.cmd"
> "%MSYS2_FINDER%" echo @echo off
>> "%MSYS2_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@(); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $c += $value } }; foreach ($exe in @($env:CP_GPP,$env:CP_PYTHON,[Environment]::GetEnvironmentVariable('CP_GPP','User'),[Environment]::GetEnvironmentVariable('CP_PYTHON','User'))) { if ($exe) { $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $exe)); $c += Join-Path $root 'msys2_shell.cmd' } }; $c += 'C:\msys64\msys2_shell.cmd'; $w=where.exe msys2_shell.cmd 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p) { $full=[IO.Path]::GetFullPath($p); $bash=Join-Path (Split-Path -Parent $full) 'usr\bin\bash.exe'; if ((Split-Path -Leaf $full) -ieq 'msys2_shell.cmd' -and (Test-Path -LiteralPath $full) -and (Test-Path -LiteralPath $bash)) { Write-Output $full; exit 0 } } }; exit 1"
>> "%MSYS2_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%MSYS2_FINDER%"""
call :search_command "MSYS2" "@env" "MSYS2_SHELL"
set "MSYS2_EXIT=!ERRORLEVEL!"
del "%MSYS2_FINDER%" >nul 2>nul
exit /b !MSYS2_EXIT!

:has_pacman_toolchain
call :load_managed_pacman_packages
if errorlevel 1 exit /b 2
call :find_msys2_shell
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
set "PACMAN_CHECKER=%TEMP%\cp_setup_find_pacman_%RANDOM%_%RANDOM%.cmd"
> "%PACMAN_CHECKER%" echo @echo off
>> "%PACMAN_CHECKER%" echo set "MSYSTEM=MINGW64"
>> "%PACMAN_CHECKER%" echo set "CHERE_INVOKING=enabled_from_arguments"
>> "%PACMAN_CHECKER%" echo "%MSYS2_BASH%" -lc "pacman -Qq %PACMAN_PACKAGES%" 2^>nul ^| findstr /r "." ^>nul
>> "%PACMAN_CHECKER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%PACMAN_CHECKER%"""
call :search_command "MSYS2 CP toolchain" "@env" "PACMAN_TOOLCHAIN"
set "PACMAN_CHECK_EXIT=!ERRORLEVEL!"
del "%PACMAN_CHECKER%" >nul 2>nul
exit /b !PACMAN_CHECK_EXIT!

:search_command
setlocal EnableExtensions EnableDelayedExpansion
set "SEARCH_LABEL=%~1"
set "SEARCH_ACTION=%~4"
set "SEARCH_SUCCESS=%~5"
set "SEARCH_SUCCESS_COLOR=%~6"
set "SEARCH_SUCCESS_NO_NEWLINE=%~7"
if not defined SEARCH_ACTION set "SEARCH_ACTION=SEARCHING"
if not defined SEARCH_SUCCESS set "SEARCH_SUCCESS=FOUND"
if not defined SEARCH_SUCCESS_COLOR set "SEARCH_SUCCESS_COLOR=38;5;114"
if not defined SEARCH_SUCCESS_NO_NEWLINE set "SEARCH_SUCCESS_NO_NEWLINE=0"
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
>> "%SEARCH_PS%" echo $action = '[' + $esc + '[38;5;183m' + $env:SEARCH_ACTION + $esc + '[0m]'
>> "%SEARCH_PS%" echo $success = '[' + $esc + '[' + $env:SEARCH_SUCCESS_COLOR + 'm' + $env:SEARCH_SUCCESS + $esc + '[0m]'
>> "%SEARCH_PS%" echo $successNoNewline = $env:SEARCH_SUCCESS_NO_NEWLINE -eq '1'
>> "%SEARCH_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SEARCH_PS%" echo $job = Start-Job -ScriptBlock { param($command) $items = @(^& $env:ComSpec /d /c $command 2^>$null); [pscustomobject]@{ ExitCode = $LASTEXITCODE; Items = $items } } -ArgumentList $command
>> "%SEARCH_PS%" echo $i = 0
>> "%SEARCH_PS%" echo do { Write-Host -NoNewline ($cr + $clear + $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ } while ($job.State -eq 'Running')
>> "%SEARCH_PS%" echo $result = Receive-Job -Wait $job
>> "%SEARCH_PS%" echo Remove-Job $job -Force
>> "%SEARCH_PS%" echo $items = @($result.Items)
>> "%SEARCH_PS%" echo if ($items.Count) { [IO.File]::WriteAllLines($output,[string[]]$items) } else { [IO.File]::WriteAllText($output,'') }
>> "%SEARCH_PS%" echo $exitCode = [int]$result.ExitCode
>> "%SEARCH_PS%" echo if ($exitCode -eq 0) { if ($successNoNewline) { Write-Host -NoNewline ($cr + $clear + $success + ' ' + $label) } else { Write-Host ($cr + $clear + $success + ' ' + $label) } } else { Write-Host -NoNewline ($cr + $clear) }
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
set "DELETE_PS=%TEMP%\cp_setup_delete_%RANDOM%_%RANDOM%.ps1"
if defined CP_DELETE_SIGNAL (
    > "%CP_DELETE_SIGNAL%" echo ready
    cd /d "%TEMP%"
    exit /b 0
)
cd /d "%TEMP%"
> "%DELETE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%DELETE_PS%" echo $root = [IO.Path]::GetFullPath^($env:CP_DELETE_ROOT^)
>> "%DELETE_PS%" echo $marker = Join-Path $root 'scripts\install.bat'
>> "%DELETE_PS%" echo if ^($root -eq [IO.Path]::GetPathRoot^($root^) -or -not ^(Test-Path -LiteralPath $marker^)^) { Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue; exit 1 }
>> "%DELETE_PS%" echo try {
>> "%DELETE_PS%" echo     Start-Sleep -Seconds 1
>> "%DELETE_PS%" echo     $staged = $null
>> "%DELETE_PS%" echo     for ^($attempt = 0; $attempt -lt 20; $attempt++^) {
>> "%DELETE_PS%" echo         $parent = Split-Path -Parent $root
>> "%DELETE_PS%" echo         $name = Split-Path -Leaf $root
>> "%DELETE_PS%" echo         $candidate = Join-Path $parent ^('.' + $name + '.deleting-' + [guid]::NewGuid^(^).ToString^('N'^)^)
>> "%DELETE_PS%" echo         try { Move-Item -LiteralPath $root -Destination $candidate -ErrorAction Stop; $staged = $candidate; break } catch { Start-Sleep -Milliseconds 500 }
>> "%DELETE_PS%" echo     }
>> "%DELETE_PS%" echo     if ^(-not $staged^) {
>> "%DELETE_PS%" echo         Write-Host '[FAILED] CP setup folder is still in use.'
>> "%DELETE_PS%" echo         Write-Host 'Close File Explorer, terminals, editors, or other apps using it, then run uninstall again.'
>> "%DELETE_PS%" echo         exit 1
>> "%DELETE_PS%" echo     }
>> "%DELETE_PS%" echo     for ^($attempt = 0; $attempt -lt 20; $attempt++^) {
>> "%DELETE_PS%" echo         try { Remove-Item -LiteralPath $staged -Recurse -Force -ErrorAction Stop; exit 0 } catch { Start-Sleep -Milliseconds 500 }
>> "%DELETE_PS%" echo     }
>> "%DELETE_PS%" echo     Write-Host '[FAILED] CP setup folder could not be fully deleted because it is still in use.'
>> "%DELETE_PS%" echo     Write-Host 'Close File Explorer, terminals, editors, or other apps using it, then run scripts\uninstall.bat again from:'
>> "%DELETE_PS%" echo     Write-Host ^('  ' + $staged^)
>> "%DELETE_PS%" echo     exit 1
>> "%DELETE_PS%" echo } catch {
>> "%DELETE_PS%" echo     Write-Host ^('[FAILED] CP setup folder cleanup failed: ' + $_.Exception.Message^)
>> "%DELETE_PS%" echo     Write-Host 'Close apps that may be using the folder, then run uninstall again.'
>> "%DELETE_PS%" echo     exit 1
>> "%DELETE_PS%" echo } finally {
>> "%DELETE_PS%" echo     Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
>> "%DELETE_PS%" echo }
start "" /b powershell -NoProfile -ExecutionPolicy Bypass -File "%DELETE_PS%"
exit /b %ERRORLEVEL%

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
call :wait_to_finish
exit /b 1
