@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "CHECK_ONLY=0"
set "STATE_KEY=HKCU\Software\my-cp-setup"

:parse_args
if "%~1"=="" goto parsed_args
if /i "%~1"=="--check" (
    set "CHECK_ONLY=1"
    shift
    goto parse_args
)
echo [%ESC%[31mFAILED%ESC%[0m] Unknown argument: %~1
exit /b 1

:parsed_args
call :enable_ansi

echo CP setup root:
echo %ROOT%
echo.

if "%CHECK_ONLY%"=="1" (
    call :check_state
    exit /b %ERRORLEVEL%
)

call :remove_external_components
if errorlevel 1 goto failed

echo.
echo [%ESC%[38;5;183mCHECKING%ESC%[0m] CP setup configuration
call :remove_path_entries
if errorlevel 1 goto failed

call :remove_env_vars
if errorlevel 1 goto failed

call :remove_cmd_macros
if errorlevel 1 goto failed

call :clear_empty_state

echo.
call :ask_yes_no "Remove this CP setup folder too"
if not errorlevel 1 (
    reg delete "%STATE_KEY%" /f >nul 2>nul
    call :schedule_repo_removal
    if errorlevel 1 goto failed
    echo [%ESC%[38;5;153mREMOVING%ESC%[0m] CP setup folder after this window closes.
    echo Restart terminals so environment changes are visible everywhere.
    exit /b 0
)

echo.
echo [%ESC%[32mDONE%ESC%[0m] CP setup configuration removed.
echo External components you kept remain installed.
echo Restart terminals so environment changes are visible everywhere.
exit /b 0

:enable_ansi
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
exit /b 0

:check_state
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $macros=Join-Path $root 'scripts\cp_macros'; $command='doskey /macrofile=\"'+$macros+'\"'; $targets=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $targets += Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $path=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($path -split ';' | Where-Object { $_ }); $foundPath=@($parts | Where-Object { $p=$_; @($targets | Where-Object { $p.TrimEnd('\') -ieq $_.TrimEnd('\') }).Count -gt 0 }); $vars=@('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP') | ForEach-Object { $v=[Environment]::GetEnvironmentVariable($_,'User'); if ($v) { [pscustomobject]@{Name=$_;Value=$v} } }; $autorun=(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; $hasMacro=$autorun -and $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -ge 0; $esc=[char]27; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $clear='['+$esc+'[38;5;114mCLEAR'+$esc+'[0m]'; if ($foundPath.Count) { Write-Host ($found+' PATH entries managed by setup') } else { Write-Host ($clear+' PATH entries managed by setup') }; foreach ($v in $vars) { Write-Host ($found+' '+$v.Name+'='+$v.Value) }; if (-not $vars) { Write-Host ($clear+' CP environment variables') }; if ($hasMacro) { Write-Host ($found+' CMD AutoRun loads cp_macros') } else { Write-Host ($clear+' CMD AutoRun for cp_macros') }"
if errorlevel 1 exit /b 1
for %%V in (Winget.Git Winget.Neovim Winget.JDK Winget.MSYS2 Pacman.Toolchain) do (
    call :state_has "%%V"
    if not errorlevel 1 echo [%ESC%[38;5;114mFOUND%ESC%[0m] %%V installed by this setup
)
exit /b 0

:remove_path_entries
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $targets=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $targets += Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $path=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $path) { $path='' }; $kept=New-Object System.Collections.Generic.List[string]; foreach ($raw in ($path -split ';')) { $p=$raw.Trim(); if (-not $p) { continue }; $match=$false; foreach ($t in $targets) { if ($p.TrimEnd('\') -ieq $t.TrimEnd('\')) { $match=$true; break } }; if (-not $match) { $kept.Add($p) } }; [Environment]::SetEnvironmentVariable('Path',($kept -join ';'),'User'); Write-Host ($removed+' User PATH entries managed by setup')"
exit /b %ERRORLEVEL%

:remove_env_vars
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $exact=@{XDG_CONFIG_HOME=$root; CP_SETUP_ROOT=$root}; foreach ($name in $exact.Keys) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if ($v -and $v.TrimEnd('\') -ieq $exact[$name].TrimEnd('\')) { [Environment]::SetEnvironmentVariable($name,$null,'User'); Write-Host ($removed+' '+$name) } }; $bases=@('C:\msys64','D:\software\programming\msys2'); foreach ($name in @('CP_PYTHON','CP_GPP')) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if (-not $v) { continue }; foreach ($base in $bases) { if ($v.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { [Environment]::SetEnvironmentVariable($name,$null,'User'); Write-Host ($removed+' '+$name); break } } }"
exit /b %ERRORLEVEL%

:remove_cmd_macros
set "MACROS=%ROOT%\scripts\cp_macros"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$macros=$env:MACROS; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $key='HKCU:\Software\Microsoft\Command Processor'; $command='doskey /macrofile=\"'+$macros+'\"'; $autorun=(Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; if ($autorun -and $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $pattern='(?i)(?:^\s*|\s*&\s*)'+[regex]::Escape($command)+'(?=\s*(?:&|$))'; $updated=[regex]::Replace($autorun,$pattern,'').Trim(); $updated=[regex]::Replace($updated,'^\s*&\s*',''); $updated=[regex]::Replace($updated,'\s*&\s*$',''); if ($updated) { Set-ItemProperty -Path $key -Name AutoRun -Value $updated } else { Remove-ItemProperty -Path $key -Name AutoRun -ErrorAction Stop }; Write-Host ($removed+' CMD AutoRun cp_macros') }"
exit /b %ERRORLEVEL%

:remove_external_components
call :uninstall_winget_component "Git" "Git.Git" "git" "Winget.Git"
if errorlevel 1 exit /b 1
call :uninstall_winget_component "Neovim" "Neovim.Neovim" "nvim" "Winget.Neovim"
if errorlevel 1 exit /b 1
call :uninstall_winget_component "JDK" "EclipseAdoptium.Temurin.21.JDK" "javac" "Winget.JDK"
if errorlevel 1 exit /b 1

call :find_msys2_shell
if errorlevel 1 exit /b 0

echo.
echo [%ESC%[38;5;114mFOUND%ESC%[0m] MSYS2 installed by this setup
call :ask_yes_no "Uninstall MSYS2 and its CP toolchain"
if errorlevel 1 goto maybe_pacman

call :uninstall_winget_now "MSYS2" "MSYS2.MSYS2"
if errorlevel 1 exit /b 1
call :clear_state "Winget.MSYS2"
call :clear_state "Pacman.Toolchain"
exit /b 0

:maybe_pacman
call :has_pacman_toolchain
if errorlevel 1 exit /b 0
call :uninstall_pacman_toolchain
exit /b %ERRORLEVEL%

:uninstall_winget_component
call :command_exists "%~3"
if errorlevel 1 exit /b 0

echo.
echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1 installed by this setup
call :ask_yes_no "Uninstall %~1"
if errorlevel 1 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1
    exit /b 0
)

call :uninstall_winget_now "%~1" "%~2"
if errorlevel 1 exit /b 1
call :clear_state "%~4"
exit /b 0

:uninstall_winget_now
call :require_winget
if errorlevel 1 exit /b 1
set "UNINSTALL_CMD="%WINGET%" uninstall --id %~2 --exact --source winget --disable-interactivity --silent"
call :run_command_spinner "%~1 via winget: %~2" "" "%TEMP%\cp_setup_winget_uninstall.log" "UNINSTALLING" "UNINSTALLED"
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] winget uninstall failed for %~1.
echo Log: %TEMP%\cp_setup_winget_uninstall.log
exit /b 1

:uninstall_pacman_toolchain
echo.
echo [%ESC%[38;5;114mFOUND%ESC%[0m] MSYS2 CP toolchain packages
call :ask_yes_no "Remove the CP toolchain from MSYS2"
if errorlevel 1 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 CP toolchain
    exit /b 0
)

call :find_msys2_shell
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was not found; the toolchain cannot be removed with pacman.
    exit /b 1
)
set "PACMAN_COMMAND=pacman -Rns --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python"
call :run_pacman_spinner "UNINSTALLING" "UNINSTALLED"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain uninstall failed.
    echo Log: %TEMP%\cp_setup_pacman_uninstall.log
    exit /b 1
)
call :clear_state "Pacman.Toolchain"
exit /b 0

:state_has
reg query "%STATE_KEY%" /v "%~1" >nul 2>nul
exit /b %ERRORLEVEL%

:command_exists
where "%~1" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_state
reg delete "%STATE_KEY%" /v "%~1" /f >nul 2>nul
exit /b 0

:clear_empty_state
for %%V in (Winget.Git Winget.Neovim Winget.JDK Winget.MSYS2 Pacman.Toolchain) do (
    call :state_has "%%V"
    if not errorlevel 1 exit /b 0
)
reg delete "%STATE_KEY%" /f >nul 2>nul
exit /b 0

:ask_yes_no
choice /C YN /N /M "%~1"
if errorlevel 2 exit /b 1
exit /b 0

:require_winget
set "WINGET="
for /F "usebackq delims=" %%P in (`where winget 2^>nul`) do if not defined WINGET set "WINGET=%%P"
if not defined WINGET if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" set "WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if defined WINGET exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] winget was not found.
exit /b 1

:find_msys2_shell
set "MSYS2_SHELL="
if exist "C:\msys64\msys2_shell.cmd" set "MSYS2_SHELL=C:\msys64\msys2_shell.cmd"
if not defined MSYS2_SHELL if exist "D:\software\programming\msys2\msys2_shell.cmd" set "MSYS2_SHELL=D:\software\programming\msys2\msys2_shell.cmd"
if defined MSYS2_SHELL exit /b 0
for /F "usebackq delims=" %%P in (`where msys2_shell.cmd 2^>nul`) do if not defined MSYS2_SHELL set "MSYS2_SHELL=%%P"
if defined MSYS2_SHELL exit /b 0
exit /b 1

:has_pacman_toolchain
call :find_msys2_shell
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
"%MSYS2_BASH%" -lc "pacman -Q mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python > /dev/null 2>&1"
exit /b %ERRORLEVEL%

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
> "%DELETE_CMD%" echo @echo off
>> "%DELETE_CMD%" echo ping 127.0.0.1 -n 3 ^>nul
>> "%DELETE_CMD%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=[IO.Path]::GetFullPath($env:CP_DELETE_ROOT); $marker=Join-Path $root 'scripts\install.bat'; if ($root -eq [IO.Path]::GetPathRoot($root) -or -not (Test-Path -LiteralPath $marker)) { exit 1 }; Remove-Item -LiteralPath $root -Recurse -Force"
>> "%DELETE_CMD%" echo del "%%~f0"
start "" /b "%ComSpec%" /d /c call "%DELETE_CMD%"
exit /b %ERRORLEVEL%

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
exit /b 1
