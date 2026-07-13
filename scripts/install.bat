@echo off
setlocal EnableExtensions DisableDelayedExpansion

for /F "tokens=1 delims=#" %%A in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%A"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "ORIGINAL_ARGS=%*"

set "CHECK_ONLY=0"
set "VERBOSE=0"
set "MISSING_COUNT=0"
set "TOOLCHAIN_INSTALLED=0"
set "STATE_KEY=HKCU\Software\my-cp-setup"
set "STATE_SCHEMA=4"
set "ACL_COMMIT=864245a00b00dd008d1abfdc239618fdb7d139da"
set "ACL_TREE_HASH=354f77a3274dcf906fa5a79d8beaba6a9c497b5435180cd0e7d41b613b7fb9d3"
set "MASON_TOOLS=pyright jdtls google-java-format clangd"
set "PACMAN_PACKAGES_ALLOWED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff"
set "WINGET_ARGS=--exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity"
set "WINGET_QUIET_ARGS=%WINGET_ARGS% --silent"

call :validate_setup_root
if errorlevel 1 exit /b 1
setlocal EnableDelayedExpansion

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
    call :initialize_state
    if errorlevel 1 exit /b 1
) else (
    call :check_state_root
    if errorlevel 1 exit /b 1
)
call :enable_ansi "%CHECK_ONLY%"

echo CP setup root:
echo %ROOT%
echo.

call :refresh_path

if "%CHECK_ONLY%"=="1" (
    echo Checking main components...
) else (
    echo Installing main components...
)

call :need_git
if errorlevel 1 goto failed
call :need_nvim
if errorlevel 1 goto failed
call :need_node_and_npm
if errorlevel 1 goto failed
call :need_jdk
if errorlevel 1 goto failed

call :find_gpp
if errorlevel 1 (
    if "%CHECK_ONLY%"=="1" (
        call :print_missing "g++"
    ) else (
        call :install_msys2_toolchain
        if errorlevel 1 goto failed
        set "TOOLCHAIN_INSTALLED=1"
    )
)

if "%CHECK_ONLY%"=="1" if not "%MISSING_COUNT%"=="0" goto skip_gpp_validation
call :find_gpp quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ was installed, but g++.exe was not found in known MSYS2 paths.
    goto failed
)
:skip_gpp_validation

if "%TOOLCHAIN_INSTALLED%"=="1" goto set_python_from_toolchain
call :find_python
if errorlevel 1 (
    if "%CHECK_ONLY%"=="1" (
        call :print_missing "Python 3.10 or newer"
    ) else (
        call :install_msys2_toolchain
        if errorlevel 1 goto failed
        set "TOOLCHAIN_INSTALLED=1"
    )
)

:set_python_from_toolchain
if "%TOOLCHAIN_INSTALLED%"=="1" (
    call :find_python quiet
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Python was installed, but python.exe was not found in the selected MSYS2 toolchain.
        goto failed
    )
)

call :ensure_ruff
if errorlevel 1 goto failed

if "%CHECK_ONLY%"=="1" (
    if "%VERBOSE%"=="1" (
        call :install_paths check
        if errorlevel 1 goto failed
    )
    call :check_env_paths
    if errorlevel 1 call :print_missing "Environment paths"
    call :check_config_integrity
    if errorlevel 1 call :print_missing "CP setup configuration"
) else (
    call :install_paths
    if errorlevel 1 goto failed
)
call :refresh_path

echo.
if "%CHECK_ONLY%"=="1" (
    echo Checking libraries...
    call :check_ac_library
) else (
    echo Installing libraries...
    call :ensure_ac_library
)
if errorlevel 1 goto failed
echo.

if "%CHECK_ONLY%"=="1" call :check_mason_tools

if "%CHECK_ONLY%"=="1" if not "%MISSING_COUNT%"=="0" goto check_missing

if "%CHECK_ONLY%"=="0" (
    call :prepare_config_mutation
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME',$env:ROOT,'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Environment]::SetEnvironmentVariable('CP_SETUP_ROOT',$env:ROOT,'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Environment]::SetEnvironmentVariable('CP_PYTHON',$env:CP_PYTHON,'User')"
    if errorlevel 1 goto failed
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Environment]::SetEnvironmentVariable('CP_GPP',$env:CP_GPP,'User'); [Environment]::SetEnvironmentVariable('CP_JAVAC',$env:CP_JAVAC,'User'); [Environment]::SetEnvironmentVariable('CP_JAVA',$env:CP_JAVA,'User')"
    if errorlevel 1 goto failed

    set "XDG_CONFIG_HOME=%ROOT%"
    set "CP_SETUP_ROOT=%ROOT%"
    call :install_cmd_macros
    if errorlevel 1 goto failed
    call :record_autorun_written_state
    if errorlevel 1 goto failed
    call :record_component "Config.Managed"
    if errorlevel 1 goto failed
    call :prepare_nvim_bootstrap
    if errorlevel 1 goto failed
    call :bootstrap_nvim_tools
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

:validate_setup_root
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:ROOT; if ($root -notmatch '^[A-Za-z]:\\') { exit 1 }; foreach ($code in @(33,37,38,59,60,62,94,124)) { if ($root.IndexOf([char]$code) -ge 0) { exit 1 } }; foreach ($name in @('TEMP','LOCALAPPDATA','APPDATA')) { $value=[Environment]::GetEnvironmentVariable($name); if ($value -and $value.IndexOf([char]33) -ge 0) { exit 2 } }; exit 0"
if not errorlevel 1 exit /b 0
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] TEMP, LOCALAPPDATA, and APPDATA paths cannot contain exclamation marks.
    echo Move the affected profile or temporary directory before running this installer.
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] The setup path cannot contain CMD metacharacters.
echo Use a local drive path without exclamation marks, percent signs, ampersands, semicolons, pipes, angle brackets, or carets.
exit /b 1

:check_state_root
set "STATE_ROOT_CHECK=%TEMP%\cp_setup_state_root_%RANDOM%_%RANDOM%.ps1"
> "%STATE_ROOT_CHECK%" echo $ErrorActionPreference = 'Stop'
>> "%STATE_ROOT_CHECK%" echo $key = 'HKCU:\Software\my-cp-setup'
>> "%STATE_ROOT_CHECK%" echo $root = [IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^)
>> "%STATE_ROOT_CHECK%" echo $stored = $null
>> "%STATE_ROOT_CHECK%" echo if ^(Test-Path -LiteralPath $key^) { $stored = ^(Get-ItemProperty -Path $key -Name 'Install.Root' -ErrorAction SilentlyContinue^).'Install.Root' }
>> "%STATE_ROOT_CHECK%" echo if ^(-not $stored^) { $stored = [Environment]::GetEnvironmentVariable^('CP_SETUP_ROOT','User'^) }
>> "%STATE_ROOT_CHECK%" echo if ^($stored -and $stored.TrimEnd^([char]92^) -ine $root^) { Write-Host ^('[FAILED] This setup is already managed from: ' + $stored^); Write-Host 'Uninstall it from that folder before using a different root.'; exit 1 }
>> "%STATE_ROOT_CHECK%" echo exit 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%STATE_ROOT_CHECK%"
set "STATE_ROOT_EXIT=%ERRORLEVEL%"
del "%STATE_ROOT_CHECK%" >nul 2>nul
exit /b %STATE_ROOT_EXIT%

