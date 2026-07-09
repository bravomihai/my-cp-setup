@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "CHECK_ONLY=0"
set "DRY_RUN=0"
set "VERBOSE=0"

:parse_args
if "%~1"=="" goto parsed_args
if /i "%~1"=="--check" (
    set "CHECK_ONLY=1"
    set "DRY_RUN=1"
    shift
    goto parse_args
)
if /i "%~1"=="--dry-run" (
    set "DRY_RUN=1"
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

call :enable_ansi

echo CP setup root:
echo %ROOT%
echo.

if "%CHECK_ONLY%"=="1" (
    call :check_state
    exit /b %ERRORLEVEL%
)

call :remove_path_entries
if errorlevel 1 goto failed

call :remove_env_vars
if errorlevel 1 goto failed

call :remove_cmd_macros
if errorlevel 1 goto failed

if "%DRY_RUN%"=="1" (
    echo.
    echo [%ESC%[38;5;114mCHECKED%ESC%[0m] Uninstall dry-run completed.
    exit /b 0
)

echo.
echo [%ESC%[32mDONE%ESC%[0m] CP setup environment entries removed.
echo External tools such as Neovim, JDK, MSYS2, and Git were not uninstalled.
echo Restart terminals so environment changes are visible everywhere.
exit /b 0

:enable_ansi
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
exit /b 0

:check_state
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $macros=Join-Path $root 'scripts\cp_macros'; $targets=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $targets += Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $path=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($path -split ';' | Where-Object { $_ }); $foundPath=@($parts | Where-Object { $p=$_; @($targets | Where-Object { $p.TrimEnd('\') -ieq $_.TrimEnd('\') }).Count -gt 0 }); $vars=@('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP') | ForEach-Object { $v=[Environment]::GetEnvironmentVariable($_,'User'); if ($v) { [pscustomobject]@{Name=$_;Value=$v} } }; $autorun=(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; $hasMacro=$autorun -and $autorun.IndexOf($macros,[StringComparison]::OrdinalIgnoreCase) -ge 0; $esc=[char]27; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $clear='['+$esc+'[38;5;114mCLEAR'+$esc+'[0m]'; if ($foundPath.Count) { Write-Host ($found+' PATH entries managed by setup') } else { Write-Host ($clear+' PATH entries managed by setup') }; foreach ($v in $vars) { Write-Host ($found+' '+$v.Name+'='+$v.Value) }; if (-not $vars) { Write-Host ($clear+' CP environment variables') }; if ($hasMacro) { Write-Host ($found+' CMD AutoRun loads cp_macros') } else { Write-Host ($clear+' CMD AutoRun for cp_macros') }"
exit /b %ERRORLEVEL%

:remove_path_entries
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $dry='%DRY_RUN%' -eq '1'; $verbose='%VERBOSE%' -eq '1'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $checked='['+$esc+'[38;5;114mCHECKED'+$esc+'[0m]'; $tag=$removed; if ($dry) { $tag=$checked }; $targets=@((Join-Path $root 'scripts'),'C:\Program Files\Git\cmd','C:\Program Files\Git\usr\bin','C:\Program Files\Git\mingw64\libexec\git-core','D:\software\programming\git\Git\cmd','D:\software\programming\git\Git\usr\bin','D:\software\programming\git\Git\mingw64\libexec\git-core','C:\Program Files\Neovim\bin','D:\software\programming\neovim\bin','C:\msys64\mingw64\bin','C:\msys64\ucrt64\bin','D:\software\programming\msys2\mingw64\bin'); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $targets += Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin' } }; $path=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $path) { $path='' }; $removedList=New-Object System.Collections.Generic.List[string]; $kept=New-Object System.Collections.Generic.List[string]; foreach ($raw in ($path -split ';')) { $p=$raw.Trim(); if (-not $p) { continue }; $match=$false; foreach ($t in $targets) { if ($p.TrimEnd('\') -ieq $t.TrimEnd('\')) { $match=$true; break } }; if ($match) { $removedList.Add($p) } else { $kept.Add($p) } }; if (-not $dry) { [Environment]::SetEnvironmentVariable('Path',($kept -join ';'),'User') }; if ($verbose) { foreach ($p in $removedList) { Write-Host ($removed+' PATH '+$p) } }; Write-Host ($tag+' User PATH entries managed by setup')"
exit /b %ERRORLEVEL%

:remove_env_vars
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root='%ROOT%'; $dry='%DRY_RUN%' -eq '1'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $checked='['+$esc+'[38;5;114mCHECKED'+$esc+'[0m]'; $tag=$removed; if ($dry) { $tag=$checked }; $exact=@{XDG_CONFIG_HOME=$root; CP_SETUP_ROOT=$root}; foreach ($name in $exact.Keys) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if ($v -and $v.TrimEnd('\') -ieq $exact[$name].TrimEnd('\')) { if (-not $dry) { [Environment]::SetEnvironmentVariable($name,$null,'User') }; Write-Host ($tag+' '+$name) } }; $bases=@('C:\msys64','D:\software\programming\msys2'); foreach ($name in @('CP_PYTHON','CP_GPP')) { $v=[Environment]::GetEnvironmentVariable($name,'User'); if (-not $v) { continue }; foreach ($base in $bases) { if ($v.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { if (-not $dry) { [Environment]::SetEnvironmentVariable($name,$null,'User') }; Write-Host ($tag+' '+$name); break } } }"
exit /b %ERRORLEVEL%

:remove_cmd_macros
set "MACROS=%ROOT%\scripts\cp_macros"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$macros='%MACROS%'; $dry='%DRY_RUN%' -eq '1'; $esc=[char]27; $removed='['+$esc+'[38;5;114mREMOVED'+$esc+'[0m]'; $checked='['+$esc+'[38;5;114mCHECKED'+$esc+'[0m]'; $tag=$removed; if ($dry) { $tag=$checked }; $key='HKCU:\Software\Microsoft\Command Processor'; $item=Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue; $autorun=$item.AutoRun; if ($autorun -and $autorun.IndexOf($macros,[StringComparison]::OrdinalIgnoreCase) -ge 0) { if (-not $dry) { Remove-ItemProperty -Path $key -Name AutoRun -ErrorAction Stop }; Write-Host ($tag+' CMD AutoRun cp_macros') }"
exit /b %ERRORLEVEL%

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
exit /b 1