:initialize_state
call :check_state_root
if errorlevel 1 exit /b 1
set "STATE_INIT_PS=%TEMP%\cp_setup_state_init_%RANDOM%_%RANDOM%.ps1"
> "%STATE_INIT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%STATE_INIT_PS%" echo $key = 'HKCU:\Software\my-cp-setup'
>> "%STATE_INIT_PS%" echo $root = [IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^)
>> "%STATE_INIT_PS%" echo $macros = Join-Path $root 'scripts\cp_macros'
>> "%STATE_INIT_PS%" echo $macroCommand = 'doskey /macrofile="' + $macros + '"'
>> "%STATE_INIT_PS%" echo if ^(-not ^(Test-Path -LiteralPath $key^)^) { New-Item -Path $key -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo $snapshot = ^(Get-ItemProperty -Path $key -Name 'Snapshot.Complete' -ErrorAction SilentlyContinue^).'Snapshot.Complete'
>> "%STATE_INIT_PS%" echo if ^($null -eq $snapshot^) {
>> "%STATE_INIT_PS%" echo     $managedValue = ^(Get-ItemProperty -Path $key -Name 'Config.Managed' -ErrorAction SilentlyContinue^).'Config.Managed'
>> "%STATE_INIT_PS%" echo     $configuredRoot = [Environment]::GetEnvironmentVariable^('CP_SETUP_ROOT','User'^)
>> "%STATE_INIT_PS%" echo     $legacyManaged = $null -ne $managedValue -or ^($configuredRoot -and $configuredRoot.TrimEnd^([char]92^) -ieq $root^)
>> "%STATE_INIT_PS%" echo     foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) {
>> "%STATE_INIT_PS%" echo         $value = [Environment]::GetEnvironmentVariable^($name,'User'^)
>> "%STATE_INIT_PS%" echo         $setupOwned = $false
>> "%STATE_INIT_PS%" echo         if ^($legacyManaged^) { if ^($name -eq 'XDG_CONFIG_HOME' -or $name -eq 'CP_SETUP_ROOT'^) { $setupOwned = $value -and $value.TrimEnd^([char]92^) -ieq $root } elseif ^($name -eq 'CP_PYTHON' -or $name -eq 'CP_GPP'^) { $setupOwned = $true } }
>> "%STATE_INIT_PS%" echo         $hadValue = $null -ne $value -and -not $setupOwned
>> "%STATE_INIT_PS%" echo         New-ItemProperty -Path $key -Name ^('Env.' + $name + '.HadValue'^) -PropertyType DWord -Value ^([int]$hadValue^) -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo         if ^($hadValue^) { New-ItemProperty -Path $key -Name ^('Env.' + $name + '.Before'^) -PropertyType String -Value $value -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo     }
>> "%STATE_INIT_PS%" echo     $path = [Environment]::GetEnvironmentVariable^('Path','User'^); if ^($null -eq $path^) { $path = '' }
>> "%STATE_INIT_PS%" echo     $pathBefore = $path
>> "%STATE_INIT_PS%" echo     if ^($legacyManaged^) {
>> "%STATE_INIT_PS%" echo         $rootScripts = ^(Join-Path $root 'scripts'^).TrimEnd^([char]92^)
>> "%STATE_INIT_PS%" echo         $parts = @^($path -split ';' ^| Where-Object { $_ -and $_.Trim^(^).TrimEnd^([char]92^) -ine $rootScripts }^)
>> "%STATE_INIT_PS%" echo         $pathBefore = $parts -join ';'
>> "%STATE_INIT_PS%" echo         if ^(@^($path -split ';' ^| Where-Object { $_ -and $_.Trim^(^).TrimEnd^([char]92^) -ieq $rootScripts }^).Count^) { $existing = @^((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue^).'Path.Entries' ^| Where-Object { $_ }^); $merged = @^($existing + $rootScripts ^| Sort-Object -Unique^); New-ItemProperty -Path $key -Name 'Path.Entries' -PropertyType MultiString -Value ^([string[]]$merged^) -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo     }
>> "%STATE_INIT_PS%" echo     New-ItemProperty -Path $key -Name 'Path.Before' -PropertyType String -Value $pathBefore -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo     $autoKey = 'HKCU:\Software\Microsoft\Command Processor'
>> "%STATE_INIT_PS%" echo     $autorun = ^(Get-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue^).AutoRun
>> "%STATE_INIT_PS%" echo     $autorunBefore = $autorun
>> "%STATE_INIT_PS%" echo     if ^($legacyManaged -and $autorun^) { if ^($autorun -ieq $macroCommand^) { $autorunBefore = $null } elseif ^($autorun.EndsWith^(' ^& ' + $macroCommand,[StringComparison]::OrdinalIgnoreCase^)^) { $autorunBefore = $autorun.Substring^(0,$autorun.Length - $macroCommand.Length - 3^) } }
>> "%STATE_INIT_PS%" echo     New-ItemProperty -Path $key -Name 'AutoRun.HadValue' -PropertyType DWord -Value ^([int]^($null -ne $autorunBefore^)^) -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo     if ^($null -ne $autorunBefore^) { New-ItemProperty -Path $key -Name 'AutoRun.Before' -PropertyType String -Value $autorunBefore -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo     $consoleKey = 'HKCU:\Console'
>> "%STATE_INIT_PS%" echo     $consoleProperty = Get-ItemProperty -Path $consoleKey -Name VirtualTerminalLevel -ErrorAction SilentlyContinue
>> "%STATE_INIT_PS%" echo     $consoleHadValue = $null -ne $consoleProperty
>> "%STATE_INIT_PS%" echo     New-ItemProperty -Path $key -Name 'Console.VirtualTerminal.HadValue' -PropertyType DWord -Value ^([int]$consoleHadValue^) -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo     if ^($consoleHadValue^) { New-ItemProperty -Path $key -Name 'Console.VirtualTerminal.Before' -PropertyType DWord -Value ^([int]$consoleProperty.VirtualTerminalLevel^) -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo     $nvimData = Join-Path $env:LOCALAPPDATA 'nvim-data'
>> "%STATE_INIT_PS%" echo     New-ItemProperty -Path $key -Name 'NvimData.Existed' -PropertyType DWord -Value ^([int]^(Test-Path -LiteralPath $nvimData^)^) -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo     $masonPackages = Join-Path $nvimData 'mason\packages'
>> "%STATE_INIT_PS%" echo     $masonBefore = @^(Get-ChildItem -LiteralPath $masonPackages -Directory -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty Name^)
>> "%STATE_INIT_PS%" echo     if ^($masonBefore.Count^) { New-ItemProperty -Path $key -Name 'Mason.Packages.Before' -PropertyType MultiString -Value ^([string[]]$masonBefore^) -Force ^| Out-Null }
>> "%STATE_INIT_PS%" echo     New-ItemProperty -Path $key -Name 'Snapshot.Complete' -PropertyType DWord -Value 1 -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo }
>> "%STATE_INIT_PS%" echo $currentSchema = ^(Get-ItemProperty -Path $key -Name 'SchemaVersion' -ErrorAction SilentlyContinue^).SchemaVersion
>> "%STATE_INIT_PS%" echo if ^($null -eq $currentSchema^) { $currentSchema = 0 }
>> "%STATE_INIT_PS%" echo if ^($currentSchema -lt 3^) {
>> "%STATE_INIT_PS%" echo     foreach ^($name in @^('CP_JAVAC','CP_JAVA'^)^) {
>> "%STATE_INIT_PS%" echo         $hadName = 'Env.' + $name + '.HadValue'
>> "%STATE_INIT_PS%" echo         $beforeName = 'Env.' + $name + '.Before'
>> "%STATE_INIT_PS%" echo         $hadProperty = Get-ItemProperty -Path $key -Name $hadName -ErrorAction SilentlyContinue
>> "%STATE_INIT_PS%" echo         if ^($null -eq $hadProperty^) { $value = [Environment]::GetEnvironmentVariable^($name,'User'^); $hadValue = $null -ne $value; New-ItemProperty -Path $key -Name $hadName -PropertyType DWord -Value ^([int]$hadValue^) -Force ^| Out-Null; if ^($hadValue^) { New-ItemProperty -Path $key -Name $beforeName -PropertyType String -Value $value -Force ^| Out-Null } }
>> "%STATE_INIT_PS%" echo     }
>> "%STATE_INIT_PS%" echo }
>> "%STATE_INIT_PS%" echo if ^($currentSchema -lt 4^) {
>> "%STATE_INIT_PS%" echo     $managed = ^(Get-ItemProperty -Path $key -Name 'Config.Managed' -ErrorAction SilentlyContinue^).'Config.Managed'
>> "%STATE_INIT_PS%" echo     if ^($null -ne $managed^) {
>> "%STATE_INIT_PS%" echo         New-ItemProperty -Path $key -Name 'Config.MutationStarted' -PropertyType DWord -Value 1 -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo         New-ItemProperty -Path $key -Name 'Nvim.BootstrapStarted' -PropertyType DWord -Value 1 -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo         $nvimData = Join-Path $env:LOCALAPPDATA 'nvim-data'; $sha = [Security.Cryptography.SHA256]::Create^(^); $rootHash = ^([BitConverter]::ToString^($sha.ComputeHash^([Text.UTF8Encoding]::new^($false^).GetBytes^($root^)^)^)^).Replace^('-',''^).ToLowerInvariant^(^); $jdtls = Join-Path $nvimData ^('jdtls-workspaces\cp-' + $rootHash.Substring^(0,16^)^)
>> "%STATE_INIT_PS%" echo         New-ItemProperty -Path $key -Name 'JdtlsWorkspace.Path' -PropertyType String -Value ^([IO.Path]::GetFullPath^($jdtls^)^) -Force ^| Out-Null; New-ItemProperty -Path $key -Name 'JdtlsWorkspace.Existed' -PropertyType DWord -Value ^([int]^(Test-Path -LiteralPath $jdtls^)^) -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo     }
>> "%STATE_INIT_PS%" echo }
>> "%STATE_INIT_PS%" echo New-ItemProperty -Path $key -Name 'Install.Root' -PropertyType String -Value $root -Force ^| Out-Null
>> "%STATE_INIT_PS%" echo New-ItemProperty -Path $key -Name 'SchemaVersion' -PropertyType DWord -Value %STATE_SCHEMA% -Force ^| Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File "%STATE_INIT_PS%"
set "STATE_INIT_EXIT=%ERRORLEVEL%"
del "%STATE_INIT_PS%" >nul 2>nul
exit /b %STATE_INIT_EXIT%

:enable_ansi
if not "%~1"=="1" reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Namespace Native -Name Console -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern System.IntPtr GetStdHandle(int nStdHandle); [DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out int lpMode); [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, int dwMode);'; $h=[Native.Console]::GetStdHandle(-11); $mode=0; if ([Native.Console]::GetConsoleMode($h,[ref]$mode)) { [Native.Console]::SetConsoleMode($h,$mode -bor 4) | Out-Null }" >nul 2>nul
exit /b 0

:ensure_admin
powershell -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1"
if not errorlevel 1 exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); foreach ($group in $id.Groups) { if ($group.Value -eq 'S-1-5-32-544') { exit 0 } }; exit 1"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup must be installed from an account in the local Administrators group.
    echo Sign in with an administrator account and run this installer again.
    exit /b 1
)

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
call :find_git
if not errorlevel 1 goto git_ready

if "%CHECK_ONLY%"=="1" (
    call :print_missing "Git"
    exit /b 0
)

call :require_winget
if errorlevel 1 exit /b 1

set "PACKAGE_PREEXISTED=0"
call :winget_has_package "Git.Git"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
set "INSTALL_CMD=!WINGET! install --id Git.Git %WINGET_QUIET_ARGS%"
call :run_install_spinner "Git via winget: Git.Git" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :capture_winget_install_result "Git.Git" "Winget.Git"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_git
if not errorlevel 1 (
    if "!PACKAGE_PREEXISTED!"=="0" (
        call :record_component_path "Winget.Git" "!FOUND_GIT_PATH!"
        if errorlevel 1 exit /b 1
    )
    if "%VERBOSE%"=="1" echo   %FOUND_GIT_PATH%
    goto git_ready
)
if not "%INSTALL_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for Git.
    echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] Git was not found after winget install.
echo Log: %TEMP%\cp_setup_winget.log
exit /b 1

:git_ready
for %%I in ("%FOUND_GIT_PATH%") do set "PATH=%%~dpI;%PATH%"
exit /b 0

:find_git
set "GIT_FINDER=%TEMP%\cp_setup_find_git_%RANDOM%_%RANDOM%.cmd"
> "%GIT_FINDER%" echo @echo off
>> "%GIT_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@((Get-ItemProperty -Path $key -Name 'Winget.Git.Path' -ErrorAction SilentlyContinue).'Winget.Git.Path','C:\Program Files\Git\cmd\git.exe'); $w=where.exe git 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version > $null 2>&1; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%GIT_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%GIT_FINDER%"""
call :search_command "Git" "@env" "FOUND_GIT_PATH"
set "GIT_FIND_EXIT=!ERRORLEVEL!"
del "%GIT_FINDER%" >nul 2>nul
exit /b !GIT_FIND_EXIT!

:need_node_and_npm
call :find_node
if not errorlevel 1 goto node_ready
if "%CHECK_ONLY%"=="1" (
    call :print_missing "Node.js LTS"
    exit /b 0
)
call :require_winget
if errorlevel 1 exit /b 1
set "PACKAGE_PREEXISTED=0"
call :winget_has_package "OpenJS.NodeJS.LTS"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
set "INSTALL_CMD=!WINGET! install --id OpenJS.NodeJS.LTS %WINGET_QUIET_ARGS%"
call :run_install_spinner "Node.js LTS via winget: OpenJS.NodeJS.LTS" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :capture_winget_install_result "OpenJS.NodeJS.LTS" "Winget.Node"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_node
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Node.js LTS was not found after winget install.
    echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
if "!PACKAGE_PREEXISTED!"=="0" (
    call :record_component_path "Winget.Node" "!FOUND_NODE_PATH!"
    if errorlevel 1 exit /b 1
)

:node_ready
call :find_npm
if not errorlevel 1 exit /b 0
if "%CHECK_ONLY%"=="1" (
    call :print_missing "npm"
    exit /b 0
)
call :require_winget
if errorlevel 1 exit /b 1
set "PACKAGE_PREEXISTED=0"
call :winget_has_package "OpenJS.NodeJS.LTS"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
set "INSTALL_CMD=!WINGET! install --id OpenJS.NodeJS.LTS %WINGET_QUIET_ARGS% --force"
call :run_install_spinner "npm via winget: OpenJS.NodeJS.LTS" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :capture_winget_install_result "OpenJS.NodeJS.LTS" "Winget.Node"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_node
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Node.js LTS was not found after reinstalling its winget package.
    exit /b 1
)
call :find_npm
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] npm was not found after installing Node.js LTS.
    exit /b 1
)
if "!PACKAGE_PREEXISTED!"=="0" (
    call :record_component_path "Winget.Node" "!FOUND_NODE_PATH!"
    if errorlevel 1 exit /b 1
)
exit /b 0

:find_node
set "NODE_FINDER=%TEMP%\cp_setup_find_node_%RANDOM%_%RANDOM%.cmd"
> "%NODE_FINDER%" echo @echo off
>> "%NODE_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@((Get-ItemProperty -Path $key -Name 'Winget.Node.Path' -ErrorAction SilentlyContinue).'Winget.Node.Path','C:\Program Files\nodejs\node.exe'); $w=where.exe node 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version > $null 2>&1; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%NODE_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%NODE_FINDER%"""
call :search_command "Node.js LTS" "@env" "FOUND_NODE_PATH"
set "NODE_FIND_EXIT=!ERRORLEVEL!"
del "%NODE_FINDER%" >nul 2>nul
exit /b !NODE_FIND_EXIT!

:find_npm
set "NPM_FINDER=%TEMP%\cp_setup_find_npm_%RANDOM%_%RANDOM%.cmd"
> "%NPM_FINDER%" echo @echo off
>> "%NPM_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $saved=(Get-ItemProperty -Path $key -Name 'Winget.Node.Path' -ErrorAction SilentlyContinue).'Winget.Node.Path'; $c=@('C:\Program Files\nodejs\npm.cmd'); foreach ($node in @($env:FOUND_NODE_PATH,$saved)) { if ($node) { $c += Join-Path (Split-Path -Parent $node) 'npm.cmd' } }; $w=where.exe npm.cmd 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version > $null 2>&1; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%NPM_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%NPM_FINDER%"""
call :search_command "npm" "@env" "FOUND_NPM_PATH"
set "NPM_FIND_EXIT=!ERRORLEVEL!"
del "%NPM_FINDER%" >nul 2>nul
exit /b !NPM_FIND_EXIT!

:need_nvim
call :find_nvim_011
if not errorlevel 1 exit /b 0
if "%CHECK_ONLY%"=="1" (
    call :print_missing "Neovim 0.11 or newer"
    exit /b 0
)
call :install_or_upgrade_winget "Neovim.Neovim" "Neovim" "Winget.Neovim"
if errorlevel 1 exit /b 1
call :find_nvim_011
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Neovim 0.11 or newer was not found after winget install.
    exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="0" (
    call :record_component_path "Winget.Neovim" "%FOUND_NVIM_PATH%"
    if errorlevel 1 exit /b 1
)
exit /b 0

:find_nvim_011
set "NVIM_FINDER=%TEMP%\cp_setup_find_nvim_%RANDOM%_%RANDOM%.cmd"
> "%NVIM_FINDER%" echo @echo off
>> "%NVIM_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@((Get-ItemProperty -Path $key -Name 'Winget.Neovim.Path' -ErrorAction SilentlyContinue).'Winget.Neovim.Path','C:\Program Files\Neovim\bin\nvim.exe'); $w=where.exe nvim 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { $line=(& $p --version 2>&1 | Select-Object -First 1); if ($line -match 'v?(\d+)\.(\d+)' -and ([int]$Matches[1] -gt 0 -or [int]$Matches[2] -ge 11)) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%NVIM_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%NVIM_FINDER%"""
call :search_command "Neovim 0.11 or newer" "@env" "FOUND_NVIM_PATH"
set "NVIM_FIND_EXIT=!ERRORLEVEL!"
del "%NVIM_FINDER%" >nul 2>nul
exit /b !NVIM_FIND_EXIT!

:need_jdk
call :find_javac_21
if not errorlevel 1 goto jdk_ready
if "%CHECK_ONLY%"=="1" (
    call :print_missing "JDK 21 or newer"
    exit /b 0
)
call :install_or_upgrade_winget "EclipseAdoptium.Temurin.21.JDK" "JDK" "Winget.JDK"
if errorlevel 1 exit /b 1
call :find_javac_21
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] JDK 21 or newer was not found after winget install.
    exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="0" (
    call :record_component_path "Winget.JDK" "%FOUND_JAVAC_PATH%"
    if errorlevel 1 exit /b 1
)
:jdk_ready
for %%I in ("%FOUND_JAVAC_PATH%") do (
    set "FOUND_JAVA_PATH=%%~dpIjava.exe"
    set "PATH=%%~dpI;%PATH%"
)
if not exist "%FOUND_JAVA_PATH%" (
    echo [%ESC%[31mFAILED%ESC%[0m] A Java runtime matching javac was not found.
    exit /b 1
)
set "CP_JAVAC=%FOUND_JAVAC_PATH%"
set "CP_JAVA=%FOUND_JAVA_PATH%"
exit /b 0

:find_javac_21
set "JAVAC_FINDER=%TEMP%\cp_setup_find_javac_%RANDOM%_%RANDOM%.cmd"
> "%JAVAC_FINDER%" echo @echo off
>> "%JAVAC_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@((Get-ItemProperty -Path $key -Name 'Winget.JDK.Path' -ErrorAction SilentlyContinue).'Winget.JDK.Path'); if (Test-Path -LiteralPath 'C:\Program Files\Eclipse Adoptium') { $c += Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'bin\javac.exe' } }; $w=where.exe javac 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { $java=Join-Path (Split-Path -Parent $p) 'java.exe'; if (Test-Path -LiteralPath $java -PathType Leaf) { $javacLine=(& $p -version 2>&1 | Select-Object -First 1); $javaLine=(& $java -version 2>&1 | Select-Object -First 1); if ($javacLine -match 'javac\s+(\d+)') { $javacMajor=[int]$Matches[1]; if ($javaLine -match 'version\s+[^0-9]*(\d+)') { $javaMajor=[int]$Matches[1]; if ($javacMajor -ge 21 -and $javaMajor -ge 21) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } } } } }; exit 1"
>> "%JAVAC_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%JAVAC_FINDER%"""
call :search_command "JDK 21 or newer" "@env" "FOUND_JAVAC_PATH"
set "JAVAC_FIND_EXIT=!ERRORLEVEL!"
del "%JAVAC_FINDER%" >nul 2>nul
exit /b !JAVAC_FIND_EXIT!

:install_or_upgrade_winget
call :require_winget
if errorlevel 1 exit /b 1
set "PACKAGE_PREEXISTED=0"
call :winget_has_package "%~1"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
if "%PACKAGE_PREEXISTED%"=="1" (
    set "INSTALL_CMD=!WINGET! upgrade --id %~1 %WINGET_QUIET_ARGS%"
) else (
    set "INSTALL_CMD=!WINGET! install --id %~1 %WINGET_QUIET_ARGS%"
)
call :run_install_spinner "%~2 via winget: %~1" "" "%TEMP%\cp_setup_winget.log"
set "INSTALL_EXIT=%ERRORLEVEL%"
call :capture_winget_install_result "%~1" "%~3"
if errorlevel 1 exit /b 1
call :refresh_path
exit /b 0

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
if "%AC_LIBRARY_NEEDS_UPDATE%"=="1" call :print_missing "ac-library at pinned commit %ACL_COMMIT%"
exit /b 0

:ensure_ac_library
call :ac_library_needs_update
if errorlevel 1 exit /b 1
if "%AC_LIBRARY_NEEDS_UPDATE%"=="0" exit /b 0
if exist "%ROOT%\.git" (
    call :update_ac_library
) else (
    call :bootstrap_ac_library_archive
)
exit /b %ERRORLEVEL%

:ac_library_needs_update
set "AC_LIBRARY_NEEDS_UPDATE=0"
set "AC_LIBRARY_PATH=%ROOT%\libraries\ac-library"
if not exist "%AC_LIBRARY_PATH%\expander.py" (
    set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
if not exist "%ROOT%\.git" (
    call :compute_ac_library_tree_hash "%AC_LIBRARY_PATH%"
    if errorlevel 1 exit /b 1
    if /i not "%AC_LIBRARY_TREE_ACTUAL%"=="%ACL_TREE_HASH%" set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
if not defined FOUND_GIT_PATH exit /b 1
if not exist "%ROOT%\.gitmodules" exit /b 1
set "AC_LIBRARY_EXPECTED="
for /F "tokens=3" %%P in ('git -C "%ROOT%" ls-tree HEAD -- libraries/ac-library 2^>nul') do if not defined AC_LIBRARY_EXPECTED set "AC_LIBRARY_EXPECTED=%%P"
if not defined AC_LIBRARY_EXPECTED exit /b 1
if /i not "%AC_LIBRARY_EXPECTED%"=="%ACL_COMMIT%" (
    echo [%ESC%[31mFAILED%ESC%[0m] install.bat ACL_COMMIT does not match the repository gitlink.
    exit /b 1
)
set "AC_LIBRARY_LOCAL="
for /F "usebackq delims=" %%P in (`git -C "%AC_LIBRARY_PATH%" rev-parse HEAD 2^>nul`) do if not defined AC_LIBRARY_LOCAL set "AC_LIBRARY_LOCAL=%%P"
if not defined AC_LIBRARY_LOCAL (
    set "AC_LIBRARY_NEEDS_UPDATE=1"
    exit /b 0
)
if /i not "%AC_LIBRARY_LOCAL%"=="%AC_LIBRARY_EXPECTED%" set "AC_LIBRARY_NEEDS_UPDATE=1"
if "%AC_LIBRARY_NEEDS_UPDATE%"=="0" (
    set "AC_LIBRARY_DIRTY="
    for /F "usebackq delims=" %%P in (`git -C "%AC_LIBRARY_PATH%" status --porcelain --untracked-files=all 2^>nul`) do if not defined AC_LIBRARY_DIRTY set "AC_LIBRARY_DIRTY=%%P"
    if defined AC_LIBRARY_DIRTY (
        echo [%ESC%[31mFAILED%ESC%[0m] ac-library has local changes; restore the pinned submodule before continuing.
        exit /b 1
    )
)
exit /b 0

:update_ac_library
if not defined FOUND_GIT_PATH exit /b 1
if not exist "%ROOT%\.gitmodules" exit /b 1
set "INSTALL_CMD=git -C "%ROOT%" submodule update --init --checkout libraries/ac-library"
call :run_install_spinner "ac-library submodule" "" "%TEMP%\cp_setup_git.log"
set "AC_LIBRARY_EXIT=!ERRORLEVEL!"
if not "!AC_LIBRARY_EXIT!"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library submodule update failed.
    echo Log: %TEMP%\cp_setup_git.log
    exit /b 1
)
call :ac_library_needs_update
if errorlevel 1 exit /b 1
if "%AC_LIBRARY_NEEDS_UPDATE%"=="1" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library did not reach the pinned commit after checkout.
    exit /b 1
)
exit /b 0

:check_env_paths
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:ROOT; $esc=[char]27; $cr=[char]13; $clear=$esc+'[2K'; $check='['+$esc+'[38;5;183mCHECKING'+$esc+'[0m]'; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $failed='['+$esc+'[31mFAILED'+$esc+'[0m]'; $job=Start-Job -ScriptBlock { param($root) $normal={ param($value) if ($value) { $value.Trim().TrimEnd('\') } }; $desired=@((Join-Path $root 'scripts').TrimEnd('\')); foreach ($exe in @($env:FOUND_GIT_PATH,$env:FOUND_NVIM_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH)) { if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { $desired += & $normal (Split-Path -Parent $exe) } }; $desired=@($desired | Where-Object { $_ } | Sort-Object -Unique); $key='HKCU:\Software\my-cp-setup'; $path=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $path) { $path='' }; $parts=@($path -split ';' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); $owned=@((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue).'Path.Entries' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); foreach ($entry in $desired) { if ($parts -inotcontains $entry) { return 1 } }; foreach ($entry in $owned) { if ($desired -inotcontains $entry -or $parts -inotcontains $entry) { return 1 } }; return 0 } -ArgumentList $root; $frames=@([char]92,'-','/','|'); $i=0; while ($job.State -eq 'Running') { Write-Host -NoNewline ($cr+$clear+$check+' '+$frames[$i %% $frames.Count]+' Environment paths'); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100; $i++ }; $items=@(Receive-Job -Wait $job); Remove-Job $job -Force; if ($items.Count -eq 0) { $exitCode=1 } else { $exitCode=[int]$items[-1] }; if ($exitCode -eq 0) { Write-Host ($cr+$clear+$found+' Environment paths') } else { Write-Host ($cr+$clear+$failed+' Environment paths') }; exit $exitCode"
exit /b %ERRORLEVEL%

:check_config_integrity
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\'); function SamePath($left,$right) { if (-not $left -or -not $right) { return $false }; return [IO.Path]::GetFullPath($left).TrimEnd('\') -ieq [IO.Path]::GetFullPath($right).TrimEnd('\') }; $key='HKCU:\Software\my-cp-setup'; $state=Get-ItemProperty -Path $key -ErrorAction SilentlyContinue; if ($null -eq $state -or -not (SamePath $state.'Install.Root' $root) -or $state.'Snapshot.Complete' -ne 1 -or $state.SchemaVersion -ne %STATE_SCHEMA% -or $state.'Config.Managed' -ne 1 -or $state.'Config.MutationStarted' -ne 1 -or $state.'Nvim.BootstrapStarted' -ne 1) { exit 1 }; $xdg=[Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME','User'); $configuredRoot=[Environment]::GetEnvironmentVariable('CP_SETUP_ROOT','User'); $python=[Environment]::GetEnvironmentVariable('CP_PYTHON','User'); $gpp=[Environment]::GetEnvironmentVariable('CP_GPP','User'); $javac=[Environment]::GetEnvironmentVariable('CP_JAVAC','User'); $java=[Environment]::GetEnvironmentVariable('CP_JAVA','User'); if (-not (SamePath $xdg $root) -or -not (SamePath $configuredRoot $root) -or -not (SamePath $python $env:CP_PYTHON) -or -not (SamePath $gpp $env:CP_GPP) -or -not (SamePath $javac $env:CP_JAVAC) -or -not (SamePath $java $env:CP_JAVA)) { exit 1 }; $macros=Join-Path $root 'scripts\cp_macros'; $command='doskey /macrofile=\"'+$macros+'\"'; $autorun=(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; if (-not $autorun -or $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -lt 0) { exit 1 }; exit 0"
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
set "WINGET_LIST_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST%" >nul 2>nul
exit /b %WINGET_LIST_EXIT%

:capture_winget_install_result
set "PACKAGE_NOW_PRESENT=0"
call :winget_has_package "%~1"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_NOW_PRESENT=1"
if "%PACKAGE_NOW_PRESENT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget did not register package %~1.
    echo Log: %TEMP%\cp_setup_winget.log
    exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="0" (
    call :record_component "%~2"
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Could not record setup ownership for %~1.
        exit /b 1
    )
)
exit /b 0

:find_msys2_shell
if /i "%~1"=="quiet" goto locate_msys2_shell
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

:locate_msys2_shell
set "MSYS2_SHELL="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@(); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $c += $value } }; foreach ($exe in @($env:CP_GPP,$env:CP_PYTHON,[Environment]::GetEnvironmentVariable('CP_GPP','User'),[Environment]::GetEnvironmentVariable('CP_PYTHON','User'))) { if ($exe) { $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $exe)); $c += Join-Path $root 'msys2_shell.cmd' } }; $c += 'C:\msys64\msys2_shell.cmd'; $w=where.exe msys2_shell.cmd 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p) { $full=[IO.Path]::GetFullPath($p); $bash=Join-Path (Split-Path -Parent $full) 'usr\bin\bash.exe'; if ((Split-Path -Leaf $full) -ieq 'msys2_shell.cmd' -and (Test-Path -LiteralPath $full) -and (Test-Path -LiteralPath $bash)) { Write-Output $full; exit 0 } } }; exit 1"`) do if not defined MSYS2_SHELL set "MSYS2_SHELL=%%P"
if defined MSYS2_SHELL exit /b 0
exit /b 1

:install_msys2_toolchain
call :ensure_msys2
if errorlevel 1 exit /b 1
set "PACMAN_REQUESTED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python"
call :capture_missing_pacman_packages "%PACMAN_REQUESTED%"
if errorlevel 1 exit /b 1
set "PACMAN_COMMAND=pacman -S --needed --noconfirm %PACMAN_REQUESTED%"
call :run_pacman_spinner "INSTALLING" "INSTALLED"
if errorlevel 1 (
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain install failed.
    echo Log: %TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :record_pacman_packages
exit /b %ERRORLEVEL%

:ensure_msys2
call :find_msys2_shell
if errorlevel 1 (
    call :require_winget
    if errorlevel 1 exit /b 1
    set "PACKAGE_PREEXISTED=0"
    call :winget_has_package "MSYS2.MSYS2"
    if errorlevel 2 exit /b 1
    if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
    set "INSTALL_CMD=!WINGET! install --id MSYS2.MSYS2 %WINGET_QUIET_ARGS% --override "install --confirm-command --accept-messages --root C:\msys64""
    call :run_install_spinner "MSYS2 via winget: MSYS2.MSYS2" "" "%TEMP%\cp_setup_winget.log"
    set "INSTALL_EXIT=%ERRORLEVEL%"
    call :capture_winget_install_result "MSYS2.MSYS2" "Winget.MSYS2"
    if errorlevel 1 exit /b 1
    call :find_msys2_shell quiet
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] winget install failed for MSYS2.
        echo Log: %TEMP%\cp_setup_winget.log
        exit /b 1
    )
    if "!PACKAGE_PREEXISTED!"=="0" (
        call :record_component_path "Winget.MSYS2" "!MSYS2_SHELL!"
        if errorlevel 1 exit /b 1
    )
    if "%VERBOSE%"=="1" echo   %MSYS2_SHELL%
)
exit /b 0

:compute_ac_library_tree_hash
set "AC_LIBRARY_TREE_ACTUAL="
set "ACL_HASH_PS=%TEMP%\cp_setup_acl_hash_%RANDOM%_%RANDOM%.ps1"
set "ACL_HASH_OUTPUT=%TEMP%\cp_setup_acl_hash_%RANDOM%_%RANDOM%.txt"
> "%ACL_HASH_PS%" echo param^([string]$Root^)
>> "%ACL_HASH_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ACL_HASH_PS%" echo $rootPath = [IO.Path]::GetFullPath^($Root^).TrimEnd^([char]92^)
>> "%ACL_HASH_PS%" echo $prefix = $rootPath + [char]92
>> "%ACL_HASH_PS%" echo $pathList = New-Object 'System.Collections.Generic.List[string]'
>> "%ACL_HASH_PS%" echo foreach ^($file in Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force^) {
>> "%ACL_HASH_PS%" echo     $relative = $file.FullName.Substring^($prefix.Length^).Replace^([char]92,[char]47^)
>> "%ACL_HASH_PS%" echo     if ^($relative -eq '.git' -or $relative.StartsWith^('.git/',[StringComparison]::Ordinal^)^) { continue }
>> "%ACL_HASH_PS%" echo     $pathList.Add^($relative^) ^| Out-Null
>> "%ACL_HASH_PS%" echo }
>> "%ACL_HASH_PS%" echo $paths = [string[]]$pathList.ToArray^(^)
>> "%ACL_HASH_PS%" echo [Array]::Sort^($paths,[StringComparer]::Ordinal^)
>> "%ACL_HASH_PS%" echo $sha = [Security.Cryptography.SHA256]::Create^(^)
>> "%ACL_HASH_PS%" echo $records = New-Object 'System.Collections.Generic.List[string]'
>> "%ACL_HASH_PS%" echo foreach ^($relative in $paths^) {
>> "%ACL_HASH_PS%" echo     $full = Join-Path $rootPath $relative.Replace^([char]47,[char]92^)
>> "%ACL_HASH_PS%" echo     $bytes = [IO.File]::ReadAllBytes^($full^)
>> "%ACL_HASH_PS%" echo     $fileHash = ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)
>> "%ACL_HASH_PS%" echo     $records.Add^(^('{0}:{1}:{2}:{3}' -f $relative.Length,$relative,$bytes.Length,$fileHash^)^) ^| Out-Null
>> "%ACL_HASH_PS%" echo }
>> "%ACL_HASH_PS%" echo $manifest = [Text.UTF8Encoding]::new^($false^).GetBytes^(^($records -join "`n"^)^)
>> "%ACL_HASH_PS%" echo ^([BitConverter]::ToString^($sha.ComputeHash^($manifest^)^)^).Replace^('-',''^).ToLowerInvariant^(^)
powershell -NoProfile -ExecutionPolicy Bypass -File "%ACL_HASH_PS%" "%~1" > "%ACL_HASH_OUTPUT%"
set "ACL_HASH_EXIT=%ERRORLEVEL%"
if "%ACL_HASH_EXIT%"=="0" for /F "usebackq delims=" %%P in ("%ACL_HASH_OUTPUT%") do if not defined AC_LIBRARY_TREE_ACTUAL set "AC_LIBRARY_TREE_ACTUAL=%%P"
del "%ACL_HASH_PS%" >nul 2>nul
del "%ACL_HASH_OUTPUT%" >nul 2>nul
if not "%ACL_HASH_EXIT%"=="0" exit /b 1
if not defined AC_LIBRARY_TREE_ACTUAL exit /b 1
exit /b 0

:bootstrap_ac_library_archive
set "ACL_BOOTSTRAP_PS=%TEMP%\cp_setup_acl_%RANDOM%_%RANDOM%.ps1"
> "%ACL_BOOTSTRAP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ACL_BOOTSTRAP_PS%" echo $ProgressPreference = 'SilentlyContinue'
>> "%ACL_BOOTSTRAP_PS%" echo $root = $env:ROOT
>> "%ACL_BOOTSTRAP_PS%" echo $commit = $env:ACL_COMMIT
>> "%ACL_BOOTSTRAP_PS%" echo $target = Join-Path $root 'libraries\ac-library'
>> "%ACL_BOOTSTRAP_PS%" echo if ^(Test-Path -LiteralPath $target^) { $items = @^(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop^); if ^($items.Count^) { throw 'libraries\ac-library exists but is not a complete pinned ACL checkout.' } }
>> "%ACL_BOOTSTRAP_PS%" echo $temp = Join-Path $env:TEMP ^('cp_setup_acl_' + [guid]::NewGuid^(^).ToString^('N'^)^)
>> "%ACL_BOOTSTRAP_PS%" echo try {
>> "%ACL_BOOTSTRAP_PS%" echo     New-Item -ItemType Directory -Path $temp -Force ^| Out-Null
>> "%ACL_BOOTSTRAP_PS%" echo     $archive = Join-Path $temp 'acl.zip'
>> "%ACL_BOOTSTRAP_PS%" echo     Invoke-WebRequest -UseBasicParsing -Uri ^('https://github.com/atcoder/ac-library/archive/' + $commit + '.zip'^) -OutFile $archive
>> "%ACL_BOOTSTRAP_PS%" echo     Expand-Archive -LiteralPath $archive -DestinationPath $temp -Force
>> "%ACL_BOOTSTRAP_PS%" echo     $source = Join-Path $temp ^('ac-library-' + $commit^)
>> "%ACL_BOOTSTRAP_PS%" echo     if ^(-not ^(Test-Path -LiteralPath ^(Join-Path $source 'expander.py'^)^)^) { throw 'Pinned ACL archive is incomplete.' }
>> "%ACL_BOOTSTRAP_PS%" echo     if ^(-not ^(Test-Path -LiteralPath $target^)^) { New-Item -ItemType Directory -Path $target -Force ^| Out-Null }
>> "%ACL_BOOTSTRAP_PS%" echo     Get-ChildItem -LiteralPath $source -Force ^| Copy-Item -Destination $target -Recurse -Force
>> "%ACL_BOOTSTRAP_PS%" echo } catch { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue; throw } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
set "INSTALL_CMD=powershell -NoProfile -ExecutionPolicy Bypass -File "%ACL_BOOTSTRAP_PS%""
call :run_install_spinner "ac-library pinned archive" "" "%TEMP%\cp_setup_acl.log"
set "ACL_BOOTSTRAP_EXIT=%ERRORLEVEL%"
del "%ACL_BOOTSTRAP_PS%" >nul 2>nul
if not "%ACL_BOOTSTRAP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library pinned archive bootstrap failed.
    echo Log: %TEMP%\cp_setup_acl.log
    exit /b 1
)
if not exist "%ROOT%\libraries\ac-library\expander.py" exit /b 1
call :compute_ac_library_tree_hash "%ROOT%\libraries\ac-library"
if errorlevel 1 exit /b 1
if /i not "%AC_LIBRARY_TREE_ACTUAL%"=="%ACL_TREE_HASH%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath (Join-Path $env:ROOT 'libraries\ac-library') -Recurse -Force -ErrorAction SilentlyContinue"
    echo [%ESC%[31mFAILED%ESC%[0m] Downloaded ac-library content does not match the pinned tree hash.
    exit /b 1
)
exit /b 0

:capture_missing_pacman_packages
call :find_msys2_shell quiet
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
set "PACMAN_MISSING="
for %%P in (%~1) do (
    "%MSYS2_BASH%" -lc "pacman -Qq %%P ^>/dev/null 2^>^&1"
    if errorlevel 1 set "PACMAN_MISSING=!PACMAN_MISSING! %%P"
)
for /F "tokens=*" %%P in ("%PACMAN_MISSING%") do set "PACMAN_MISSING=%%P"
exit /b 0

:record_pacman_packages
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $allowed=@($env:PACMAN_PACKAGES_ALLOWED -split ' ' | Where-Object { $_ }); $new=@($env:PACMAN_MISSING -split ' ' | Where-Object { $_ }); $existing=@((Get-ItemProperty -Path $key -Name 'Pacman.Packages' -ErrorAction SilentlyContinue).'Pacman.Packages' | Where-Object { $_ }); foreach ($name in @($existing+$new)) { if ($allowed -inotcontains $name) { throw ('Unsafe setup-owned pacman package: '+$name) } }; $owned=@($existing+$new | Sort-Object -Unique); if ($owned.Count) { New-ItemProperty -Path $key -Name 'Pacman.Packages' -PropertyType MultiString -Value ([string[]]$owned) -Force | Out-Null; New-ItemProperty -Path $key -Name 'Pacman.Toolchain' -PropertyType DWord -Value 1 -Force | Out-Null; $shell=$env:MSYS2_SHELL; if ($shell -and (Test-Path -LiteralPath $shell)) { New-ItemProperty -Path $key -Name 'Pacman.Shell.Path' -PropertyType String -Value ([IO.Path]::GetFullPath($shell)) -Force | Out-Null } }"
exit /b %ERRORLEVEL%

:record_partial_pacman_packages
set "PACMAN_INSTALLED_NEW="
for %%P in (%PACMAN_MISSING%) do (
    "%MSYS2_BASH%" -lc "pacman -Qq -- %%P ^>/dev/null 2^>^&1"
    if not errorlevel 1 set "PACMAN_INSTALLED_NEW=!PACMAN_INSTALLED_NEW! %%P"
)
set "PACMAN_MISSING=!PACMAN_INSTALLED_NEW!"
if not defined PACMAN_MISSING exit /b 0
call :record_pacman_packages
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
>> "%SPIN_PS%" echo foreach ($path in @($env:MSYS2_SHELL,'C:\msys64\msys2_shell.cmd')) { if ($path -and (Split-Path -Leaf $path) -ieq 'msys2_shell.cmd' -and (Test-Path -LiteralPath $path)) { $shell = [IO.Path]::GetFullPath($path); break } }
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
if /i not "%~1"=="check" (
    call :capture_user_path
    if errorlevel 1 exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $root=$env:ROOT; $check='%~1' -ieq 'check'; $verbose='%VERBOSE%' -eq '1'; $esc=[char]27; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $normal={ param($value) if ($value) { $value.Trim().TrimEnd('\') } }; $desired=@((Join-Path $root 'scripts').TrimEnd('\')); foreach ($exe in @($env:FOUND_GIT_PATH,$env:FOUND_NVIM_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH)) { if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { $desired += & $normal (Split-Path -Parent $exe) } }; $desired=@($desired | Where-Object { $_ } | Sort-Object -Unique); if ($check) { if ($verbose) { Write-Host ($found+' Environment paths:'); foreach ($p in $desired) { Write-Host ('  '+$p) } }; exit 0 }; $key='HKCU:\Software\my-cp-setup'; $owned=@((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue).'Path.Entries' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); $u=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $u) { $u='' }; $clean=New-Object System.Collections.Generic.List[string]; foreach ($raw in ($u -split ';')) { $normalized=& $normal $raw; if (-not $normalized) { continue }; if ($owned -icontains $normalized -and $desired -inotcontains $normalized) { continue }; if (-not ($clean | Where-Object { $_ -ieq $normalized })) { $clean.Add($normalized) } }; foreach ($p in $desired) { if (-not ($clean | Where-Object { $_ -ieq $p })) { $clean.Add($p) } }; if ($env:FOUND_JAVAC_PATH -and (Test-Path -LiteralPath $env:FOUND_JAVAC_PATH -PathType Leaf)) { $priority=& $normal (Split-Path -Parent $env:FOUND_JAVAC_PATH); for ($i=$clean.Count-1; $i -ge 0; $i--) { if ($clean[$i] -ieq $priority) { $clean.RemoveAt($i) } }; $clean.Insert(0,$priority) }; [Environment]::SetEnvironmentVariable('Path',($clean -join ';'),'User')"
set "INSTALL_PATHS_EXIT=%ERRORLEVEL%"
if /i "%~1"=="check" exit /b %INSTALL_PATHS_EXIT%
call :record_managed_path_entries
if errorlevel 1 exit /b 1
exit /b %INSTALL_PATHS_EXIT%

:capture_user_path
set "PATH_SNAPSHOT=%TEMP%\cp_setup_path_before_%RANDOM%_%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$path=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $path) { $path='' }; Set-Content -LiteralPath $env:PATH_SNAPSHOT -Value $path -NoNewline"
exit /b %ERRORLEVEL%

:record_managed_path_entries
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $snapshot=$env:PATH_SNAPSHOT; try { if (-not (Test-Path -LiteralPath $snapshot)) { exit 1 }; $before=Get-Content -LiteralPath $snapshot -Raw; $after=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $after) { $after='' }; $normal={ param($value) if ($value) { $value.Trim().TrimEnd('\') } }; $targets=@((Join-Path $env:ROOT 'scripts').TrimEnd('\')); foreach ($exe in @($env:FOUND_GIT_PATH,$env:FOUND_NVIM_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH)) { if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { $targets += & $normal (Split-Path -Parent $exe) } }; $targets=@($targets | Where-Object { $_ } | Sort-Object -Unique); $beforeEntries=@($before -split ';' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); $afterEntries=@($after -split ';' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); $key='HKCU:\Software\my-cp-setup'; $previousWritten=(Get-ItemProperty -Path $key -Name 'Path.Written' -ErrorAction SilentlyContinue).'Path.Written'; $existing=@((Get-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue).'Path.Entries' | ForEach-Object { & $normal $_ } | Where-Object { $_ }); $retained=@($existing | Where-Object { $targets -icontains $_ -and $afterEntries -icontains $_ }); $new=@($targets | Where-Object { $afterEntries -icontains $_ -and $beforeEntries -inotcontains $_ }); $owned=@($retained+$new | Sort-Object -Unique); if ($owned.Count) { New-ItemProperty -Path $key -Name 'Path.Entries' -PropertyType MultiString -Value ([string[]]$owned) -Force | Out-Null } else { Remove-ItemProperty -Path $key -Name 'Path.Entries' -ErrorAction SilentlyContinue }; if ($null -eq $previousWritten -or $before -eq $previousWritten) { New-ItemProperty -Path $key -Name 'Path.Written' -PropertyType String -Value $after -Force | Out-Null }; exit 0 } catch { if ($null -ne $before) { [Environment]::SetEnvironmentVariable('Path',$before,'User') }; throw } finally { Remove-Item -LiteralPath $snapshot -Force -ErrorAction SilentlyContinue }"
exit /b %ERRORLEVEL%

:prepare_config_mutation
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $started=(Get-ItemProperty -Path $key -Name 'Config.MutationStarted' -ErrorAction SilentlyContinue).'Config.MutationStarted'; if ($null -eq $started) { foreach ($name in @('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA')) { $value=[Environment]::GetEnvironmentVariable($name,'User'); $had=$null -ne $value; New-ItemProperty -Path $key -Name ('Env.'+$name+'.HadValue') -PropertyType DWord -Value ([int]$had) -Force | Out-Null; if ($had) { New-ItemProperty -Path $key -Name ('Env.'+$name+'.Before') -PropertyType String -Value $value -Force | Out-Null } else { Remove-ItemProperty -Path $key -Name ('Env.'+$name+'.Before') -ErrorAction SilentlyContinue } }; $autoKey='HKCU:\Software\Microsoft\Command Processor'; $autorun=(Get-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; $autoHad=$null -ne $autorun; New-ItemProperty -Path $key -Name 'AutoRun.HadValue' -PropertyType DWord -Value ([int]$autoHad) -Force | Out-Null; if ($autoHad) { New-ItemProperty -Path $key -Name 'AutoRun.Before' -PropertyType String -Value $autorun -Force | Out-Null } else { Remove-ItemProperty -Path $key -Name 'AutoRun.Before' -ErrorAction SilentlyContinue }; Remove-ItemProperty -Path $key -Name 'AutoRun.Written' -ErrorAction SilentlyContinue; New-ItemProperty -Path $key -Name 'Config.MutationStarted' -PropertyType DWord -Value 1 -Force | Out-Null }; $writes=@{ XDG_CONFIG_HOME=$env:ROOT; CP_SETUP_ROOT=$env:ROOT; CP_PYTHON=$env:CP_PYTHON; CP_GPP=$env:CP_GPP; CP_JAVAC=$env:CP_JAVAC; CP_JAVA=$env:CP_JAVA }; foreach ($name in $writes.Keys) { $value=$writes[$name]; if ([string]::IsNullOrWhiteSpace($value)) { throw ('Missing intended environment value: '+$name) }; New-ItemProperty -Path $key -Name ('Env.'+$name+'.Written') -PropertyType String -Value $value -Force | Out-Null }; exit 0"
exit /b %ERRORLEVEL%

:record_autorun_written_state
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $autorun=(Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; $previousWritten=(Get-ItemProperty -Path $key -Name 'AutoRun.Written' -ErrorAction SilentlyContinue).'AutoRun.Written'; if ($null -ne $autorun -and ($null -eq $previousWritten -or $autorun -eq $previousWritten)) { New-ItemProperty -Path $key -Name 'AutoRun.Written' -PropertyType String -Value $autorun -Force | Out-Null }; exit 0"
exit /b %ERRORLEVEL%

:prepare_nvim_bootstrap
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $started=(Get-ItemProperty -Path $key -Name 'Nvim.BootstrapStarted' -ErrorAction SilentlyContinue).'Nvim.BootstrapStarted'; if ($null -eq $started) { $nvimData=Join-Path $env:LOCALAPPDATA 'nvim-data'; New-ItemProperty -Path $key -Name 'NvimData.Existed' -PropertyType DWord -Value ([int](Test-Path -LiteralPath $nvimData)) -Force | Out-Null; $packages=Join-Path $nvimData 'mason\packages'; $before=@(Get-ChildItem -LiteralPath $packages -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name); if ($before.Count) { New-ItemProperty -Path $key -Name 'Mason.Packages.Before' -PropertyType MultiString -Value ([string[]]$before) -Force | Out-Null } else { Remove-ItemProperty -Path $key -Name 'Mason.Packages.Before' -ErrorAction SilentlyContinue }; $root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\'); $sha=[Security.Cryptography.SHA256]::Create(); $rootHash=([BitConverter]::ToString($sha.ComputeHash([Text.UTF8Encoding]::new($false).GetBytes($root)))).Replace('-','').ToLowerInvariant(); $jdtls=Join-Path $nvimData ('jdtls-workspaces\cp-'+$rootHash.Substring(0,16)); New-ItemProperty -Path $key -Name 'JdtlsWorkspace.Path' -PropertyType String -Value ([IO.Path]::GetFullPath($jdtls)) -Force | Out-Null; New-ItemProperty -Path $key -Name 'JdtlsWorkspace.Existed' -PropertyType DWord -Value ([int](Test-Path -LiteralPath $jdtls)) -Force | Out-Null; New-ItemProperty -Path $key -Name 'Nvim.BootstrapStarted' -PropertyType DWord -Value 1 -Force | Out-Null }; exit 0"
exit /b %ERRORLEVEL%

:install_cmd_macros
set "MACROS=%ROOT%\scripts\cp_macros"
if not exist "%MACROS%" (
    echo Macro file not found: %MACROS%
    exit /b 1
)
if not defined CP_PYTHON call :find_python
if not defined CP_PYTHON (
    echo Could not find a usable Python 3.10 or newer executable.
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Environment]::SetEnvironmentVariable('CP_SETUP_ROOT',$env:ROOT,'User'); [Environment]::SetEnvironmentVariable('CP_PYTHON',$env:CP_PYTHON,'User'); [Environment]::SetEnvironmentVariable('CP_JAVAC',$env:CP_JAVAC,'User'); [Environment]::SetEnvironmentVariable('CP_JAVA',$env:CP_JAVA,'User')"
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

:record_component_path
if "%~1"=="" exit /b 0
if "%~2"=="" exit /b 0
reg add "%STATE_KEY%" /v "%~1.Path" /t REG_SZ /d "%~2" /f >nul
exit /b %ERRORLEVEL%

:ensure_ruff
call :find_ruff
if not errorlevel 1 exit /b 0
if "%CHECK_ONLY%"=="1" (
    call :print_missing "Ruff"
    exit /b 0
)
call :ensure_msys2
if errorlevel 1 exit /b 1
set "PACMAN_REQUESTED=mingw-w64-x86_64-ruff"
call :capture_missing_pacman_packages "%PACMAN_REQUESTED%"
if errorlevel 1 exit /b 1
set "PACMAN_COMMAND=pacman -S --needed --noconfirm %PACMAN_REQUESTED%"
call :run_pacman_spinner "INSTALLING" "INSTALLED"
if errorlevel 1 (
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] Ruff install failed.
    echo Log: %TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :record_pacman_packages
if errorlevel 1 exit /b 1
call :find_ruff
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] Ruff was installed, but ruff.exe was not found.
exit /b 1

:find_ruff
set "RUFF_FINDER=%TEMP%\cp_setup_find_ruff_%RANDOM%_%RANDOM%.cmd"
> "%RUFF_FINDER%" echo @echo off
>> "%RUFF_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@(); foreach ($exe in @($env:CP_GPP,$env:CP_PYTHON)) { if ($exe) { $c += Join-Path (Split-Path -Parent $exe) 'ruff.exe' } }; $shells=@($env:MSYS2_SHELL); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $shells += $value } }; foreach ($shell in $shells) { if ($shell) { $c += Join-Path (Split-Path -Parent $shell) 'mingw64\bin\ruff.exe' } }; $c += @('C:\msys64\mingw64\bin\ruff.exe','C:\msys64\ucrt64\bin\ruff.exe'); $w=where.exe ruff 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version > $null 2>&1; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%RUFF_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%RUFF_FINDER%"""
call :search_command "Ruff" "@env" "FOUND_RUFF_PATH"
set "RUFF_FIND_EXIT=!ERRORLEVEL!"
del "%RUFF_FINDER%" >nul 2>nul
exit /b !RUFF_FIND_EXIT!

:refresh_path
for /F "usebackq tokens=* delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
exit /b 0

:find_python
if /i "%~1"=="quiet" goto locate_python
set "PYTHON_FINDER=%TEMP%\cp_setup_find_python_%RANDOM%_%RANDOM%.cmd"
> "%PYTHON_FINDER%" echo @echo off
>> "%PYTHON_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@($env:CP_PYTHON); $shells=@($env:MSYS2_SHELL); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $shells += $value } }; foreach ($shell in $shells) { if ($shell) { $c += Join-Path (Split-Path -Parent $shell) 'mingw64\bin\python.exe' } }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe'); $w=where.exe python 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p -c 'import sys; raise SystemExit(1 if sys.version_info[:2] < (3, 10) else 0)' 2>$null; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
>> "%PYTHON_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call ""%PYTHON_FINDER%"""
call :search_command "Python" "@env" "CP_PYTHON"
set "FIND_EXIT=!ERRORLEVEL!"
del "%PYTHON_FINDER%" >nul 2>nul
exit /b !FIND_EXIT!

:locate_python
set "CP_PYTHON="
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@($env:CP_PYTHON); $shells=@($env:MSYS2_SHELL); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $shells += $value } }; foreach ($shell in $shells) { if ($shell) { $c += Join-Path (Split-Path -Parent $shell) 'mingw64\bin\python.exe' } }; $c += @('C:\msys64\mingw64\bin\python.exe','C:\msys64\ucrt64\bin\python.exe'); $w=where.exe python 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; $py=Get-Command py.exe -ErrorAction SilentlyContinue; if ($py) { $p=& $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null; if ($LASTEXITCODE -eq 0) { $c += $p } }; foreach ($p in $c) { if ($p -and $p -notlike '*\Microsoft\WindowsApps\*' -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p -c 'import sys; raise SystemExit(1 if sys.version_info[:2] < (3, 10) else 0)' 2>$null; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"`) do set "CP_PYTHON=%%P"
if defined CP_PYTHON exit /b 0
exit /b 1

:find_gpp
if /i "%~1"=="quiet" goto locate_gpp
set "GPP_FINDER=%TEMP%\cp_setup_find_gpp_%RANDOM%_%RANDOM%.cmd"
> "%GPP_FINDER%" echo @echo off
>> "%GPP_FINDER%" echo powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@($env:CP_GPP); $shells=@($env:MSYS2_SHELL); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $shells += $value } }; foreach ($shell in $shells) { if ($shell) { $c += Join-Path (Split-Path -Parent $shell) 'mingw64\bin\g++.exe' } }; $c += @('C:\msys64\mingw64\bin\g++.exe','C:\msys64\ucrt64\bin\g++.exe'); $w=where.exe g++ 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"
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
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$key='HKCU:\Software\my-cp-setup'; $c=@($env:CP_GPP); $shells=@($env:MSYS2_SHELL); foreach ($name in @('Pacman.Shell.Path','Winget.MSYS2.Path')) { $value=(Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue).$name; if ($value) { $shells += $value } }; foreach ($shell in $shells) { if ($shell) { $c += Join-Path (Split-Path -Parent $shell) 'mingw64\bin\g++.exe' } }; $c += @('C:\msys64\mingw64\bin\g++.exe','C:\msys64\ucrt64\bin\g++.exe'); $w=where.exe g++ 2>$null; if ($LASTEXITCODE -eq 0) { $c += $w }; foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { & $p --version *> $null; if ($LASTEXITCODE -eq 0) { Write-Output ([IO.Path]::GetFullPath($p)); exit 0 } } }; exit 1"`) do set "CP_GPP=%%P"
if defined CP_GPP (
    for %%I in ("%CP_GPP%") do set "PATH=%%~dpI;%PATH%"
    exit /b 0
)
exit /b 1

:check_mason_tools
set "MASON_BIN=%LOCALAPPDATA%\nvim-data\mason\bin"
call :check_mason_binary "Pyright" "pyright.cmd" "--version"
call :check_mason_binary "JDT LS" "jdtls.cmd" ""
call :check_mason_binary "Google Java Format" "google-java-format.cmd" "--version"
call :check_mason_binary "clangd" "clangd.cmd" "--version"
exit /b 0

:check_mason_binary
if not exist "%MASON_BIN%\%~2" (
    call :print_missing "Mason %~1"
    exit /b 0
)
if "%~3"=="" (
    if /i "%~2"=="jdtls.cmd" (
        if not exist "%MASON_BIN%\..\packages\jdtls\plugins\org.eclipse.equinox.launcher_*.jar" (
            call :print_missing "Mason %~1 executable"
            exit /b 0
        )
        if not exist "%MASON_BIN%\..\packages\jdtls\config_win" (
            call :print_missing "Mason %~1 executable"
            exit /b 0
        )
    )
    call :print_found "Mason %~1"
    exit /b 0
)
"%ComSpec%" /d /s /c ""%MASON_BIN%\%~2" %~3" >nul 2>nul
if errorlevel 1 (
    call :print_missing "Mason %~1 executable"
) else (
    call :print_found "Mason %~1"
)
exit /b 0

:bootstrap_nvim_tools
call :capture_missing_mason_packages
if errorlevel 1 exit /b 1
set "INSTALL_CMD="%FOUND_NVIM_PATH%" --headless "+Lazy! restore" +qa"
call :run_install_spinner "LazyVim plugins" "this may take a while" "%TEMP%\cp_setup_nvim.log"
set "LAZY_BOOTSTRAP_EXIT=%ERRORLEVEL%"
if not "%LAZY_BOOTSTRAP_EXIT%"=="0" (
    call :record_mason_packages
    echo [%ESC%[31mFAILED%ESC%[0m] LazyVim plugin bootstrap failed.
    echo Log: %TEMP%\cp_setup_nvim.log
    exit /b 1
)
set "MASON_BOOTSTRAP_LUA=%TEMP%\cp_setup_mason_%RANDOM%_%RANDOM%.lua"
> "%MASON_BOOTSTRAP_LUA%" echo local names = { "pyright", "jdtls", "google-java-format", "clangd" }
>> "%MASON_BOOTSTRAP_LUA%" echo local registry = require("mason-registry")
>> "%MASON_BOOTSTRAP_LUA%" echo local refreshed = false
>> "%MASON_BOOTSTRAP_LUA%" echo registry.refresh(function()
>> "%MASON_BOOTSTRAP_LUA%" echo   for _, name in ipairs(names) do
>> "%MASON_BOOTSTRAP_LUA%" echo     local package = registry.get_package(name)
>> "%MASON_BOOTSTRAP_LUA%" echo     if not package:is_installed() then package:install() end
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   refreshed = true
>> "%MASON_BOOTSTRAP_LUA%" echo end)
>> "%MASON_BOOTSTRAP_LUA%" echo local complete = vim.wait(300000, function()
>> "%MASON_BOOTSTRAP_LUA%" echo   if not refreshed then return false end
>> "%MASON_BOOTSTRAP_LUA%" echo   for _, name in ipairs(names) do if not registry.get_package(name):is_installed() then return false end end
>> "%MASON_BOOTSTRAP_LUA%" echo   return true
>> "%MASON_BOOTSTRAP_LUA%" echo end, 200)
>> "%MASON_BOOTSTRAP_LUA%" echo if not complete then vim.api.nvim_err_writeln("Timed out installing required Mason tools") vim.cmd("cquit") end
>> "%MASON_BOOTSTRAP_LUA%" echo vim.cmd("qa^!")
set "INSTALL_CMD="%FOUND_NVIM_PATH%" --headless -c "lua dofile([[!MASON_BOOTSTRAP_LUA!]])""
call :run_install_spinner "Neovim language tools" "this may take a while" "%TEMP%\cp_setup_mason.log"
set "MASON_BOOTSTRAP_EXIT=%ERRORLEVEL%"
del "%MASON_BOOTSTRAP_LUA%" >nul 2>nul
call :record_mason_packages
set "MASON_RECORD_EXIT=%ERRORLEVEL%"
if not "%MASON_BOOTSTRAP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Mason tool bootstrap failed.
    echo Log: %TEMP%\cp_setup_mason.log
    exit /b 1
)
if not "%MASON_RECORD_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not record setup-owned Mason packages.
    exit /b 1
)
exit /b 0

:capture_missing_mason_packages
set "MASON_MISSING="
for %%T in (%MASON_TOOLS%) do if not exist "%LOCALAPPDATA%\nvim-data\mason\packages\%%T" set "MASON_MISSING=!MASON_MISSING! %%T"
exit /b 0

:record_mason_packages
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key='HKCU:\Software\my-cp-setup'; $dir=Join-Path $env:LOCALAPPDATA 'nvim-data\mason\packages'; $allowed=@($env:MASON_TOOLS -split ' ' | Where-Object { $_ }); $existing=@((Get-ItemProperty -Path $key -Name 'Mason.Packages' -ErrorAction SilentlyContinue).'Mason.Packages' | Where-Object { $_ }); foreach ($name in $existing) { if ($allowed -inotcontains $name) { throw ('Unsafe setup-owned Mason package: '+$name) } }; $missing=@($env:MASON_MISSING -split ' ' | Where-Object { $_ -and $allowed -icontains $_ }); $new=@($missing | Where-Object { Test-Path -LiteralPath (Join-Path $dir $_) }); $owned=@($existing+$new | Sort-Object -Unique); if ($owned.Count) { New-ItemProperty -Path $key -Name 'Mason.Packages' -PropertyType MultiString -Value ([string[]]$owned) -Force | Out-Null }"
exit /b %ERRORLEVEL%

:verify_mason_tools
set "MASON_BIN=%LOCALAPPDATA%\nvim-data\mason\bin"
for %%T in (pyright.cmd jdtls.cmd google-java-format.cmd clangd.cmd) do if not exist "%MASON_BIN%\%%T" exit /b 1
"%ComSpec%" /d /s /c ""%MASON_BIN%\pyright.cmd" --version" >nul 2>nul
if errorlevel 1 exit /b 1
"%ComSpec%" /d /s /c ""%MASON_BIN%\google-java-format.cmd" --version" >nul 2>nul
if errorlevel 1 exit /b 1
"%ComSpec%" /d /s /c ""%MASON_BIN%\clangd.cmd" --version" >nul 2>nul
if errorlevel 1 exit /b 1
if not exist "%MASON_BIN%\..\packages\jdtls\plugins\org.eclipse.equinox.launcher_*.jar" exit /b 1
if not exist "%MASON_BIN%\..\packages\jdtls\config_win" exit /b 1
"%FOUND_NVIM_PATH%" --headless -c "lua for _,tool in ipairs({'pyright-langserver','jdtls','google-java-format','clangd'}) do assert(vim.fn.executable(tool)==1, tool..' is not executable') end" +qa >nul 2>nul
exit /b %ERRORLEVEL%

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
if not defined FOUND_RUFF_PATH (
    echo [%ESC%[31mFAILED%ESC%[0m] Ruff is not visible during verification.
    exit /b 1
)
echo. | "%FOUND_RUFF_PATH%" check --no-cache --force-exclude --quiet --select E9 --stdin-filename "%ROOT%\template\python\solve.py" --no-fix --output-format json - >nul 2>nul
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Ruff does not support the syntax-check command required by Neovim.
    exit /b 1
)
if not defined FOUND_JAVAC_PATH (
    echo [%ESC%[31mFAILED%ESC%[0m] javac is not visible during verification.
    exit /b 1
)
if not defined FOUND_JAVA_PATH (
    echo [%ESC%[31mFAILED%ESC%[0m] java is not visible during verification.
    exit /b 1
)
call :verify_mason_tools
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Required Mason tools are not usable.
    exit /b 1
)
call :ensure_spinner
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not create verification spinner.
    exit /b 1
)
for /F "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "Join-Path $env:TEMP ('cp_setup_verify_' + [guid]::NewGuid().ToString('N'))"`) do set "VERIFY_DIR=%%P"
mkdir "%VERIFY_DIR%" >nul 2>nul
mkdir "%VERIFY_DIR%\classes" >nul 2>nul
copy /y "%ROOT%\template\cpp\solve.cpp" "%VERIFY_DIR%\solve.cpp" >nul
if errorlevel 1 goto verify_failed
copy /y "%ROOT%\template\java\solve.java" "%VERIFY_DIR%\solve.java" >nul
if errorlevel 1 goto verify_failed
copy /y "%ROOT%\template\python\solve.py" "%VERIFY_DIR%\solve.py" >nul
if errorlevel 1 goto verify_failed

if "%CHECK_ONLY%"=="0" (
    "%CP_PYTHON%" "%SPINNER_PY%" --label "Run C++ template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%VERIFY_DIR%\solve.cpp"
    if errorlevel 1 goto verify_failed
    "%CP_PYTHON%" "%SPINNER_PY%" --label "Run Java template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%VERIFY_DIR%\solve.java"
    if errorlevel 1 goto verify_failed
    "%CP_PYTHON%" "%SPINNER_PY%" --label "Run Python template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\run.py" "%VERIFY_DIR%\solve.py"
    if errorlevel 1 goto verify_failed
)
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand C++ template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" --no-clipboard "%VERIFY_DIR%\solve.cpp"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand Java template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" --no-clipboard "%VERIFY_DIR%\solve.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Expand Python template" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" "%ROOT%\scripts\expand.py" --no-clipboard "%VERIFY_DIR%\solve.py"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded C++" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_GPP%" -std=c++20 -O2 "%VERIFY_DIR%\submit.cpp" -o "%VERIFY_DIR%\submit_test.exe"
if errorlevel 1 goto verify_failed
copy /y "%VERIFY_DIR%\submit.java" "%VERIFY_DIR%\Main.java" >nul
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Compile expanded Java" --cwd "%VERIFY_DIR%" --stdin-empty -- "%FOUND_JAVAC_PATH%" -encoding UTF-8 -d "%VERIFY_DIR%\classes" "%VERIFY_DIR%\Main.java"
if errorlevel 1 goto verify_failed
"%CP_PYTHON%" "%SPINNER_PY%" --label "Parse expanded Python" --cwd "%VERIFY_DIR%" --stdin-empty -- "%CP_PYTHON%" -c "import ast, pathlib; ast.parse(pathlib.Path(r'%VERIFY_DIR%\submit.py').read_text(encoding='utf-8'))"
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
if defined SPINNER_PY del "%SPINNER_PY%" >nul 2>nul
if defined VERIFY_DIR (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$target=[IO.Path]::GetFullPath($env:VERIFY_DIR); $temp=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\'; if (-not $target.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $target) -notlike 'cp_setup_verify_*') { exit 1 }; Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop"
    if errorlevel 1 exit /b 1
)
exit /b 0

:failed
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup install did not complete.
exit /b 1
