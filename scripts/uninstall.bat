@echo off
if defined CP_UNINSTALL_ENTRY_ACTIVE goto cp_uninstall_entry_active
set "CP_UNINSTALL_ENTRY_ACTIVE=1"
call "%~f0" %*
set "CP_UNINSTALL_ENTRY_EXIT=%ERRORLEVEL%"
set "CP_UNINSTALL_ENTRY_ACTIVE="
exit /b %CP_UNINSTALL_ENTRY_EXIT%

:cp_uninstall_entry_active
setlocal EnableExtensions DisableDelayedExpansion

set "__APPDIR__="
set "SYSTEM32=%__APPDIR__%"
if "%SYSTEM32:~-1%"=="\" set "SYSTEM32=%SYSTEM32:~0,-1%"
for %%I in ("%SYSTEM32%\..") do set "TRUSTED_SYSTEMROOT=%%~fI"
for %%I in ("%SYSTEM32%") do set "SYSTEM32_LEAF=%%~nxI"
if /i "%SYSTEM32_LEAF%"=="SysWOW64" goto reexec_native_cmd
if /i not "%SYSTEM32_LEAF%"=="System32" exit /b 1
goto native_cmd_ready

:reexec_native_cmd
if "%CP_UNINSTALL_NATIVE_REEXEC%"=="1" exit /b 1
set "CP_UNINSTALL_NATIVE_REEXEC=1"
if not exist "%TRUSTED_SYSTEMROOT%\Sysnative\cmd.exe" exit /b 1
"%TRUSTED_SYSTEMROOT%\Sysnative\cmd.exe" /d /s /c ""%~f0" %*"
exit /b %ERRORLEVEL%

:native_cmd_ready
set "SystemRoot=%TRUSTED_SYSTEMROOT%"
set "windir=%TRUSTED_SYSTEMROOT%"
set "SystemDrive=%TRUSTED_SYSTEMROOT:~0,2%"
set "CMD_EXE=%SYSTEM32%\cmd.exe"
set "POWERSHELL_EXE=%SYSTEM32%\WindowsPowerShell\v1.0\powershell.exe"
set "REG_EXE=%SYSTEM32%\reg.exe"
set "WHERE_EXE=%SYSTEM32%\where.exe"
set "FINDSTR_EXE=%SYSTEM32%\findstr.exe"
set "ICACLS_EXE=%SYSTEM32%\icacls.exe"
set "ComSpec=%CMD_EXE%"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%SYSTEM32%;%TRUSTED_SYSTEMROOT%;%SYSTEM32%\Wbem;%SYSTEM32%\WindowsPowerShell\v1.0"
set "PSModulePath=%SYSTEM32%\WindowsPowerShell\v1.0\Modules"
set "__COMPAT_LAYER="
for %%V in (COR_ENABLE_PROFILING COR_PROFILER COR_PROFILER_PATH COR_PROFILER_PATH_32 COR_PROFILER_PATH_64 CORECLR_ENABLE_PROFILING CORECLR_PROFILER CORECLR_PROFILER_PATH CORECLR_PROFILER_PATH_32 CORECLR_PROFILER_PATH_64 DOTNET_STARTUP_HOOKS DOTNET_ADDITIONAL_DEPS DOTNET_SHARED_STORE DOTNET_ROOT COMPLUS_InstallRoot COMPLUS_Version BASH_ENV ENV SHELLOPTS BASHOPTS PYTHONHOME PYTHONPATH NODE_OPTIONS NODE_PATH JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS JDK_JAVAC_OPTIONS _JAVA_OPTIONS CLASSPATH GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT RUBYOPT PERL5OPT __COMPAT_LAYER) do set "%%V="
set "DOTNET_ROOT(x86)="

set "ESC="
if defined CP_SETUP_ORIGINAL_ROOT (
    set "ROOT=%CP_SETUP_ORIGINAL_ROOT%"
) else (
    for %%I in ("%~dp0..") do set "ROOT=%%~fI"
)
set "UNINSTALL_SCRIPT=%~f0"
set "ORIGINAL_ARGS=%*"

set "CHECK_ONLY=0"
set "ALL_MODE=0"
set "NON_INTERACTIVE=0"
set "NO_PAUSE=0"
set "KEEP_REPO=0"
set "UNINSTALL_LOG_REQUESTED="
set "ELEVATED_UNINSTALL_ARGS="
set "CAN_REMOVE_REPO=1"
set "CONFIG_REMOVED=0"
set "REMOVE_REPO=0"
set "STATE_SCHEMA=5"
set "MASON_TOOLS=pyright jdtls google-java-format clangd"
set "PACMAN_PACKAGES_ALLOWED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff"
set "UNINSTALL_COMMAND_TIMEOUT_SECONDS=1800"
set "UNINSTALL_SEARCH_TIMEOUT_SECONDS=120"
set "UNINSTALL_UAC_TIMEOUT_SECONDS=300"
set "UNINSTALL_CHILD_TIMEOUT_SECONDS=7200"
set "UNINSTALL_MEDIUM_TIMEOUT_SECONDS=1800"
set "UNINSTALL_TIMEOUT_SEEN=0"
set "CP_RUNTIME_SECURE=0"
set "MEDIUM_LAUNCHER_PS="
set "MEDIUM_NATIVE_CS="
set "PROCESS_TREE_NATIVE_CS="
set "PROCESS_TREE_PS="
set "EARLY_ELEVATED=0"
set "DIRECT_ELEVATED_PARENT=0"

cd /d "%SYSTEM32%"
if errorlevel 1 exit /b 1
call :validate_system_tools
if errorlevel 1 exit /b 1
call :enable_ansi
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent();if(([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 0};exit 1" >nul 2>nul
if not errorlevel 1 set "EARLY_ELEVATED=1"
if "%EARLY_ELEVATED%"=="1" if not "%CP_SETUP_ELEVATED_CHILD%"=="1" (
    set "DIRECT_ELEVATED_PARENT=1"
    call :initialize_direct_elevated_context
    if errorlevel 1 exit /b 1
) else if "%EARLY_ELEVATED%"=="1" (
    if not "%CP_SETUP_ELEVATED_CHILD%"=="1" set "CP_SETUP_TARGET_SID="
    if not defined CP_SETUP_TARGET_SID for /F "usebackq delims=" %%S in (`"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value"`) do if not defined CP_SETUP_TARGET_SID set "CP_SETUP_TARGET_SID=%%S"
    "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "if($env:CP_SETUP_TARGET_SID -notmatch '^S-1-(?:[0-9]+-)+[0-9]+$'){exit 1};exit 0" >nul 2>nul
    if errorlevel 1 exit /b 1
    call :initialize_secure_runtime
    if errorlevel 1 exit /b 1
    set "TEMP=%CP_RUNTIME_TEMP%"
    set "TMP=%CP_RUNTIME_TEMP%"
)
if "%DIRECT_ELEVATED_PARENT%"=="0" (
    call :initialize_target_context
    if errorlevel 1 exit /b 1
    call :initialize_visible_temp
    if errorlevel 1 exit /b 1
)
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
if /i "%~1"=="--non-interactive" (
    if "%CHECK_ONLY%"=="1" goto incompatible_args
    set "NON_INTERACTIVE=1"
    set "NO_PAUSE=1"
    set "KEEP_REPO=1"
    set "ALL_MODE=1"
    shift
    goto parse_args
)
if /i "%~1"=="--no-pause" (
    set "NO_PAUSE=1"
    shift
    goto parse_args
)
if /i "%~1"=="--log" (
    if "%~2"=="" (
        echo [%ESC%[31mFAILED%ESC%[0m] --log requires a file path.
        exit /b 1
    )
    set "UNINSTALL_LOG_REQUESTED=%~2"
    shift
    shift
    goto parse_args
)
echo [%ESC%[31mFAILED%ESC%[0m] Unknown argument: %~1
exit /b 1

:incompatible_args
echo [%ESC%[31mFAILED%ESC%[0m] Use either --check or --all, not both.
exit /b 1

:parsed_args
set "ELEVATED_UNINSTALL_ARGS="
if "%CHECK_ONLY%"=="1" (
    set "ELEVATED_UNINSTALL_ARGS=--check"
) else if "%NON_INTERACTIVE%"=="1" (
    set "ELEVATED_UNINSTALL_ARGS=--non-interactive"
) else if "%ALL_MODE%"=="1" (
    set "ELEVATED_UNINSTALL_ARGS=--all"
)
set "ELEVATED_UNINSTALL_ARGS=!ELEVATED_UNINSTALL_ARGS! --no-pause"
for /F "tokens=*" %%A in ("!ELEVATED_UNINSTALL_ARGS!") do set "ELEVATED_UNINSTALL_ARGS=%%A"
if /I "%CP_SETUP_STATE_CONTEXT%"=="ABSENT" if "%CP_SETUP_LEGACY_STATE%"=="1" (
    echo [%ESC%[31mFAILED%ESC%[0m] Legacy per-user setup ownership state was found without protected machine state.
    echo Reinstall this version of CP setup before uninstalling so ownership can be verified safely.
    exit /b 1
)
set "NEED_ELEVATION=0"
if "%CHECK_ONLY%"=="0" set "NEED_ELEVATION=1"
if "%DIRECT_ELEVATED_PARENT%"=="1" set "NEED_ELEVATION=1"
if "%NEED_ELEVATION%"=="1" (
    cd /d "%SYSTEM32%"
    if errorlevel 1 exit /b 1
    call :ensure_admin
    set "ADMIN_EXIT=!ERRORLEVEL!"
    if "!ADMIN_EXIT!"=="2" (
        call :cleanup_secure_runtime >nul 2>nul
        exit /b 0
    )
    if not "!ADMIN_EXIT!"=="0" exit /b !ADMIN_EXIT!
    call :initialize_secure_runtime
    if errorlevel 1 goto failed
    cd /d "%CP_RUNTIME_TEMP%"
    if errorlevel 1 goto failed
    call :sanitize_elevated_environment
    if errorlevel 1 goto failed
    call :prepare_native_helpers
    if errorlevel 1 goto failed
)
call :check_state_root
if errorlevel 1 (
    if "%CHECK_ONLY%"=="1" exit /b 1
    goto failed
)
call :enable_ansi "%CHECK_ONLY%"
call :refresh_path

echo CP setup root:
echo %ROOT%
echo.

if "%CHECK_ONLY%"=="1" (
    call :prepare_process_tree_helpers
    if errorlevel 1 (
        if "%CP_RUNTIME_SECURE%"=="1" call :cleanup_secure_runtime >nul 2>nul
        exit /b 1
    )
    call :check_state
    set "CHECK_EXIT=!ERRORLEVEL!"
    call :cleanup_process_tree_helpers
    if errorlevel 1 set "CHECK_EXIT=1"
    if "%CP_RUNTIME_SECURE%"=="1" (
        call :cleanup_secure_runtime
        if errorlevel 1 set "CHECK_EXIT=1"
    )
    exit /b !CHECK_EXIT!
)

call :stop_setup_active_operation
if errorlevel 1 goto failed
call :recover_pending_acl
if errorlevel 1 goto failed
call :recover_pending_registry
if errorlevel 1 goto failed
call :recover_pending_mason
if errorlevel 1 goto failed
call :recover_pending_components
if errorlevel 1 goto failed
call :recover_pending_artifacts
if errorlevel 1 goto failed

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
call :clear_empty_state
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
set "CONFIG_REMOVED=1"
if "%CONFIG_STATUS_ABOVE%"=="1" goto decide_repo_removal
echo.

:decide_repo_removal
if not "%CAN_REMOVE_REPO%"=="1" goto repo_kept
if "%KEEP_REPO%"=="1" goto repo_kept_by_choice

echo.
call :ask_yes_no "Remove this CP setup folder too"
if errorlevel 1 goto repo_kept_by_choice
echo [%ESC%[38;5;153mREMOVING%ESC%[0m] CP setup folder after the uninstaller closes.
    call :assert_state_absent
    if errorlevel 1 goto failed
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
if "%REMOVE_REPO%"=="1" if "%CP_ELEVATION_PARENT%"=="1" (
    call :print_completion > "%CP_DEFER_COMPLETION_FILE%"
    >> "%CP_DEFER_COMPLETION_FILE%" echo Restart terminals so environment changes are visible everywhere.
) else (
    call :print_completion
    echo Restart terminals so environment changes are visible everywhere.
)
call :wait_to_finish
if "%REMOVE_REPO%"=="0" (
    call :cleanup_secure_runtime
    if errorlevel 1 goto failed
    exit /b 0
)
call :schedule_repo_removal
if errorlevel 1 (
    call :cleanup_secure_runtime
    goto failed
)
if not "%KEEP_RUNTIME_FOR_DELETE%"=="1" (
    call :cleanup_secure_runtime
    if errorlevel 1 goto failed
)
if "%ELEVATED_REMOVE_REQUEST%"=="1" exit /b 10
exit /b 0

:configuration_failed
goto failed

:validate_system_tools
if not exist "%CMD_EXE%" goto system_tools_failed
if not exist "%POWERSHELL_EXE%" goto system_tools_failed
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $system=[IO.Path]::GetFullPath($env:SYSTEM32).TrimEnd('\'); $actual=[IO.Path]::GetFullPath([Environment]::SystemDirectory).TrimEnd('\'); if ($system -ine $actual) { exit 1 }; $trusted=@('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $untrusted=@('S-1-1-0','S-1-5-11','S-1-5-32-545'); $mask=[Security.AccessControl.FileSystemRights]::WriteData -bor [Security.AccessControl.FileSystemRights]::AppendData -bor [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor [Security.AccessControl.FileSystemRights]::WriteAttributes -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership; foreach ($path in @($env:TRUSTED_SYSTEMROOT,$system,(Split-Path -Parent $env:POWERSHELL_EXE),$env:CMD_EXE,$env:POWERSHELL_EXE)) { $full=[IO.Path]::GetFullPath($path); $item=Get-Item -LiteralPath $full -Force -ErrorAction Stop; if ([bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 }; $acl=Get-Acl -LiteralPath $full; try { $ownerSid=([Security.Principal.NTAccount]$acl.Owner).Translate([Security.Principal.SecurityIdentifier]).Value } catch { $ownerSid=$acl.Owner }; if ($trusted -notcontains $ownerSid) { exit 1 }; foreach ($ace in $acl.Access) { if ($ace.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or -not ([int64]$ace.FileSystemRights -band [int64]$mask)) { continue }; try { $sid=$ace.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { $sid=[string]$ace.IdentityReference }; if ($untrusted -contains $sid) { exit 1 } } }; foreach ($exe in @($env:CMD_EXE,$env:POWERSHELL_EXE)) { $signature=Get-AuthenticodeSignature -LiteralPath $exe; if ($signature.Status -ne [Management.Automation.SignatureStatus]::Valid -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch 'Microsoft') { exit 1 } }; exit 0 } catch { exit 1 }" >nul 2>nul
if not errorlevel 1 exit /b 0
:system_tools_failed
echo [%ESC%[31mFAILED%ESC%[0m] Protected Windows system tools could not be verified.
exit /b 1

:initialize_target_context
set "TARGET_CONTEXT_TEMP=%TEMP%"
if "%CP_RUNTIME_SECURE%"=="1" set "TARGET_CONTEXT_TEMP=%CP_RUNTIME_TEMP%"
set "TARGET_CONTEXT_ELEVATED=0"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1" >nul 2>nul
if not errorlevel 1 set "TARGET_CONTEXT_ELEVATED=1"
if "%TARGET_CONTEXT_ELEVATED%"=="0" set "CP_SETUP_TARGET_SID="
if not "%CP_SETUP_ELEVATED_CHILD%"=="1" (
    set "CP_SETUP_TARGET_SID="
    set "CP_ELEVATION_PARENT="
)
set "TARGET_SID_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_sid_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value" > "%TARGET_SID_FILE%" 2>nul
for /F "usebackq delims=" %%S in ("%TARGET_SID_FILE%") do if not defined CP_SETUP_TARGET_SID set "CP_SETUP_TARGET_SID=%%S"
del "%TARGET_SID_FILE%" >nul 2>nul
set "TARGET_SID_FILE="
if not defined CP_SETUP_TARGET_SID goto target_context_failed
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "if ($env:CP_SETUP_TARGET_SID -notmatch '^S-1-(?:[0-9]+-)+[0-9]+$') { exit 1 }; if (-not (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $env:CP_SETUP_TARGET_SID))) { exit 1 }; exit 0" >nul 2>nul
if errorlevel 1 goto target_context_failed
set "TARGET_HIVE=HKU\%CP_SETUP_TARGET_SID%"
set "STATE_KEY=HKLM\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_REGISTRY=Registry::HKEY_USERS\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_STATE=Registry::HKEY_LOCAL_MACHINE\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_STATE_RELATIVE=Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_ENV=%CP_SETUP_TARGET_REGISTRY%\Environment"
set "CP_SETUP_TARGET_PROFILE="
set "CP_SETUP_TARGET_LOCALAPPDATA="
set "CP_SETUP_TARGET_APPDATA="
set "CP_SETUP_PROTECTED_NVIMDATA="
set "CP_SETUP_STATE_CONTEXT=ABSENT"
set "CP_SETUP_LEGACY_STATE=0"
goto initialize_target_context_safe

:initialize_target_context_safe
set "TARGET_INFO_PS=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_target_%RANDOM%_%RANDOM%.ps1"
set "TARGET_PROFILE_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_profile_%RANDOM%_%RANDOM%.txt"
set "TARGET_LOCAL_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_local_%RANDOM%_%RANDOM%.txt"
set "TARGET_APP_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_app_%RANDOM%_%RANDOM%.txt"
set "TARGET_NVIM_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_nvim_%RANDOM%_%RANDOM%.txt"
set "TARGET_STATE_FILE=%TARGET_CONTEXT_TEMP%\cp_setup_uninstall_state_%RANDOM%_%RANDOM%.txt"
> "%TARGET_INFO_PS%" echo $ErrorActionPreference='Stop'
>> "%TARGET_INFO_PS%" echo try {
>> "%TARGET_INFO_PS%" echo   $sid=$env:CP_SETUP_TARGET_SID; $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%TARGET_INFO_PS%" echo   $profileKey=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\'+$sid,$false^)
>> "%TARGET_INFO_PS%" echo   if ^(-not $profileKey^) { throw 'Profile metadata is missing.' }; try { $profile=[IO.Path]::GetFullPath^([Environment]::ExpandEnvironmentVariables^([string]$profileKey.GetValue^('ProfileImagePath',$null,$option^)^)^).TrimEnd^('\'^); } finally { $profileKey.Dispose^(^) }
>> "%TARGET_INFO_PS%" echo   $shell=[Microsoft.Win32.Registry]::Users.OpenSubKey^($sid+'\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders',$false^); $local=$null; $app=$null
>> "%TARGET_INFO_PS%" echo   if ^($shell^) { try { $local=$shell.GetValue^('Local AppData',$null,$option^); $app=$shell.GetValue^('AppData',$null,$option^) } finally { $shell.Dispose^(^) } }
>> "%TARGET_INFO_PS%" echo   if ^(-not $local^) { $local=Join-Path $profile 'AppData\Local' }; if ^(-not $app^) { $app=Join-Path $profile 'AppData\Roaming' }
>> "%TARGET_INFO_PS%" echo   $local=[IO.Path]::GetFullPath^([Environment]::ExpandEnvironmentVariables^([string]$local^)^).TrimEnd^('\'^); $app=[IO.Path]::GetFullPath^([Environment]::ExpandEnvironmentVariables^([string]$app^)^).TrimEnd^('\'^)
>> "%TARGET_INFO_PS%" echo   foreach ^($p in @^($profile,$local,$app^)^) { if ^($p -notmatch '^^[A-Za-z]:\\'^) { throw 'Profile path is invalid.' } }
>> "%TARGET_INFO_PS%" echo   $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); $status='ABSENT'; $nvim=''
>> "%TARGET_INFO_PS%" echo   if ^($state^) { try {
>> "%TARGET_INFO_PS%" echo     $names=@^($state.GetValueNames^(^)^); foreach ^($n in @^('Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root','SchemaVersion'^)^) { if ^($names -notcontains $n^) { throw ^('Missing protected state value: '+$n^) } }
>> "%TARGET_INFO_PS%" echo     foreach ^($n in @^('Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root'^)^) { if ^($state.GetValueKind^($n^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw ^('Invalid protected state kind: '+$n^) } }; if ^($state.GetValueKind^('SchemaVersion'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('SchemaVersion',0,$option^) -ne [int]$env:STATE_SCHEMA^) { throw 'Protected state schema is invalid.' }
>> "%TARGET_INFO_PS%" echo     if ^([string]$state.GetValue^('Target.Sid',$null,$option^) -cne $sid^) { throw 'Target SID mismatch.' }; $storedProfile=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.Profile',$null,$option^)^).TrimEnd^('\'^); $storedLocal=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.LocalAppData',$null,$option^)^).TrimEnd^('\'^); $storedApp=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.AppData',$null,$option^)^).TrimEnd^('\'^); $nvim=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root',$null,$option^)^).TrimEnd^('\'^)
>> "%TARGET_INFO_PS%" echo     if ^($storedProfile -ine $profile -or $storedLocal -ine $local -or $storedApp -ine $app -or -not $storedLocal.StartsWith^($storedProfile+'\',[StringComparison]::OrdinalIgnoreCase^) -or -not $storedApp.StartsWith^($storedProfile+'\',[StringComparison]::OrdinalIgnoreCase^) -or $nvim -ine ^(Join-Path $storedLocal 'nvim-data'^)^) { throw 'Protected target metadata does not match the invoking user.' }
>> "%TARGET_INFO_PS%" echo     if ^($names -contains 'Install.Root'^) { if ^($state.GetValueKind^('Install.Root'^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Invalid protected install root kind.' }; $null=[IO.Path]::GetFullPath^([string]$state.GetValue^('Install.Root',$null,$option^)^); $status='FOUND' } else {
>> "%TARGET_INFO_PS%" echo       $allowed=@^('SchemaVersion','Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root','Snapshot.Complete','Path.HadValue','Path.Before','Path.Before.Kind','AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','NvimData.Existed','Mason.Packages.Before','JdtlsWorkspace.Existed','JdtlsWorkspace.Path','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths','Pending.Artifacts.Intent'^); $unexpected=@^($names ^| Where-Object { $_ -notin $allowed -and $_ -notmatch '^^Env\.[^.]+\.(?:HadValue^|Before^|Before\.Kind^)$' }^); if ^($unexpected.Count -or $state.SubKeyCount -ne 0^) { throw 'Protected install root metadata is missing after setup mutation began.' }; $artifactNames=@^('Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^); $artifactCount=@^($artifactNames ^| Where-Object { $names -contains $_ }^).Count; if ^($artifactCount -notin @^(0,3^)^) { throw 'Incomplete snapshot artifact metadata.' }; if ^($artifactCount^) { foreach ^($artifactName in $artifactNames^) { if ^($state.GetValueKind^($artifactName^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Invalid snapshot artifact metadata.' } }; if ^(@^($state.GetValue^('Artifacts.Created.Paths',$null,$option^)^).Count -ne 0^) { throw 'Invalid snapshot artifact metadata.' } }; if ^($names -contains 'Pending.Artifacts.Intent' -and $state.GetValueKind^('Pending.Artifacts.Intent'^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Invalid pending artifact metadata.' }; $status='SNAPSHOT'
>> "%TARGET_INFO_PS%" echo     }
>> "%TARGET_INFO_PS%" echo   } finally { $state.Dispose^(^) } }
>> "%TARGET_INFO_PS%" echo   [IO.File]::WriteAllText^($env:TARGET_PROFILE_FILE,$profile^); [IO.File]::WriteAllText^($env:TARGET_LOCAL_FILE,$local^); [IO.File]::WriteAllText^($env:TARGET_APP_FILE,$app^); [IO.File]::WriteAllText^($env:TARGET_NVIM_FILE,$nvim^); [IO.File]::WriteAllText^($env:TARGET_STATE_FILE,$status^)
>> "%TARGET_INFO_PS%" echo } catch { exit 1 }
set "TARGET_PROFILE_FILE=%TARGET_PROFILE_FILE%" & set "TARGET_LOCAL_FILE=%TARGET_LOCAL_FILE%" & set "TARGET_APP_FILE=%TARGET_APP_FILE%" & set "TARGET_NVIM_FILE=%TARGET_NVIM_FILE%" & set "TARGET_STATE_FILE=%TARGET_STATE_FILE%"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%TARGET_INFO_PS%" >nul 2>nul
if errorlevel 1 goto target_context_safe_failed
set /p "CP_SETUP_TARGET_PROFILE="<"%TARGET_PROFILE_FILE%"
set /p "CP_SETUP_TARGET_LOCALAPPDATA="<"%TARGET_LOCAL_FILE%"
set /p "CP_SETUP_TARGET_APPDATA="<"%TARGET_APP_FILE%"
set /p "CP_SETUP_PROTECTED_NVIMDATA="<"%TARGET_NVIM_FILE%"
set /p "CP_SETUP_STATE_CONTEXT="<"%TARGET_STATE_FILE%"
for %%F in ("%TARGET_INFO_PS%" "%TARGET_PROFILE_FILE%" "%TARGET_LOCAL_FILE%" "%TARGET_APP_FILE%" "%TARGET_NVIM_FILE%" "%TARGET_STATE_FILE%") do del "%%~F" >nul 2>nul
exit /b 0

:target_context_safe_failed
for %%F in ("%TARGET_INFO_PS%" "%TARGET_PROFILE_FILE%" "%TARGET_LOCAL_FILE%" "%TARGET_APP_FILE%" "%TARGET_NVIM_FILE%" "%TARGET_STATE_FILE%") do del "%%~F" >nul 2>nul
goto target_context_failed
:target_context_failed
echo [%ESC%[31mFAILED%ESC%[0m] The invoking user profile could not be resolved safely.
exit /b 1

:initialize_direct_elevated_context
set "CP_SETUP_TARGET_SID="
set "CP_SETUP_TARGET_PROFILE="
set "CP_SETUP_TARGET_LOCALAPPDATA="
set "CP_SETUP_TARGET_APPDATA="
for /F "usebackq delims=" %%S in (`"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value"`) do if not defined CP_SETUP_TARGET_SID set "CP_SETUP_TARGET_SID=%%S"
for /F "usebackq delims=" %%P in (`"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)"`) do if not defined CP_SETUP_TARGET_PROFILE set "CP_SETUP_TARGET_PROFILE=%%P"
for /F "usebackq delims=" %%P in (`"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)"`) do if not defined CP_SETUP_TARGET_LOCALAPPDATA set "CP_SETUP_TARGET_LOCALAPPDATA=%%P"
for /F "usebackq delims=" %%P in (`"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)"`) do if not defined CP_SETUP_TARGET_APPDATA set "CP_SETUP_TARGET_APPDATA=%%P"
if not defined CP_SETUP_TARGET_SID goto target_context_failed
if not defined CP_SETUP_TARGET_PROFILE goto target_context_failed
if not defined CP_SETUP_TARGET_LOCALAPPDATA goto target_context_failed
if not defined CP_SETUP_TARGET_APPDATA goto target_context_failed
set "TARGET_HIVE=HKU\%CP_SETUP_TARGET_SID%"
set "STATE_KEY=HKLM\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_REGISTRY=Registry::HKEY_USERS\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_STATE=Registry::HKEY_LOCAL_MACHINE\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_STATE_RELATIVE=Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_ENV=%CP_SETUP_TARGET_REGISTRY%\Environment"
set "CP_SETUP_PROTECTED_NVIMDATA=%CP_SETUP_TARGET_LOCALAPPDATA%\nvim-data"
set "CP_SETUP_STATE_CONTEXT=DIRECT_PARENT"
set "CP_SETUP_LEGACY_STATE=0"
call :initialize_visible_temp
exit /b %ERRORLEVEL%

:initialize_visible_temp
set "CP_VISIBLE_TEMP=%CP_SETUP_TARGET_LOCALAPPDATA%\Temp"
set "CP_VISIBLE_TMP=%CP_VISIBLE_TEMP%"
if not "%CP_RUNTIME_SECURE%"=="1" set "CP_RUNTIME_TEMP=%CP_VISIBLE_TEMP%"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $profile=[IO.Path]::GetFullPath($env:CP_SETUP_TARGET_PROFILE).TrimEnd('\'); $local=[IO.Path]::GetFullPath($env:CP_SETUP_TARGET_LOCALAPPDATA).TrimEnd('\'); $temp=[IO.Path]::GetFullPath($env:CP_VISIBLE_TEMP).TrimEnd('\'); if (-not $local.StartsWith($profile+'\',[StringComparison]::OrdinalIgnoreCase) -or $temp -ine ($local+'\Temp')) { exit 1 }; $current=$temp; while ($current) { $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if (-not $item.PSIsContainer -or [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 }; $parent=[IO.Directory]::GetParent($current); if (-not $parent) { break }; $next=$parent.FullName; if ($next -eq $current) { break }; $current=$next }; exit 0 } catch { exit 1 }" >nul 2>nul
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] The invoking user's temporary directory could not be verified safely.
exit /b 1

:validate_setup_root
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:ROOT; if ($root -notmatch '^[A-Za-z]:\\') { exit 1 }; foreach ($code in @(33,37,38,59,60,62,94,124)) { if ($root.IndexOf([char]$code) -ge 0) { exit 1 } }; foreach ($value in @($env:CP_VISIBLE_TEMP,$env:CP_SETUP_TARGET_LOCALAPPDATA,$env:CP_SETUP_TARGET_APPDATA)) { if ($value -and $value.IndexOf([char]33) -ge 0) { exit 2 } }; exit 0"
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
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\'); $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); if (-not $key) { if ($env:CP_SETUP_STATE_CONTEXT -ne 'ABSENT') { throw 'Protected setup state disappeared during validation.' }; exit 0 }; try { $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames; $names=@($key.GetValueNames()); if ($names -notcontains 'Install.Root') { if ($env:CP_SETUP_STATE_CONTEXT -ne 'SNAPSHOT') { throw 'Protected install root metadata is missing.' }; $allowed=@('SchemaVersion','Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root','Snapshot.Complete','Path.HadValue','Path.Before','Path.Before.Kind','AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','NvimData.Existed','Mason.Packages.Before','JdtlsWorkspace.Existed','JdtlsWorkspace.Path','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths','Pending.Artifacts.Intent'); $unexpected=@($names | Where-Object { $_ -notin $allowed -and $_ -notmatch '^Env\.[^.]+\.(?:HadValue|Before|Before\.Kind)$' }); if ($unexpected.Count -or $key.SubKeyCount -ne 0) { throw 'Protected install root metadata is missing after setup mutation began.' }; $artifactNames=@('Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'); $artifactCount=@($artifactNames | Where-Object { $names -contains $_ }).Count; if ($artifactCount -notin @(0,3)) { throw 'Incomplete snapshot artifact metadata.' }; if ($artifactCount) { foreach ($name in $artifactNames) { if ($key.GetValueKind($name) -ne [Microsoft.Win32.RegistryValueKind]::MultiString) { throw 'Invalid snapshot artifact metadata.' } }; if (@($key.GetValue('Artifacts.Created.Paths',$null,$option)).Count -ne 0) { throw 'Invalid snapshot artifact metadata.' } }; if ($names -contains 'Pending.Artifacts.Intent' -and $key.GetValueKind('Pending.Artifacts.Intent') -ne [Microsoft.Win32.RegistryValueKind]::String) { throw 'Invalid pending artifact metadata.' }; exit 0 }; if ($env:CP_SETUP_STATE_CONTEXT -ne 'FOUND' -or $key.GetValueKind('Install.Root') -ne [Microsoft.Win32.RegistryValueKind]::String) { throw 'Protected install root metadata is invalid.' }; $stored=[IO.Path]::GetFullPath([string]$key.GetValue('Install.Root',$null,$option)).TrimEnd('\'); if ($stored -ine $root) { Write-Host ('[FAILED] This setup is managed from: '+$stored); Write-Host 'Run uninstall.bat from that folder.'; exit 1 } } finally { $key.Dispose() }; exit 0 } catch { Write-Host ('[FAILED] Setup ownership state could not be read safely: '+$_.Exception.Message); exit 2 }"
exit /b %ERRORLEVEL%

:has_setup_configuration
set "CONFIG_CHECK_PS=%CP_RUNTIME_TEMP%\cp_setup_config_check_%RANDOM%_%RANDOM%.ps1"
> "%CONFIG_CHECK_PS%" echo $ErrorActionPreference = 'Stop'
>> "%CONFIG_CHECK_PS%" echo try {
>> "%CONFIG_CHECK_PS%" echo     $option = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%CONFIG_CHECK_PS%" echo     $state = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^)
>> "%CONFIG_CHECK_PS%" echo     if ^(-not $state^) { exit 1 }
>> "%CONFIG_CHECK_PS%" echo     try {
>> "%CONFIG_CHECK_PS%" echo         $stateNames = @^($state.GetValueNames^(^)^)
>> "%CONFIG_CHECK_PS%" echo         $users = [Microsoft.Win32.Registry]::Users
>> "%CONFIG_CHECK_PS%" echo         $envKey = $users.OpenSubKey^($env:CP_SETUP_TARGET_SID + '\Environment',$false^)
>> "%CONFIG_CHECK_PS%" echo         $hasManaged = $stateNames -contains 'Config.Managed'
>> "%CONFIG_CHECK_PS%" echo         $hasEnvironment = $false
>> "%CONFIG_CHECK_PS%" echo         if ^($envKey^) { try {
>> "%CONFIG_CHECK_PS%" echo             $envNames = @^($envKey.GetValueNames^(^)^)
>> "%CONFIG_CHECK_PS%" echo             foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) { $writtenName='Env.'+$name+'.Written'; $kindName=$writtenName+'.Kind'; if ^($stateNames -contains $writtenName -and $stateNames -contains $kindName -and $envNames -contains $name^) { $current=[string]$envKey.GetValue^($name,$null,$option^); $kind=[int]$envKey.GetValueKind^($name^); $written=[string]$state.GetValue^($writtenName,$null,$option^); $writtenKind=[int]$state.GetValue^($kindName,0,$option^); if ^($current -ceq $written -and $kind -eq $writtenKind^) { $hasEnvironment=$true; break } } }
>> "%CONFIG_CHECK_PS%" echo             if ^(-not $hasEnvironment -and $stateNames -contains 'Path.Written' -and $stateNames -contains 'Path.Written.Kind' -and $envNames -contains 'Path'^) { $current=[string]$envKey.GetValue^('Path',$null,$option^); $kind=[int]$envKey.GetValueKind^('Path'^); $written=[string]$state.GetValue^('Path.Written',$null,$option^); $writtenKind=[int]$state.GetValue^('Path.Written.Kind',0,$option^); $hasEnvironment=$current -ceq $written -and $kind -eq $writtenKind }
>> "%CONFIG_CHECK_PS%" echo         } finally { $envKey.Dispose^(^) } }
>> "%CONFIG_CHECK_PS%" echo         $hasAutoRun = $false
>> "%CONFIG_CHECK_PS%" echo         $autoKey = $users.OpenSubKey^($env:CP_SETUP_TARGET_SID + '\Software\Microsoft\Command Processor',$false^)
>> "%CONFIG_CHECK_PS%" echo         if ^($autoKey^) { try { if ^($autoKey.GetValueNames^(^) -contains 'AutoRun' -and $stateNames -contains 'AutoRun.Written' -and $stateNames -contains 'AutoRun.Written.Kind'^) { $current=[string]$autoKey.GetValue^('AutoRun',$null,$option^); $kind=[int]$autoKey.GetValueKind^('AutoRun'^); $written=[string]$state.GetValue^('AutoRun.Written',$null,$option^); $writtenKind=[int]$state.GetValue^('AutoRun.Written.Kind',0,$option^); $hasAutoRun=$current -ceq $written -and $kind -eq $writtenKind } } finally { $autoKey.Dispose^(^) } }
>> "%CONFIG_CHECK_PS%" echo         if ^($hasManaged -or $hasEnvironment -or $hasAutoRun^) { exit 0 }
>> "%CONFIG_CHECK_PS%" echo     } finally { $state.Dispose^(^) }
>> "%CONFIG_CHECK_PS%" echo     exit 1
>> "%CONFIG_CHECK_PS%" echo } catch { exit 2 }
set "CONFIG_CHECKER=%CP_RUNTIME_TEMP%\cp_setup_config_check_%RANDOM%_%RANDOM%.cmd"
> "%CONFIG_CHECKER%" echo @echo off
>> "%CONFIG_CHECKER%" echo "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%CONFIG_CHECK_PS%"
>> "%CONFIG_CHECKER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call "%CONFIG_CHECKER%""
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
exit /b 0

:enable_ansi
rem Do not mutate the target user's Console registry while uninstalling.
"%POWERSHELL_EXE%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Add-Type -Namespace Native -Name Console -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern System.IntPtr GetStdHandle(int nStdHandle); [DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out int lpMode); [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, int dwMode);'; $h=[Native.Console]::GetStdHandle(-11); $mode=0; if ([Native.Console]::GetConsoleMode($h,[ref]$mode)) { [Native.Console]::SetConsoleMode($h,$mode -bor 4) | Out-Null }" >nul 2>nul
for /F "delims=#" %%E in ('"prompt #$E# & for %%B in (1) do rem"') do set "ESC=%%E"
exit /b 0

:refresh_path
if not "%CHECK_ONLY%"=="1" exit /b 0
set "PATH_FILE=%CP_RUNTIME_TEMP%\cp_setup_uninstall_path_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$key=[Microsoft.Win32.Registry]::Users.OpenSubKey($env:CP_SETUP_TARGET_SID+'\Environment',$false);$user='';if($key){try{$user=[string]$key.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}finally{$key.Dispose()}};$user=[Environment]::ExpandEnvironmentVariables($user);[IO.File]::WriteAllText($env:PATH_FILE,([Environment]::GetEnvironmentVariable('Path','Machine')+';'+$user))" >nul 2>nul
if not errorlevel 1 set /p "PATH="<"%PATH_FILE%"
del "%PATH_FILE%" >nul 2>nul
exit /b 0

:ensure_admin
set "ELEVATE_ALREADY_ADMIN=0"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1"
if not errorlevel 1 set "ELEVATE_ALREADY_ADMIN=1"
if "%ELEVATE_ALREADY_ADMIN%"=="1" if "%CP_SETUP_ELEVATED_CHILD%"=="1" exit /b 0
if "%ELEVATE_ALREADY_ADMIN%"=="0" if "%NON_INTERACTIVE%"=="1" (
    echo [%ESC%[31mFAILED%ESC%[0m] Non-interactive uninstall requires an already elevated terminal.
    exit /b 1
)

set "CP_UNINSTALL_SCRIPT=%~f0"
set "CP_UNINSTALL_ARGS=%ELEVATED_UNINSTALL_ARGS%"
set "CP_UNINSTALL_CWD=%SYSTEM32%"
set "CP_ELEVATE_UAC_TIMEOUT_SECONDS=%UNINSTALL_UAC_TIMEOUT_SECONDS%"
set "CP_ELEVATE_CHILD_TIMEOUT_SECONDS=%UNINSTALL_CHILD_TIMEOUT_SECONDS%"
set "CP_SOURCE_TRANSPORT_PATH=%CP_VISIBLE_TEMP%\cp_setup_uninstall_source_%RANDOM%_%RANDOM%.transport"
set "CP_ELEVATE_PROTOCOL_FILE=%CP_VISIBLE_TEMP%\cp_setup_uninstall_protocol_%RANDOM%_%RANDOM%.txt"
del "%CP_ELEVATE_PROTOCOL_FILE%" >nul 2>nul
setlocal DisableDelayedExpansion
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$lines=[IO.File]::ReadAllLines($env:CP_UNINSTALL_SCRIPT);$first=[Array]::IndexOf($lines,'::__CP_UNINSTALL_ELEVATE_BEGIN__');$last=[Array]::IndexOf($lines,'::__CP_UNINSTALL_ELEVATE_END__');if($first-lt 0-or$last-le$first){throw 'Missing uninstall elevation orchestrator.'};$source=for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw 'Malformed uninstall elevation orchestrator.'};$lines[$i].Substring(2)};&([scriptblock]::Create($source-join[Environment]::NewLine))"
set "ELEVATE_EXIT=%ERRORLEVEL%"
del "%CP_SOURCE_TRANSPORT_PATH%" >nul 2>nul
endlocal & set "ELEVATE_EXIT=%ELEVATE_EXIT%"
set "SCHEDULE_EXIT=0"
if "%ELEVATE_EXIT%"=="10" (
    cd /d "%CP_VISIBLE_TEMP%"
    call :schedule_repo_removal
    set "SCHEDULE_EXIT=!ERRORLEVEL!"
)
if not "%ELEVATE_EXIT%"=="0" if not "%ELEVATE_EXIT%"=="10" (
    del "%CP_ELEVATE_PROTOCOL_FILE%" >nul 2>nul
    exit /b %ELEVATE_EXIT%
)
if not "%SCHEDULE_EXIT%"=="0" (
    call :finalize_protocol_transcript 1
    del "%CP_ELEVATE_PROTOCOL_FILE%" >nul 2>nul
    echo.
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
    call :wait_to_finish
    exit /b 1
)
if "%ELEVATE_EXIT%"=="10" (
    call :finalize_protocol_transcript 0
    if errorlevel 1 (
        del "%CP_ELEVATE_PROTOCOL_FILE%" >nul 2>nul
        echo.
        echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
        call :wait_to_finish
        exit /b 1
    )
    if exist "%CP_ELEVATE_PROTOCOL_FILE%" type "%CP_ELEVATE_PROTOCOL_FILE%"
    del "%CP_ELEVATE_PROTOCOL_FILE%" >nul 2>nul
)
exit /b 2

:finalize_protocol_transcript
set "FINAL_PROTOCOL_EXIT=%~1"
set "FINAL_TRANSCRIPT_PATH=%UNINSTALL_LOG_REQUESTED%"
if not defined FINAL_TRANSCRIPT_PATH set "FINAL_TRANSCRIPT_PATH=%CP_VISIBLE_TEMP%\cp_setup_uninstall.log"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$path=$env:FINAL_TRANSCRIPT_PATH;if(-not[IO.Path]::IsPathRooted($path)){$path=Join-Path $env:ROOT $path};$path=[IO.Path]::GetFullPath($path);if(-not[IO.File]::Exists($path)){throw'Uninstall transcript is missing.'};$lines=[Collections.Generic.List[string]]::new();foreach($line in [IO.File]::ReadAllLines($path,[Text.Encoding]::Default)){if($line-notmatch'^\[CP-SETUP\] END(?:\s|$)'){$lines.Add($line)}};$lines.Add('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit='+$env:FINAL_PROTOCOL_EXIT);[IO.File]::WriteAllLines($path,$lines,[Text.Encoding]::Default)" >nul 2>nul
exit /b %ERRORLEVEL%

:initialize_secure_runtime
if "%CP_RUNTIME_SECURE%"=="1" exit /b 0
set "CP_RUNTIME_TEMP="
set "SECURE_RUNTIME_BOOTSTRAP_OWNED=1"
set "SECURE_RUNTIME_BOOTSTRAP=%TRUSTED_SYSTEMROOT%\Temp\cp-setup-bootstrap-%RANDOM%-%RANDOM%-%RANDOM%"
if defined CP_ELEVATE_TRANSCRIPT_DIR (
    set "SECURE_RUNTIME_BOOTSTRAP_OWNED=0"
    set "SECURE_RUNTIME_BOOTSTRAP=%CP_ELEVATE_TRANSCRIPT_DIR%"
)
set "SECURE_RUNTIME_PS=%SECURE_RUNTIME_BOOTSTRAP%\initialize.ps1"
set "SECURE_RUNTIME_OUTPUT=%SECURE_RUNTIME_BOOTSTRAP%\runtime.txt"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92);$path=[IO.Path]::GetFullPath($env:SECURE_RUNTIME_BOOTSTRAP).TrimEnd([char]92);$owned=$env:SECURE_RUNTIME_BOOTSTRAP_OWNED-eq'1';$leaf=[IO.Path]::GetFileName($path);$validLeaf=if($owned){$leaf-match'^cp-setup-bootstrap-[0-9]+-[0-9]+-[0-9]+$'}else{$leaf-match'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'};if(-not$path.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or-not$validLeaf){throw'Unsafe secure-runtime bootstrap path.'};$baseItem=Get-Item -LiteralPath $base -Force;if(-not$baseItem.PSIsContainer-or($baseItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Unsafe secure-runtime bootstrap root.'};$admin=[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544');$system=[Security.Principal.SecurityIdentifier]::new('S-1-5-18');if($owned){if([IO.Directory]::Exists($path)){throw'Secure-runtime bootstrap already exists.'};$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner($admin);$acl.SetAccessRuleProtection($true,$false);$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit;foreach($sid in @($system,$admin)){$rule=[Security.AccessControl.FileSystemAccessRule]::new($sid,[Security.AccessControl.FileSystemRights]::Modify,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow);[void]$acl.AddAccessRule($rule)};[IO.Directory]::CreateDirectory($path,$acl)|Out-Null};$item=Get-Item -LiteralPath $path -Force;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Unsafe secure-runtime bootstrap.'};$actual=$item.GetAccessControl();try{$owner=([Security.Principal.NTAccount]$actual.Owner).Translate([Security.Principal.SecurityIdentifier]).Value}catch{$owner=$actual.Owner};if($owner-notin@($admin.Value,$system.Value)-or-not$actual.AreAccessRulesProtected){throw'Unsafe secure-runtime bootstrap ACL.'};$mask=[Security.AccessControl.FileSystemRights]::WriteData-bor[Security.AccessControl.FileSystemRights]::AppendData-bor[Security.AccessControl.FileSystemRights]::WriteExtendedAttributes-bor[Security.AccessControl.FileSystemRights]::WriteAttributes-bor[Security.AccessControl.FileSystemRights]::ChangePermissions-bor[Security.AccessControl.FileSystemRights]::TakeOwnership;foreach($ace in $actual.Access){try{$sid=$ace.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value}catch{$sid=[string]$ace.IdentityReference};if($sid-notin@($admin.Value,$system.Value)-and$ace.AccessControlType-eq[Security.AccessControl.AccessControlType]::Allow-and([int64]$ace.FileSystemRights-band[int64]$mask)){throw'Secure-runtime bootstrap is writable by an untrusted identity.'}}" >nul 2>nul
if errorlevel 1 goto secure_runtime_initialization_failed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$lines=[IO.File]::ReadAllLines($env:UNINSTALL_SCRIPT);$first=[Array]::IndexOf($lines,'::__CP_SECURE_RUNTIME_BEGIN__');$last=[Array]::IndexOf($lines,'::__CP_SECURE_RUNTIME_END__');if($first-lt0-or$last-le$first){throw'Missing secure-runtime source block.'};$source=[Collections.Generic.List[string]]::new();for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw'Malformed secure-runtime source block.'};$source.Add($lines[$i].Substring(2))};[IO.File]::WriteAllLines($env:SECURE_RUNTIME_PS,$source,[Text.UTF8Encoding]::new($false))" >nul 2>nul
if errorlevel 1 goto secure_runtime_initialization_failed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SECURE_RUNTIME_PS%" >nul 2>nul
if errorlevel 1 goto secure_runtime_initialization_failed
if exist "%SECURE_RUNTIME_OUTPUT%" set /p "CP_RUNTIME_TEMP="<"%SECURE_RUNTIME_OUTPUT%"
if not defined CP_RUNTIME_TEMP goto secure_runtime_initialization_failed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$path=[IO.Path]::GetFullPath($env:CP_RUNTIME_TEMP).TrimEnd([char]92);$base=[IO.Path]::GetFullPath((Join-Path([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData))'my-cp-setup-runtime')).TrimEnd([char]92);if(-not$path.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($path)-notmatch'^[0-9a-f]{32}$'-or-not[IO.Directory]::Exists($path)-or([IO.File]::GetAttributes($path)-band[IO.FileAttributes]::ReparsePoint)){exit 1};exit 0" >nul 2>nul
if errorlevel 1 goto secure_runtime_initialization_failed
set "CP_RUNTIME_SECURE=1"
call :cleanup_secure_bootstrap >nul 2>nul
if errorlevel 1 (
    call :cleanup_secure_runtime >nul 2>nul
    echo [%ESC%[31mFAILED%ESC%[0m] A protected temporary directory could not be created for the uninstaller.
    exit /b 1
)
exit /b 0

:secure_runtime_initialization_failed
call :cleanup_secure_bootstrap >nul 2>nul
echo [%ESC%[31mFAILED%ESC%[0m] A protected temporary directory could not be created for the uninstaller.
exit /b 1

:cleanup_secure_bootstrap
if not defined SECURE_RUNTIME_BOOTSTRAP exit /b 0
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92);$path=[IO.Path]::GetFullPath($env:SECURE_RUNTIME_BOOTSTRAP).TrimEnd([char]92);$owned=$env:SECURE_RUNTIME_BOOTSTRAP_OWNED-eq'1';$leaf=[IO.Path]::GetFileName($path);$validLeaf=if($owned){$leaf-match'^cp-setup-bootstrap-[0-9]+-[0-9]+-[0-9]+$'}else{$leaf-match'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'};if(-not$path.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or-not$validLeaf){throw'Unsafe secure-runtime bootstrap cleanup path.'};if([IO.Directory]::Exists($path)){$root=[IO.DirectoryInfo]::new($path);if($root.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Secure-runtime bootstrap cleanup encountered a reparse point.'};$acl=$root.GetAccessControl();try{$owner=([Security.Principal.NTAccount]$acl.Owner).Translate([Security.Principal.SecurityIdentifier]).Value}catch{$owner=$acl.Owner};if($owner-notin@('S-1-5-18','S-1-5-32-544')-or-not$acl.AreAccessRulesProtected){throw'Unsafe secure-runtime bootstrap ACL.'};if($owned){$stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root);while($stack.Count){$dir=$stack.Pop();foreach($item in $dir.EnumerateFileSystemInfos()){if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Secure-runtime bootstrap contains a reparse point.'};if($item-is[IO.DirectoryInfo]){$stack.Push($item)}}};[IO.Directory]::Delete($path,$true)}else{foreach($name in @('initialize.ps1','runtime.txt')){$file=Join-Path $path $name;if([IO.File]::Exists($file)){if([IO.File]::GetAttributes($file)-band[IO.FileAttributes]::ReparsePoint){throw'Secure-runtime bootstrap helper is a reparse point.'};[IO.File]::Delete($file)}}}};if($owned-and[IO.Directory]::Exists($path)){exit 1};exit 0" >nul 2>nul
set "SECURE_BOOTSTRAP_EXIT=%ERRORLEVEL%"
if "%SECURE_BOOTSTRAP_EXIT%"=="0" (
    set "SECURE_RUNTIME_BOOTSTRAP="
    set "SECURE_RUNTIME_BOOTSTRAP_OWNED="
    set "SECURE_RUNTIME_PS="
    set "SECURE_RUNTIME_OUTPUT="
)
exit /b %SECURE_BOOTSTRAP_EXIT%
:cleanup_secure_runtime
if not "%CP_RUNTIME_SECURE%"=="1" exit /b 0
cd /d "%SYSTEM32%"
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $path=[IO.Path]::GetFullPath($env:CP_RUNTIME_TEMP).TrimEnd('\'); $programData=[IO.Path]::GetFullPath([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)).TrimEnd('\'); $base=[IO.Path]::GetFullPath((Join-Path $programData 'my-cp-setup-runtime')).TrimEnd('\'); if (-not $path.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $path) -notmatch '^[0-9a-f]{32}$') { exit 1 }; function Remove-TreeNoFollow([string]$target,[string]$boundary) { $full=[IO.Path]::GetFullPath($target).TrimEnd('\'); if ($full -ine $boundary -and -not $full.StartsWith($boundary+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe runtime cleanup path' }; if (-not (Test-Path -LiteralPath $full)) { return }; $item=Get-Item -LiteralPath $full -Force; if ([bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Runtime cleanup encountered a reparse point' }; if (-not $item.PSIsContainer) { $item.Attributes=[IO.FileAttributes]::Normal; $item.Delete(); return }; foreach ($child in @($item.GetFileSystemInfos())) { $childFull=[IO.Path]::GetFullPath($child.FullName); if (-not $childFull.StartsWith($full+'\',[StringComparison]::OrdinalIgnoreCase) -or [bool]($child.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe runtime cleanup child' }; Remove-TreeNoFollow $childFull $full }; $item.Refresh(); $item.Delete() }; if (Test-Path -LiteralPath $path) { Remove-TreeNoFollow $path $base }; if (Test-Path -LiteralPath $path) { exit 1 }; if (Test-Path -LiteralPath $base) { $baseItem=Get-Item -LiteralPath $base -Force; if ([bool]($baseItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 }; if (@($baseItem.GetFileSystemInfos()).Count -eq 0) { $baseItem.Delete() } }; exit 0" >nul 2>nul
set "RUNTIME_CLEANUP_EXIT=%ERRORLEVEL%"
if "%RUNTIME_CLEANUP_EXIT%"=="0" if defined CP_ELEVATE_TRANSCRIPT_DIR "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$dir=[IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR).TrimEnd([char]92);$base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92);if(-not$dir.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($dir)-notmatch'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'){throw'Unsafe runtime marker directory.'};$marker=Join-Path $dir 'runtime.marker';if([IO.File]::Exists($marker)){$parts=([IO.File]::ReadAllText($marker,[Text.Encoding]::Default).Trim()).Split([char]'|');if($parts.Count-ne4-or$parts[0]-cne$env:CP_RUNTIME_OPERATION_ID-or[IO.Path]::GetFullPath($parts[1]).TrimEnd([char]92)-ine[IO.Path]::GetFullPath($env:CP_RUNTIME_TEMP).TrimEnd([char]92)){throw'Runtime marker changed.'};[IO.File]::Delete($marker)};if([IO.File]::Exists($marker)){exit 1};exit 0" >nul 2>nul
if "%RUNTIME_CLEANUP_EXIT%"=="0" if errorlevel 1 set "RUNTIME_CLEANUP_EXIT=1"
if "%RUNTIME_CLEANUP_EXIT%"=="0" (
    set "CP_RUNTIME_SECURE=0"
    set "CP_RUNTIME_TEMP=%CP_VISIBLE_TEMP%"
    set "TEMP=%CP_VISIBLE_TEMP%"
    set "TMP=%CP_VISIBLE_TMP%"
)
exit /b %RUNTIME_CLEANUP_EXIT%

:sanitize_elevated_environment
set "SystemRoot=%TRUSTED_SYSTEMROOT%"
set "windir=%TRUSTED_SYSTEMROOT%"
set "SystemDrive=%TRUSTED_SYSTEMROOT:~0,2%"
set "ComSpec=%CMD_EXE%"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%SYSTEM32%;%TRUSTED_SYSTEMROOT%;%SYSTEM32%\Wbem;%SYSTEM32%\WindowsPowerShell\v1.0"
set "PSModulePath=%SYSTEM32%\WindowsPowerShell\v1.0\Modules"
set "TEMP=%CP_RUNTIME_TEMP%"
set "TMP=%CP_RUNTIME_TEMP%"
set "BASH_ENV="
set "ENV="
set "SHELLOPTS="
set "BASHOPTS="
set "MSYS="
set "MSYS2_PATH_TYPE="
set "CHERE_INVOKING="
set "MSYSTEM="
set "QT_PLUGIN_PATH="
set "QT_QPA_PLATFORM_PLUGIN_PATH="
set "QML2_IMPORT_PATH="
set "PYTHONHOME="
set "PYTHONPATH="
set "JAVA_TOOL_OPTIONS="
set "_JAVA_OPTIONS="
set "JDK_JAVA_OPTIONS="
set "GIT_EXEC_PATH="
set "GIT_CONFIG="
set "GIT_CONFIG_GLOBAL="
set "GIT_CONFIG_SYSTEM="
set "GIT_CONFIG_NOSYSTEM="
set "RUBYOPT="
set "PERL5OPT="
set "DOTNET_STARTUP_HOOKS="
set "COR_ENABLE_PROFILING="
set "COR_PROFILER="
set "__COMPAT_LAYER="
exit /b 0

:prepare_process_tree_helpers
if defined PROCESS_TREE_NATIVE_CS if defined PROCESS_TREE_PS if exist "%PROCESS_TREE_NATIVE_CS%" if exist "%PROCESS_TREE_PS%" exit /b 0
set "PROCESS_TREE_NATIVE_CS=%CP_RUNTIME_TEMP%\cp_setup_process_tree_%RANDOM%_%RANDOM%.cs"
set "PROCESS_TREE_PS=%CP_RUNTIME_TEMP%\cp_setup_process_tree_%RANDOM%_%RANDOM%.ps1"
set "NATIVE_EXTRACT_PS=%CP_RUNTIME_TEMP%\cp_setup_native_extract_%RANDOM%_%RANDOM%.ps1"
> "%NATIVE_EXTRACT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%NATIVE_EXTRACT_PS%" echo $lines=[IO.File]::ReadAllLines^($env:UNINSTALL_SCRIPT^)
>> "%NATIVE_EXTRACT_PS%" echo function Export-Block^([string]$begin,[string]$end,[string]$destination^) { $first=[Array]::IndexOf^($lines,'::'+$begin^); $last=[Array]::IndexOf^($lines,'::'+$end^); if ^($first -lt 0 -or $last -le $first^) { throw ^('Missing protected source block: '+$begin^) }; $content=[Collections.Generic.List[string]]::new^(^); for ^($i=$first+1;$i -lt $last;$i++^) { if ^(-not $lines[$i].StartsWith^('::',[StringComparison]::Ordinal^)^) { throw 'Malformed protected source block.' }; $content.Add^($lines[$i].Substring^(2^)^) }; [IO.File]::WriteAllLines^($destination,$content,[Text.UTF8Encoding]::new^($false^)^) }
>> "%NATIVE_EXTRACT_PS%" echo Export-Block '__CP_PROCESS_TREE_NATIVE_BEGIN__' '__CP_PROCESS_TREE_NATIVE_END__' $env:PROCESS_TREE_NATIVE_CS
>> "%NATIVE_EXTRACT_PS%" echo Export-Block '__CP_PROCESS_TREE_PS_BEGIN__' '__CP_PROCESS_TREE_PS_END__' $env:PROCESS_TREE_PS
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%NATIVE_EXTRACT_PS%"
set "NATIVE_EXTRACT_EXIT=%ERRORLEVEL%"
del "%NATIVE_EXTRACT_PS%" >nul 2>nul
set "NATIVE_EXTRACT_PS="
if not "%NATIVE_EXTRACT_EXIT%"=="0" exit /b %NATIVE_EXTRACT_EXIT%
if not exist "%PROCESS_TREE_NATIVE_CS%" exit /b 1
if not exist "%PROCESS_TREE_PS%" exit /b 1
exit /b 0

:cleanup_process_tree_helpers
if defined PROCESS_TREE_NATIVE_CS del "%PROCESS_TREE_NATIVE_CS%" >nul 2>nul
if defined PROCESS_TREE_PS del "%PROCESS_TREE_PS%" >nul 2>nul
set "PROCESS_TREE_NATIVE_CS="
set "PROCESS_TREE_PS="
exit /b 0

:export_embedded_block
set "EXPORT_BLOCK_BEGIN=%~1"
set "EXPORT_BLOCK_END=%~2"
set "EXPORT_BLOCK_DESTINATION=%~3"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$lines=[IO.File]::ReadAllLines($env:UNINSTALL_SCRIPT);$first=[Array]::IndexOf($lines,$env:EXPORT_BLOCK_BEGIN);$last=[Array]::IndexOf($lines,$env:EXPORT_BLOCK_END);if($first-lt0-or$last-le$first){throw('Missing protected source block: '+$env:EXPORT_BLOCK_BEGIN)};$content=[Collections.Generic.List[string]]::new();for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw'Malformed protected source block.'};$content.Add($lines[$i].Substring(2))};[IO.File]::WriteAllLines($env:EXPORT_BLOCK_DESTINATION,$content,[Text.UTF8Encoding]::new($false))" >nul 2>nul
set "EXPORT_BLOCK_EXIT=%ERRORLEVEL%"
set "EXPORT_BLOCK_BEGIN="
set "EXPORT_BLOCK_END="
set "EXPORT_BLOCK_DESTINATION="
exit /b %EXPORT_BLOCK_EXIT%

:prepare_native_helpers
call :prepare_process_tree_helpers
if errorlevel 1 exit /b %ERRORLEVEL%
if defined MEDIUM_LAUNCHER_PS if defined MEDIUM_NATIVE_CS if exist "%MEDIUM_LAUNCHER_PS%" if exist "%MEDIUM_NATIVE_CS%" exit /b 0
set "MEDIUM_LAUNCHER_PS=%CP_RUNTIME_TEMP%\cp_setup_medium_launcher_%RANDOM%_%RANDOM%.ps1"
set "MEDIUM_NATIVE_CS=%CP_RUNTIME_TEMP%\cp_setup_medium_native_%RANDOM%_%RANDOM%.cs"
set "MEDIUM_EXTRACT_PS=%CP_RUNTIME_TEMP%\cp_setup_medium_extract_%RANDOM%_%RANDOM%.ps1"
> "%MEDIUM_EXTRACT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MEDIUM_EXTRACT_PS%" echo $lines=[IO.File]::ReadAllLines^($env:UNINSTALL_SCRIPT^)
>> "%MEDIUM_EXTRACT_PS%" echo function Export-Block^([string]$begin,[string]$end,[string]$destination^) { $first=[Array]::IndexOf^($lines,'::'+$begin^); $last=[Array]::IndexOf^($lines,'::'+$end^); if ^($first -lt 0 -or $last -le $first^) { throw ^('Missing protected source block: '+$begin^) }; $content=[Collections.Generic.List[string]]::new^(^); for ^($i=$first+1;$i -lt $last;$i++^) { if ^(-not $lines[$i].StartsWith^('::',[StringComparison]::Ordinal^)^) { throw 'Malformed protected source block.' }; $content.Add^($lines[$i].Substring^(2^)^) }; [IO.File]::WriteAllLines^($destination,$content,[Text.UTF8Encoding]::new^($false^)^) }
>> "%MEDIUM_EXTRACT_PS%" echo Export-Block '__CP_MEDIUM_LAUNCHER_BEGIN__' '__CP_MEDIUM_LAUNCHER_END__' $env:MEDIUM_LAUNCHER_PS
>> "%MEDIUM_EXTRACT_PS%" echo Export-Block '__CP_MEDIUM_NATIVE_BEGIN__' '__CP_MEDIUM_NATIVE_END__' $env:MEDIUM_NATIVE_CS
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_EXTRACT_PS%"
set "MEDIUM_EXTRACT_EXIT=%ERRORLEVEL%"
del "%MEDIUM_EXTRACT_PS%" >nul 2>nul
set "MEDIUM_EXTRACT_PS="
if not "%MEDIUM_EXTRACT_EXIT%"=="0" exit /b %MEDIUM_EXTRACT_EXIT%
if not exist "%MEDIUM_LAUNCHER_PS%" exit /b 1
if not exist "%MEDIUM_NATIVE_CS%" exit /b 1
exit /b 0

:run_medium_worker
if not exist "%~1" exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%~1" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32%" -ExecTemp "%CP_RUNTIME_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds %~2
set "MEDIUM_WORKER_EXIT=%ERRORLEVEL%"
if "%MEDIUM_WORKER_EXIT%"=="124" set "UNINSTALL_TIMEOUT_SEEN=1"
exit /b %MEDIUM_WORKER_EXIT%

:publish_component_log
set "CP_LOG_NAME=%~1"
set "CP_LOG_SOURCE=%CP_RUNTIME_TEMP%\%~1"
if not exist "%CP_LOG_SOURCE%" exit /b 0
if exist "%CP_LOG_SOURCE%\" exit /b 1
set "LOG_PUBLISHER_PS=%CP_RUNTIME_TEMP%\cp_setup_log_publisher_%RANDOM%_%RANDOM%.ps1"
> "%LOG_PUBLISHER_PS%" echo $ErrorActionPreference='Stop'
>> "%LOG_PUBLISHER_PS%" echo Set-StrictMode -Version 2
>> "%LOG_PUBLISHER_PS%" echo $identity=[Security.Principal.WindowsIdentity]::GetCurrent^(^);if^($identity.User.Value-ine$env:CP_SETUP_TARGET_SID^){throw 'Log publisher SID mismatch.'};if^(([Security.Principal.WindowsPrincipal]::new^($identity^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)^){throw 'Log publisher unexpectedly has an elevated token.'}
>> "%LOG_PUBLISHER_PS%" echo $name=[string]$env:CP_LOG_NAME;if^($name-notmatch'^^cp_setup_[A-Za-z0-9_]{1,64}\.log$'^){throw 'Invalid component log name.'}
>> "%LOG_PUBLISHER_PS%" echo function Assert-Path^([string]$path,[bool]$leafMayBeMissing^){$full=[IO.Path]::GetFullPath^($path^);$root=[IO.Path]::GetPathRoot^($full^);$current=$root;$parts=$full.Substring^($root.Length^).Split^([char[]]@^([char]92^),[StringSplitOptions]::RemoveEmptyEntries^);for^($i=0;$i-lt$parts.Count;$i++^){$current=[IO.Path]::Combine^($current,$parts[$i]^);if^($leafMayBeMissing-and$i-eq$parts.Count-1-and-not[IO.File]::Exists^($current^)-and-not[IO.Directory]::Exists^($current^)^){continue};$item=Get-Item -LiteralPath $current -Force -ErrorAction Stop;if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^){throw ^('Component log path contains a reparse point: '+$current^)}};$full}
>> "%LOG_PUBLISHER_PS%" echo $runtime=Assert-Path $env:CP_RUNTIME_TEMP $false;$source=Assert-Path $env:CP_LOG_SOURCE $false;if^([IO.Path]::GetDirectoryName^($source^)-ine$runtime-or[IO.Path]::GetFileName^($source^)-cne$name-or-not[IO.File]::Exists^($source^)^){throw 'Protected component log is invalid.'}
>> "%LOG_PUBLISHER_PS%" echo $local=[IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_LOCALAPPDATA^).TrimEnd^([char]92^);$targetRoot=Assert-Path $env:CP_VISIBLE_TEMP $false;if^($targetRoot-ine[IO.Path]::GetFullPath^((Join-Path $local 'Temp'^)^).TrimEnd^([char]92^)^){throw 'Component log destination root is invalid.'};$destination=[IO.Path]::GetFullPath^((Join-Path $targetRoot $name^)^);if^([IO.Path]::GetDirectoryName^($destination^)-ine$targetRoot^){throw 'Component log destination escaped target Temp.'}
>> "%LOG_PUBLISHER_PS%" echo if^(Test-Path -LiteralPath $destination^){$item=Get-Item -LiteralPath $destination -Force;if^($item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Component log destination is unsafe.'}};$temporary=Join-Path $targetRoot ^('.'+$name+'.'+[guid]::NewGuid^(^).ToString^('N'^)+'.tmp'^)
>> "%LOG_PUBLISHER_PS%" echo $input=[IO.FileStream]::new^($source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite^);try{$output=[IO.FileStream]::new^($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read^);try{$input.CopyTo^($output^);$output.Flush^($true^)}finally{$output.Dispose^(^)}}finally{$input.Dispose^(^)};try{if^(Test-Path -LiteralPath $destination^){[IO.File]::Delete^($destination^)};[IO.File]::Move^($temporary,$destination^);if^(-not[IO.File]::Exists^($destination^)-or^([IO.File]::GetAttributes^($destination^)-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Component log publication did not verify.'}}finally{if^(Test-Path -LiteralPath $temporary^){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
call :run_medium_worker "%LOG_PUBLISHER_PS%" 60 >nul 2>nul
set "LOG_PUBLISH_EXIT=%ERRORLEVEL%"
del "%LOG_PUBLISHER_PS%" >nul 2>nul
set "LOG_PUBLISHER_PS="
set "CP_LOG_NAME="
set "CP_LOG_SOURCE="
exit /b %LOG_PUBLISH_EXIT%

:commit_state_metadata
set "STATE_COMMIT_PS=%CP_RUNTIME_TEMP%\cp_setup_state_commit_%RANDOM%_%RANDOM%.ps1"
> "%STATE_COMMIT_PS%" echo $ErrorActionPreference='Stop'
>> "%STATE_COMMIT_PS%" echo $allowed=@^('Path.HadValue','Path.Entries','Path.Before','Path.Before.Kind','Path.Written','Path.Written.Kind','AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','AutoRun.Entry','AutoRun.Written','AutoRun.Written.Kind','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','Console.VirtualTerminal.Written','Console.VirtualTerminal.Written.Kind','Acl.SourceArchive.Hash','Config.Managed','Config.MutationStarted','Snapshot.Complete','NvimData.Existed','Nvim.BootstrapStarted','Mason.Packages.Before','Mason.Packages','Mason.Inventory.Frozen','JdtlsWorkspace.Existed','JdtlsWorkspace.Path','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^)
>> "%STATE_COMMIT_PS%" echo $requested=@^($env:STATE_METADATA_NAMES.Split^([char]';',[StringSplitOptions]::RemoveEmptyEntries^)^)
>> "%STATE_COMMIT_PS%" echo if ^(-not $requested.Count -or @^($requested ^| Where-Object { $_ -notin $allowed -and $_ -notmatch '^^Env\.[A-Z0-9_]+\.(?:HadValue^|Before^|Before\.Kind^|Written^|Written\.Kind^)$' }^).Count^) { throw 'Unsafe protected-state commit request.' }
>> "%STATE_COMMIT_PS%" echo $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$true^); if ^(-not $key^) { exit 0 }
>> "%STATE_COMMIT_PS%" echo try { foreach ^($name in $requested^) { $key.DeleteValue^($name,$false^) }; $remaining=@^($key.GetValueNames^(^) ^| Where-Object { $requested -contains $_ }^); if ^($remaining.Count^) { throw ^('Protected-state commit verification failed: '+^($remaining -join ', '^)^) } } finally { $key.Dispose^(^) }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%STATE_COMMIT_PS%" >nul 2>nul
set "STATE_COMMIT_EXIT=%ERRORLEVEL%"
del "%STATE_COMMIT_PS%" >nul 2>nul
exit /b %STATE_COMMIT_EXIT%

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
    set "STATE_CHECK_EXIT=!ERRORLEVEL!"
    if "!STATE_CHECK_EXIT!"=="2" (
        echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for %%V.
        exit /b 1
    )
    if "!STATE_CHECK_EXIT!"=="0" echo [%ESC%[38;5;114mFOUND%ESC%[0m] %%V installed by this setup
)
exit /b 0

:remove_setup_configuration
call :remove_managed_mason_packages
if errorlevel 1 exit /b 1
call :remove_nvim_generated_data
if errorlevel 1 exit /b 1
call :remove_created_artifacts
if errorlevel 1 exit /b 1
set "CONFIG_ROOT=%ROOT%"
set "MACROS=%ROOT%\scripts\cp_macros"
set "CONFIG_CLEANUP_PS=%CP_RUNTIME_TEMP%\cp_setup_config_cleanup_%RANDOM%_%RANDOM%.ps1"
> "%CONFIG_CLEANUP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%CONFIG_CLEANUP_PS%" echo $option = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%CONFIG_CLEANUP_PS%" echo $users = [Microsoft.Win32.Registry]::Users
>> "%CONFIG_CLEANUP_PS%" echo $state = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^)
>> "%CONFIG_CLEANUP_PS%" echo if ^(-not $state^) { exit 0 }
>> "%CONFIG_CLEANUP_PS%" echo try {
>> "%CONFIG_CLEANUP_PS%" echo     $getRaw = { param^($key,$name^) if ^(-not $key^) { return [pscustomobject]@{ Exists=$false; Value=$null; Kind=$null } }; $names=@^($key.GetValueNames^(^)^); if ^($names -notcontains $name^) { return [pscustomobject]@{ Exists=$false; Value=$null; Kind=$null } }; [pscustomobject]@{ Exists=$true; Value=$key.GetValue^($name,$null,$option^); Kind=[int]$key.GetValueKind^($name^) } }
>> "%CONFIG_CLEANUP_PS%" echo     $setRaw = { param^($key,$name,$value,$kind^) if ^($kind -notin @^(1,2^)^) { throw ^('Unsafe registry kind for '+$name^) }; $key.SetValue^($name,[string]$value,[Microsoft.Win32.RegistryValueKind]$kind^) }
>> "%CONFIG_CLEANUP_PS%" echo     $deleteMetadata = { param^([string[]]$names^) }
>> "%CONFIG_CLEANUP_PS%" echo     $validateSnapshot = { param^([string]$prefix,[int]$valueKind=1,[int[]]$originalKinds=@^(1,2^)^) $had=^& $getRaw $state ^($prefix+'.HadValue'^); $before=^& $getRaw $state ^($prefix+'.Before'^); $beforeKind=^& $getRaw $state ^($prefix+'.Before.Kind'^); if ^(-not $had.Exists^) { if ^($before.Exists -or $beforeKind.Exists^) { throw ^('Incomplete snapshot metadata for '+$prefix^) }; return [pscustomobject]@{ Exists=$false; HadValue=0; Before=$null; BeforeKind=$null } }; if ^([int]$had.Kind -ne 4 -or [int]$had.Value -notin @^(0,1^)^) { throw ^('Unsafe snapshot metadata for '+$prefix^) }; if ^([int]$had.Value -eq 1^) { if ^(-not $before.Exists -or -not $beforeKind.Exists -or [int]$before.Kind -ne $valueKind -or [int]$beforeKind.Kind -ne 4 -or [int]$beforeKind.Value -notin $originalKinds^) { throw ^('Incomplete snapshot metadata for '+$prefix^) } } elseif ^($before.Exists -or $beforeKind.Exists^) { throw ^('Unexpected snapshot metadata for '+$prefix^) }; [pscustomobject]@{ Exists=$true; HadValue=[int]$had.Value; Before=$before; BeforeKind=$beforeKind } }
>> "%CONFIG_CLEANUP_PS%" echo     $envKey = $users.OpenSubKey^($env:CP_SETUP_TARGET_SID+'\Environment',$true^)
>> "%CONFIG_CLEANUP_PS%" echo     try {
>> "%CONFIG_CLEANUP_PS%" echo         foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) {
>> "%CONFIG_CLEANUP_PS%" echo             $prefix='Env.'+$name; $metadata=@^($prefix+'.HadValue',$prefix+'.Before',$prefix+'.Before.Kind',$prefix+'.Written',$prefix+'.Written.Kind'^); $snapshot=^& $validateSnapshot $prefix; $written=^& $getRaw $state ^($prefix+'.Written'^); $writtenKind=^& $getRaw $state ^($prefix+'.Written.Kind'^)
>> "%CONFIG_CLEANUP_PS%" echo             if ^(-not $written.Exists -and -not $writtenKind.Exists^) { if ^($snapshot.Exists^) { ^& $deleteMetadata $metadata }; continue }; if ^(-not $written.Exists -or -not $writtenKind.Exists -or -not $snapshot.Exists^) { throw ^('Incomplete environment ownership metadata for '+$name^) }
>> "%CONFIG_CLEANUP_PS%" echo             $wk=[int]$writtenKind.Value; if ^([int]$written.Kind -ne 1 -or [int]$writtenKind.Kind -ne 4 -or $wk -notin @^(1,2^)^) { throw ^('Unsafe written registry metadata for '+$name^) }; $current=^& $getRaw $envKey $name
>> "%CONFIG_CLEANUP_PS%" echo             $expectedExists=$current.Exists; $expectedValue=$current.Value; $expectedKind=$current.Kind; if ^($current.Exists -and [string]$current.Value -ceq [string]$written.Value -and [int]$current.Kind -eq $wk^) { if ^($snapshot.HadValue -eq 1^) { ^& $setRaw $envKey $name $snapshot.Before.Value ^([int]$snapshot.BeforeKind.Value^); $expectedExists=$true; $expectedValue=$snapshot.Before.Value; $expectedKind=[int]$snapshot.BeforeKind.Value } else { $envKey.DeleteValue^($name,$false^); $expectedExists=$false } }
>> "%CONFIG_CLEANUP_PS%" echo             $after=^& $getRaw $envKey $name; if ^($expectedExists^) { if ^(-not $after.Exists -or [string]$after.Value -cne [string]$expectedValue -or [int]$after.Kind -ne [int]$expectedKind^) { throw ^('Environment cleanup verification failed for '+$name^) } } elseif ^($after.Exists^) { throw ^('Environment cleanup verification failed for '+$name^) }
>> "%CONFIG_CLEANUP_PS%" echo             ^& $deleteMetadata $metadata
>> "%CONFIG_CLEANUP_PS%" echo         }
>> "%CONFIG_CLEANUP_PS%" echo         $pathMetadata=@^('Path.HadValue','Path.Entries','Path.Before','Path.Before.Kind','Path.Written','Path.Written.Kind'^); $pathSnapshot=^& $validateSnapshot 'Path'; $pathWritten=^& $getRaw $state 'Path.Written'; $pathWrittenKind=^& $getRaw $state 'Path.Written.Kind'; $entries=^& $getRaw $state 'Path.Entries'; $pathMutation=$pathWritten.Exists -or $pathWrittenKind.Exists -or $entries.Exists
>> "%CONFIG_CLEANUP_PS%" echo         if ^(-not $pathMutation^) { if ^($pathSnapshot.Exists^) { ^& $deleteMetadata $pathMetadata } } else { if ^(-not $pathWritten.Exists -or -not $pathWrittenKind.Exists -or -not $entries.Exists -or -not $pathSnapshot.Exists^) { throw 'Incomplete Path ownership metadata' }; $wk=[int]$pathWrittenKind.Value; if ^([int]$pathWritten.Kind -ne 1 -or [int]$pathWrittenKind.Kind -ne 4 -or $wk -notin @^(1,2^) -or [int]$entries.Kind -ne 7^) { throw 'Unsafe Path ownership metadata' }; $current=^& $getRaw $envKey 'Path'; $expectedExists=$current.Exists; $expectedValue=$current.Value; $expectedKind=$current.Kind; if ^($current.Exists -and [string]$current.Value -ceq [string]$pathWritten.Value -and [int]$current.Kind -eq $wk^) { if ^($pathSnapshot.HadValue -eq 1^) { ^& $setRaw $envKey 'Path' $pathSnapshot.Before.Value ^([int]$pathSnapshot.BeforeKind.Value^); $expectedExists=$true; $expectedValue=$pathSnapshot.Before.Value; $expectedKind=[int]$pathSnapshot.BeforeKind.Value } else { $envKey.DeleteValue^('Path',$false^); $expectedExists=$false } } elseif ^($current.Exists^) { if ^([int]$current.Kind -notin @^(1,2^)^) { throw 'Unsafe current registry kind for Path' }; $owned=@^($entries.Value ^| Where-Object { $_ } ^| ForEach-Object { ^([string]$_^).Trim^(^).TrimEnd^('\'^) }^); $parts=@^([string]$current.Value -split ';',-1^); $kept=@^($parts ^| Where-Object { $owned -inotcontains ^([string]$_^).Trim^(^).TrimEnd^('\'^) }^); $expectedValue=$kept -join ';'; $expectedKind=[int]$current.Kind; ^& $setRaw $envKey 'Path' $expectedValue $expectedKind }; $after=^& $getRaw $envKey 'Path'; if ^($expectedExists^) { if ^(-not $after.Exists -or [string]$after.Value -cne [string]$expectedValue -or [int]$after.Kind -ne [int]$expectedKind^) { throw 'Path cleanup verification failed' } } elseif ^($after.Exists^) { throw 'Path cleanup verification failed' }; ^& $deleteMetadata $pathMetadata }
>> "%CONFIG_CLEANUP_PS%" echo     } finally { if ^($envKey^) { $envKey.Dispose^(^) } }
>> "%CONFIG_CLEANUP_PS%" echo     $autoMetadata=@^('AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','AutoRun.Entry','AutoRun.Written','AutoRun.Written.Kind'^); $autoSnapshot=^& $validateSnapshot 'AutoRun'; $autoWritten=^& $getRaw $state 'AutoRun.Written'; $autoWrittenKind=^& $getRaw $state 'AutoRun.Written.Kind'; $autoEntry=^& $getRaw $state 'AutoRun.Entry'; $autoMutation=$autoWritten.Exists -or $autoWrittenKind.Exists -or $autoEntry.Exists
>> "%CONFIG_CLEANUP_PS%" echo     if ^(-not $autoMutation^) { if ^($autoSnapshot.Exists^) { ^& $deleteMetadata $autoMetadata } } else { if ^(-not $autoWritten.Exists -or -not $autoWrittenKind.Exists -or -not $autoEntry.Exists -or -not $autoSnapshot.Exists^) { throw 'Incomplete AutoRun ownership metadata' }; $autoKey=$users.OpenSubKey^($env:CP_SETUP_TARGET_SID+'\Software\Microsoft\Command Processor',$true^); try { $wk=[int]$autoWrittenKind.Value; $owned=[string]$autoEntry.Value; if ^([int]$autoWritten.Kind -ne 1 -or [int]$autoWrittenKind.Kind -ne 4 -or [int]$autoEntry.Kind -ne 1 -or $wk -notin @^(1,2^) -or -not $owned^) { throw 'Unsafe AutoRun ownership metadata' }; $current=^& $getRaw $autoKey 'AutoRun'; $expectedExists=$current.Exists; $expectedValue=$current.Value; $expectedKind=$current.Kind; if ^($current.Exists -and [string]$current.Value -ceq [string]$autoWritten.Value -and [int]$current.Kind -eq $wk^) { if ^($autoSnapshot.HadValue -eq 1^) { ^& $setRaw $autoKey 'AutoRun' $autoSnapshot.Before.Value ^([int]$autoSnapshot.BeforeKind.Value^); $expectedExists=$true; $expectedValue=$autoSnapshot.Before.Value; $expectedKind=[int]$autoSnapshot.BeforeKind.Value } else { $autoKey.DeleteValue^('AutoRun',$false^); $expectedExists=$false } } elseif ^($current.Exists^) { if ^([int]$current.Kind -notin @^(1,2^)^) { throw 'Unsafe current registry kind for AutoRun' }; $text=[string]$current.Value; $offset=0; $index=-1; while ^($offset -le $text.Length-$owned.Length^) { $candidate=$text.IndexOf^($owned,$offset,[StringComparison]::OrdinalIgnoreCase^); if ^($candidate -lt 0^) { break }; $leftOk=$candidate -eq 0 -or ^($candidate -ge 3 -and $text.Substring^($candidate-3,3^) -ceq ' ^& '^); $right=$candidate+$owned.Length; $rightOk=$right -eq $text.Length -or ^($right+3 -le $text.Length -and $text.Substring^($right,3^) -ceq ' ^& '^); if ^($leftOk -and $rightOk^) { $index=$candidate; break }; $offset=$candidate+1 }; if ^($index -ge 0^) { $right=$index+$owned.Length; if ^($index -ge 3 -and $text.Substring^($index-3,3^) -ceq ' ^& '^ ) { $kept=$text.Remove^($index-3,$owned.Length+3^) } elseif ^($right+3 -le $text.Length -and $text.Substring^($right,3^) -ceq ' ^& '^ ) { $kept=$text.Remove^($index,$owned.Length+3^) } else { $kept='' }; if ^($kept.Length^) { ^& $setRaw $autoKey 'AutoRun' $kept ^([int]$current.Kind^); $expectedValue=$kept; $expectedKind=[int]$current.Kind } else { $autoKey.DeleteValue^('AutoRun',$false^); $expectedExists=$false } } }; $after=^& $getRaw $autoKey 'AutoRun'; if ^($expectedExists^) { if ^(-not $after.Exists -or [string]$after.Value -cne [string]$expectedValue -or [int]$after.Kind -ne [int]$expectedKind^) { throw 'AutoRun cleanup verification failed' } } elseif ^($after.Exists^) { throw 'AutoRun cleanup verification failed' } } finally { if ^($autoKey^) { $autoKey.Dispose^(^) } }; ^& $deleteMetadata $autoMetadata }
>> "%CONFIG_CLEANUP_PS%" echo     $consoleMetadata=@^('Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','Console.VirtualTerminal.Written','Console.VirtualTerminal.Written.Kind'^); $consoleSnapshot=^& $validateSnapshot 'Console.VirtualTerminal' 4 @^(4^); $consoleWritten=^& $getRaw $state 'Console.VirtualTerminal.Written'; $consoleWrittenKind=^& $getRaw $state 'Console.VirtualTerminal.Written.Kind'; $consoleMutation=$consoleWritten.Exists -or $consoleWrittenKind.Exists
>> "%CONFIG_CLEANUP_PS%" echo     if ^(-not $consoleMutation^) { if ^($consoleSnapshot.Exists^) { ^& $deleteMetadata $consoleMetadata } } else { if ^(-not $consoleWritten.Exists -or -not $consoleWrittenKind.Exists -or -not $consoleSnapshot.Exists^) { throw 'Incomplete console ownership metadata' }; $wk=[int]$consoleWrittenKind.Value; if ^([int]$consoleWritten.Kind -ne 4 -or [int]$consoleWrittenKind.Kind -ne 4 -or $wk -ne 4^) { throw 'Unsafe console ownership metadata' }; $consoleKey=$users.OpenSubKey^($env:CP_SETUP_TARGET_SID+'\Console',$true^); if ^($consoleKey^) { try { $current=^& $getRaw $consoleKey 'VirtualTerminalLevel'; $expectedExists=$current.Exists; $expectedValue=$current.Value; $expectedKind=$current.Kind; if ^($current.Exists -and [int]$current.Kind -eq $wk -and [int64]$current.Value -eq [int64]$consoleWritten.Value^) { if ^($consoleSnapshot.HadValue -eq 1^) { $consoleKey.SetValue^('VirtualTerminalLevel',$consoleSnapshot.Before.Value,[Microsoft.Win32.RegistryValueKind][int]$consoleSnapshot.BeforeKind.Value^); $expectedExists=$true; $expectedValue=$consoleSnapshot.Before.Value; $expectedKind=[int]$consoleSnapshot.BeforeKind.Value } else { $consoleKey.DeleteValue^('VirtualTerminalLevel',$false^); $expectedExists=$false } }; $after=^& $getRaw $consoleKey 'VirtualTerminalLevel'; if ^($expectedExists^) { if ^(-not $after.Exists -or [int]$after.Kind -ne [int]$expectedKind -or [string]$after.Value -cne [string]$expectedValue^) { throw 'Console cleanup verification failed' } } elseif ^($after.Exists^) { throw 'Console cleanup verification failed' } } finally { $consoleKey.Dispose^(^) } }; ^& $deleteMetadata $consoleMetadata }
>> "%CONFIG_CLEANUP_PS%" echo     ^& $deleteMetadata @^('Acl.SourceArchive.Hash','Config.Managed','Config.MutationStarted','Snapshot.Complete'^)
>> "%CONFIG_CLEANUP_PS%" echo     # Protected metadata is committed only by the elevated phase after this worker succeeds.
>> "%CONFIG_CLEANUP_PS%" echo } finally { $state.Dispose^(^) }
>> "%CONFIG_CLEANUP_PS%" echo exit 0
set "CONFIG_CLEANUP_LOG=%CP_RUNTIME_TEMP%\cp_setup_config_cleanup.log"
del "%CONFIG_CLEANUP_LOG%" >nul 2>nul
call :run_medium_worker "%CONFIG_CLEANUP_PS%" 300 > "%CONFIG_CLEANUP_LOG%" 2>&1
set "CONFIG_CLEANUP_EXIT=!ERRORLEVEL!"
del "%CONFIG_CLEANUP_PS%" >nul 2>nul
call :publish_component_log "cp_setup_config_cleanup.log"
set "CONFIG_CLEANUP_PUBLISH_EXIT=!ERRORLEVEL!"
if "!CONFIG_CLEANUP_EXIT!"=="0" if not "!CONFIG_CLEANUP_PUBLISH_EXIT!"=="0" set "CONFIG_CLEANUP_EXIT=1"
if not "!CONFIG_CLEANUP_EXIT!"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup configuration cleanup failed.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_config_cleanup.log
    exit /b 1
)
del "%CONFIG_CLEANUP_LOG%" >nul 2>nul
set "STATE_METADATA_NAMES=Path.HadValue;Path.Entries;Path.Before;Path.Before.Kind;Path.Written;Path.Written.Kind;AutoRun.HadValue;AutoRun.Before;AutoRun.Before.Kind;AutoRun.Entry;AutoRun.Written;AutoRun.Written.Kind;Console.VirtualTerminal.HadValue;Console.VirtualTerminal.Before;Console.VirtualTerminal.Before.Kind;Console.VirtualTerminal.Written;Console.VirtualTerminal.Written.Kind;Acl.SourceArchive.Hash;Config.Managed;Config.MutationStarted;Snapshot.Complete;Env.XDG_CONFIG_HOME.HadValue;Env.XDG_CONFIG_HOME.Before;Env.XDG_CONFIG_HOME.Before.Kind;Env.XDG_CONFIG_HOME.Written;Env.XDG_CONFIG_HOME.Written.Kind;Env.CP_SETUP_ROOT.HadValue;Env.CP_SETUP_ROOT.Before;Env.CP_SETUP_ROOT.Before.Kind;Env.CP_SETUP_ROOT.Written;Env.CP_SETUP_ROOT.Written.Kind;Env.CP_PYTHON.HadValue;Env.CP_PYTHON.Before;Env.CP_PYTHON.Before.Kind;Env.CP_PYTHON.Written;Env.CP_PYTHON.Written.Kind;Env.CP_GPP.HadValue;Env.CP_GPP.Before;Env.CP_GPP.Before.Kind;Env.CP_GPP.Written;Env.CP_GPP.Written.Kind;Env.CP_JAVAC.HadValue;Env.CP_JAVAC.Before;Env.CP_JAVAC.Before.Kind;Env.CP_JAVAC.Written;Env.CP_JAVAC.Written.Kind;Env.CP_JAVA.HadValue;Env.CP_JAVA.Before;Env.CP_JAVA.Before.Kind;Env.CP_JAVA.Written;Env.CP_JAVA.Written.Kind"
call :commit_state_metadata
if errorlevel 1 exit /b %ERRORLEVEL%
exit /b 0

:remove_external_components
call :state_has "Winget.Git"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Git.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_git
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Git" "git"
)

call :state_has "Winget.Neovim"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Neovim.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "Neovim" "Neovim.Neovim" "nvim" "Winget.Neovim" "Neovim and generated LazyVim data"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Neovim" "nvim"
)

call :state_has "Winget.Node"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Node.js LTS.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "Node.js LTS" "OpenJS.NodeJS.LTS" "node" "Winget.Node"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Node.js LTS" "node"
)

call :state_has "Winget.JDK"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for JDK.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "JDK" "EclipseAdoptium.Temurin.21.JDK" "javac" "Winget.JDK"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "JDK" "javac"
)

call :state_has "Winget.MSYS2"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for MSYS2.
    exit /b 1
)
if errorlevel 1 (
    call :report_unmanaged_msys2
    goto maybe_pacman
)
call :has_setup_managed_msys2
if errorlevel 2 exit /b 1
if errorlevel 1 (
    call :clear_state "Winget.MSYS2"
    if errorlevel 1 exit /b 1
    call :print_missing "MSYS2"
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
if errorlevel 1 exit /b 1
call :clear_pacman_state
if errorlevel 1 exit /b 1
echo [%ESC%[38;5;114mUNINSTALLED%ESC%[0m] MSYS2
echo.
exit /b 0

:maybe_pacman
call :state_has "Pacman.Toolchain"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for the MSYS2 CP toolchain.
    exit /b 1
)
if errorlevel 1 exit /b 0
call :has_pacman_toolchain
if errorlevel 2 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 packages because exact setup ownership is unavailable.
    set "CAN_REMOVE_REPO=0"
    echo.
    exit /b 0
)
if errorlevel 1 (
    call :clear_pacman_state
    if errorlevel 1 exit /b 1
    call :print_missing "MSYS2 CP toolchain"
    echo.
    exit /b 0
)
call :uninstall_pacman_toolchain
exit /b %ERRORLEVEL%

:remove_all_external_components
call :state_has "Winget.Git"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Git.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_git
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Git" "git"
)

call :state_has "Winget.Neovim"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Neovim.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "Neovim" "Neovim.Neovim" "nvim" "Winget.Neovim" "Neovim and generated LazyVim data"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Neovim" "nvim"
)

call :state_has "Winget.Node"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for Node.js LTS.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "Node.js LTS" "OpenJS.NodeJS.LTS" "node" "Winget.Node"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "Node.js LTS" "node"
)

call :state_has "Winget.JDK"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for JDK.
    exit /b 1
)
if not errorlevel 1 (
    call :uninstall_winget_component "JDK" "EclipseAdoptium.Temurin.21.JDK" "javac" "Winget.JDK"
    if errorlevel 1 exit /b 1
) else (
    call :report_unmanaged_command "JDK" "javac"
)

call :state_has "Winget.MSYS2"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for MSYS2.
    exit /b 1
)
if not errorlevel 1 (
    call :has_setup_managed_msys2
    if errorlevel 2 exit /b 1
    if errorlevel 1 (
        call :clear_state "Winget.MSYS2"
        if errorlevel 1 exit /b 1
        call :print_missing "MSYS2"
        echo.
    ) else (
        call :uninstall_msys2
        if errorlevel 1 exit /b 1
        call :clear_state "Winget.MSYS2"
        if errorlevel 1 exit /b 1
        call :clear_pacman_state
        if errorlevel 1 exit /b 1
        echo [%ESC%[38;5;114mUNINSTALLED%ESC%[0m] MSYS2
        echo.
        exit /b 0
    )
)

call :report_unmanaged_msys2

call :state_has "Pacman.Toolchain"
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read for the MSYS2 CP toolchain.
    exit /b 1
)
if not errorlevel 1 (
    call :find_msys2_shell
    if errorlevel 2 (
        echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 path could not be verified safely.
        exit /b 1
    )
    if errorlevel 1 (
        call :clear_pacman_state
        if errorlevel 1 exit /b 1
        call :print_missing "MSYS2 CP toolchain"
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
    if /I "%~4"=="Winget.Neovim" (
        call :remove_managed_mason_packages
        if errorlevel 1 exit /b 1
        call :remove_nvim_generated_data
        if errorlevel 1 exit /b 1
    )
    call :clear_state "%~4"
    if errorlevel 1 exit /b 1
    call :print_missing "%~1"
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
if /I "%~4"=="Winget.Neovim" (
    call :remove_nvim_generated_data
    if errorlevel 1 exit /b 1
)
call :clear_state "%~4"
if errorlevel 1 exit /b 1
echo [%ESC%[38;5;114mUNINSTALLED%ESC%[0m] %~1
echo.
exit /b 0

:report_unmanaged_command
set "SEARCH_COMMAND_INPUT="%WHERE_EXE%" %~2"
call :search_command "%~1" "@env" "UNMANAGED_COMPONENT_PATH"
if errorlevel 1 (
    call :print_missing "%~1"
    echo.
    exit /b 0
)
echo [%ESC%[38;5;244mKEPT%ESC%[0m] %~1 was not installed by CP setup.
echo.
exit /b 0

:report_unmanaged_msys2
call :detect_msys2_shell
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
set "UNINSTALL_CMD="%WINGET%" uninstall --id %~2 --exact --source winget --scope machine --disable-interactivity --silent"
for %%I in ("%WINGET%") do set "SPIN_WORKDIR=%%~dpI"
call :run_command_spinner "%~1" "" "%CP_VISIBLE_TEMP%\cp_setup_winget_uninstall.log" "UNINSTALLING" "UNINSTALLED" "1" "%~3"
set "SPIN_WORKDIR="
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] winget uninstall failed for %~1.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_winget_uninstall.log
    exit /b 1
)
call :winget_has_package "%~2"
if errorlevel 2 exit /b 1
if not errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] %~1 remains registered with winget.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_winget_uninstall.log
    exit /b 1
)
exit /b 0

:uninstall_msys2
call :load_managed_msys2_root
if errorlevel 2 exit /b 1
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 path metadata is missing.
    exit /b 1
)

set "MANAGED_MSYS2_UNINSTALLER=!MANAGED_MSYS2_ROOT!\uninstall.exe"
if not exist "!MANAGED_MSYS2_UNINSTALLER!" goto uninstall_msys2_winget
if exist "!MANAGED_MSYS2_UNINSTALLER!\" goto uninstall_msys2_winget
call :validate_native_msys2_uninstaller
if errorlevel 1 goto uninstall_msys2_winget

set "MSYS2_ARTIFACT_SNAPSHOT=%CP_RUNTIME_TEMP%\cp_setup_msys2_artifacts_%RANDOM%_%RANDOM%.txt"
call :capture_native_msys2_artifacts "before" >> "%CP_RUNTIME_TEMP%\cp_setup_msys2_uninstall.log" 2>&1
if errorlevel 1 goto native_msys2_uninstall_failed
set "UNINSTALL_CMD="!MANAGED_MSYS2_UNINSTALLER!" pr --confirm-command"
set "SPIN_WORKDIR=!MANAGED_MSYS2_ROOT!"
call :run_command_spinner "MSYS2" "" "%CP_VISIBLE_TEMP%\cp_setup_msys2_uninstall.log" "UNINSTALLING" "UNINSTALLED" "1" "1"
set "NATIVE_MSYS2_EXIT=!ERRORLEVEL!"
set "SPIN_WORKDIR="
call :capture_native_msys2_artifacts "after" >> "%CP_RUNTIME_TEMP%\cp_setup_msys2_uninstall.log" 2>&1
set "NATIVE_ARTIFACT_EXIT=!ERRORLEVEL!"
call :publish_component_log "cp_setup_msys2_uninstall.log"
set "NATIVE_LOG_PUBLISH_EXIT=!ERRORLEVEL!"
if "!NATIVE_ARTIFACT_EXIT!"=="0" if not "!NATIVE_LOG_PUBLISH_EXIT!"=="0" set "NATIVE_ARTIFACT_EXIT=1"
del "!MSYS2_ARTIFACT_SNAPSHOT!" >nul 2>nul
set "MSYS2_ARTIFACT_SNAPSHOT="
if not "!NATIVE_MSYS2_EXIT!"=="0" goto native_msys2_uninstall_failed
if not "!NATIVE_ARTIFACT_EXIT!"=="0" goto native_msys2_uninstall_failed
goto verify_msys2_uninstall

:native_msys2_uninstall_failed
call :publish_component_log "cp_setup_msys2_uninstall.log" >nul 2>nul
if defined MSYS2_ARTIFACT_SNAPSHOT del "!MSYS2_ARTIFACT_SNAPSHOT!" >nul 2>nul
set "MSYS2_ARTIFACT_SNAPSHOT="
echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 native uninstall failed.
echo Log: %CP_VISIBLE_TEMP%\cp_setup_msys2_uninstall.log
exit /b 1

:uninstall_msys2_winget
if not defined MANAGED_MSYS2_ROOT set "MANAGED_MSYS2_ROOT=C:\msys64"
call :winget_has_package "MSYS2.MSYS2"
if errorlevel 2 exit /b 1
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 has no usable native uninstaller and is not registered with winget.
    exit /b 1
)
call :uninstall_winget_now "MSYS2" "MSYS2.MSYS2" "1"
if errorlevel 1 exit /b 1

:verify_msys2_uninstall
call :verify_msys2_removed
if errorlevel 1 exit /b 1
exit /b 0

:has_setup_managed_msys2
call :load_managed_msys2_root
if errorlevel 2 exit /b 2
if errorlevel 1 exit /b 2
if exist "!MANAGED_MSYS2_ROOT!\" exit /b 0

:has_setup_managed_msys2_winget
call :winget_has_package "MSYS2.MSYS2"
exit /b %ERRORLEVEL%

:load_managed_msys2_root
set "MANAGED_MSYS2_ROOT="
set "MSYS_ROOT_FILE=%CP_RUNTIME_TEMP%\cp_setup_msys_root_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try{$k=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default).OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false);if(-not $k){exit 1};$v=[string]$k.GetValue('Winget.MSYS2.Path',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=[IO.Path]::GetFullPath($v).TrimEnd('\');if([IO.Path]::GetFileName($p) -cne 'msys2_shell.cmd'){exit 1};[IO.File]::WriteAllText($env:MSYS_ROOT_FILE,[IO.Path]::GetDirectoryName($p),[Text.Encoding]::ASCII);$k.Dispose()}catch{exit 1}" >nul 2>nul
for /F "usebackq delims=" %%P in ("%MSYS_ROOT_FILE%") do if not defined MANAGED_MSYS2_ROOT set "MANAGED_MSYS2_ROOT=%%P"
del "%MSYS_ROOT_FILE%" >nul 2>nul
if defined MANAGED_MSYS2_ROOT exit /b 0
exit /b 1

:validate_native_msys2_uninstaller
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $root=[IO.Path]::GetFullPath($env:MANAGED_MSYS2_ROOT).TrimEnd('\'); $candidate=[IO.Path]::GetFullPath($env:MANAGED_MSYS2_UNINSTALLER); if ($root -ine 'C:\msys64' -or $candidate -ine (Join-Path $root 'uninstall.exe') -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { exit 1 }; $trustedOwners=@('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $untrusted=@('S-1-1-0','S-1-5-11','S-1-5-32-545',$env:CP_SETUP_TARGET_SID); $mask=[Security.AccessControl.FileSystemRights]::WriteData -bor [Security.AccessControl.FileSystemRights]::AppendData -bor [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor [Security.AccessControl.FileSystemRights]::WriteAttributes -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership; foreach ($path in @($root,$candidate)) { $item=Get-Item -LiteralPath $path -Force; if ([bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 }; $acl=Get-Acl -LiteralPath $path; $owner=$acl.Owner; try { $ownerSid=([Security.Principal.NTAccount]$owner).Translate([Security.Principal.SecurityIdentifier]).Value } catch { $ownerSid=$owner }; if ($trustedOwners -notcontains $ownerSid) { exit 1 }; foreach ($ace in $acl.Access) { if ($ace.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or -not ([int64]$ace.FileSystemRights -band [int64]$mask)) { continue }; try { $sid=$ace.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { $sid=[string]$ace.IdentityReference }; if ($untrusted -contains $sid) { exit 1 } } }; exit 0 } catch { exit 1 }" >nul 2>nul
exit /b %ERRORLEVEL%

:capture_native_msys2_artifacts
set "NATIVE_ARTIFACT_PHASE=%~1"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$lines=[IO.File]::ReadAllLines($env:CP_UNINSTALL_SCRIPT);$first=[Array]::IndexOf($lines,'::__CP_NATIVE_ARTIFACTS_BEGIN__');$last=[Array]::IndexOf($lines,'::__CP_NATIVE_ARTIFACTS_END__');if($first-lt 0-or$last-le$first){throw 'Missing native artifact inventory block.'};$source=for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw 'Malformed native artifact inventory block.'};$lines[$i].Substring(2)};&([scriptblock]::Create($source-join[Environment]::NewLine))"
set "NATIVE_ARTIFACT_EXIT=%ERRORLEVEL%"
set "NATIVE_ARTIFACT_PHASE="
exit /b %NATIVE_ARTIFACT_EXIT%

:verify_msys2_removed
if defined MANAGED_MSYS2_ROOT (
    call :wait_for_msys2_root_removal
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 files remain at !MANAGED_MSYS2_ROOT!
        exit /b 1
    )
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

:wait_for_msys2_root_removal
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$path=$env:MANAGED_MSYS2_ROOT; for ($attempt=0; $attempt -lt 60; $attempt++) { if (-not (Test-Path -LiteralPath $path)) { exit 0 }; Start-Sleep -Milliseconds 500 }; exit 1" >nul 2>nul
exit /b %ERRORLEVEL%

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
if errorlevel 2 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be read safely for the MSYS2 CP toolchain.
    exit /b 1
)
if errorlevel 1 (
    echo [%ESC%[38;5;244mKEPT%ESC%[0m] MSYS2 packages because exact setup ownership is unavailable.
    set "CAN_REMOVE_REPO=0"
    exit /b 0
)
    call :find_msys2_shell
    if errorlevel 2 (
        echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 path could not be verified safely.
        exit /b 1
    )
    if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was not found; the toolchain cannot be removed with pacman.
    exit /b 1
)
set "PACMAN_COMMAND=p=$(mktemp) || exit 2; pacman -Qq >$p || { s=$?; rm -f $p; exit $s; }; set --; for package in %PACMAN_PACKAGES%; do grep -Fxq -- $package $p; s=$?; case $s in 0) set -- $@ $package;; 1);; *) rm -f $p; exit $s;; esac; done; rm -f $p; test $# -eq 0 || pacman -Rns --noconfirm -- $@"
call :run_pacman_spinner "UNINSTALLING" "UNINSTALLED" "1"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain uninstall failed.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_pacman_uninstall.log
    exit /b 1
)
call :verify_pacman_packages_removed
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed MSYS2 packages remain installed or could not be verified.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_pacman_uninstall.log
    exit /b 1
)
call :clear_pacman_state
if errorlevel 1 exit /b 1
echo [%ESC%[38;5;114mUNINSTALLED%ESC%[0m] MSYS2 CP toolchain via pacman
echo.
exit /b 0

:verify_pacman_packages_removed
setlocal EnableExtensions EnableDelayedExpansion
for %%I in ("%MSYS2_SHELL%") do set "PACMAN_VERIFY_BASH=%%~dpIusr\bin\bash.exe"
if not exist "!PACMAN_VERIFY_BASH!" endlocal & exit /b 1
set "PACMAN_VERIFY_LIST=%CP_RUNTIME_TEMP%\cp_setup_pacman_verify_%RANDOM%_%RANDOM%.txt"
set "SILENT_COMMAND="!PACMAN_VERIFY_BASH!" -lc "pacman -Qq""
set "SILENT_OUTPUT=!PACMAN_VERIFY_LIST!"
set "SILENT_ERROR=%CP_VISIBLE_TEMP%\cp_setup_pacman_uninstall.log"
set "SILENT_TIMEOUT_SECONDS=120"
call :run_silent_command
set "PACMAN_VERIFY_EXIT=!ERRORLEVEL!"
if "!PACMAN_VERIFY_EXIT!"=="124" (
    del "!PACMAN_VERIFY_LIST!" >nul 2>nul
    endlocal & set "UNINSTALL_TIMEOUT_SEEN=1" & exit /b 124
)
if not "!PACMAN_VERIFY_EXIT!"=="0" (
    del "!PACMAN_VERIFY_LIST!" >nul 2>nul
    endlocal & exit /b 1
)
set "PACMAN_PACKAGES_REMAIN=0"
for %%P in (%PACMAN_PACKAGES%) do (
    "%FINDSTR_EXE%" /X /L /C:"%%P" "!PACMAN_VERIFY_LIST!" >nul
    if not errorlevel 1 set "PACMAN_PACKAGES_REMAIN=1"
)
del "!PACMAN_VERIFY_LIST!" >nul 2>nul
if "!PACMAN_PACKAGES_REMAIN!"=="1" endlocal & exit /b 1
endlocal & exit /b 0

:run_silent_command
for %%L in ("%SILENT_ERROR%") do set "SILENT_ERROR_NAME=%%~nxL"
set "SILENT_ERROR=%CP_RUNTIME_TEMP%\%SILENT_ERROR_NAME%"
set "SILENT_PS=%CP_RUNTIME_TEMP%\cp_setup_silent_%RANDOM%_%RANDOM%.ps1"
> "%SILENT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SILENT_PS%" echo . $env:PROCESS_TREE_PS
>> "%SILENT_PS%" echo $wrapper=Join-Path $env:CP_RUNTIME_TEMP ^('cp_setup_silent_'+[guid]::NewGuid^(^).ToString^('N'^)+'.cmd'^); $q=[char]34
>> "%SILENT_PS%" echo [int]$timeout=0; if ^(-not [int]::TryParse^($env:SILENT_TIMEOUT_SECONDS,[ref]$timeout^) -or $timeout -lt 1^) { $timeout=120 }
>> "%SILENT_PS%" echo try { [IO.File]::WriteAllLines^($wrapper,@^('@echo off','set "MSYSTEM=MINGW64"','set "CHERE_INVOKING=enabled_from_arguments"' ,^('call '+$env:SILENT_COMMAND+' 1^>'+$q+$env:SILENT_OUTPUT+$q+' 2^>^>'+$q+$env:SILENT_ERROR+$q^),'exit /b %%ERRORLEVEL%%'^)^); $arguments='/d /s /c ""'+$wrapper+'""'; $process=Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:CP_RUNTIME_TEMP -WindowStyle Hidden -PassThru; exit ^(Wait-BoundedProcess $process ^($timeout*1000^) $env:TASKKILL_EXE^) } finally { Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue }
"%POWERSHELL_EXE%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SILENT_PS%" >nul 2>nul
set "SILENT_EXIT=%ERRORLEVEL%"
if "%SILENT_EXIT%"=="124" set "UNINSTALL_TIMEOUT_SEEN=1"
del "%SILENT_PS%" >nul 2>nul
call :publish_component_log "%SILENT_ERROR_NAME%"
set "SILENT_PUBLISH_EXIT=%ERRORLEVEL%"
if "%SILENT_EXIT%"=="0" if not "%SILENT_PUBLISH_EXIT%"=="0" set "SILENT_EXIT=1"
set "SILENT_ERROR_NAME="
exit /b %SILENT_EXIT%

:load_managed_pacman_packages
set "PACMAN_PACKAGES="
set "PACMAN_STATE_STATUS=ERROR"
set "PACMAN_STATE_FILE=%CP_RUNTIME_TEMP%\cp_setup_pacman_state_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try{$key=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default).OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false);if(-not $key){'STATUS=ABSENT'|Set-Content $env:PACMAN_STATE_FILE;exit};$n=@($key.GetValueNames());if($n -notcontains 'Pacman.Packages'){'STATUS=ABSENT'|Set-Content $env:PACMAN_STATE_FILE;exit};$a=@($env:PACMAN_PACKAGES_ALLOWED -split ' ');$p=@($key.GetValue('Pacman.Packages',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)|Where-Object{$_});if(-not $p.Count -or @($p|Where-Object{$a -notcontains $_}).Count){'STATUS=ERROR'|Set-Content $env:PACMAN_STATE_FILE;exit};@('STATUS=OK','PACKAGES='+($p -join ' '))|Set-Content $env:PACMAN_STATE_FILE;$key.Dispose()}catch{'STATUS=ERROR'|Set-Content $env:PACMAN_STATE_FILE}" >nul 2>nul
for /F "usebackq tokens=1,* delims==" %%A in ("%PACMAN_STATE_FILE%") do (
    if /I "%%A"=="STATUS" set "PACMAN_STATE_STATUS=%%B"
    if /I "%%A"=="PACKAGES" set "PACMAN_PACKAGES=%%B"
)
del "%PACMAN_STATE_FILE%" >nul 2>nul
if /I "%PACMAN_STATE_STATUS%"=="ABSENT" exit /b 1
if /I not "%PACMAN_STATE_STATUS%"=="OK" exit /b 2
if not defined PACMAN_PACKAGES exit /b 2
exit /b 0

:state_has
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try { $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); if (-not $key) { exit 1 }; try { if (@($key.GetValueNames()) -contains '%~1') { exit 0 }; exit 1 } finally { $key.Dispose() } } catch { exit 2 }" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_state
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try { $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true); if (-not $key) { exit 0 }; try { foreach ($name in @('%~1.Path','%~1')) { $key.DeleteValue($name,$false) }; $remaining=@($key.GetValueNames()); if ($remaining -contains '%~1.Path' -or $remaining -contains '%~1') { exit 1 }; exit 0 } finally { $key.Dispose() } } catch { exit 2 }" >nul 2>nul
if errorlevel 1 goto clear_state_failed
exit /b 0

:clear_state_failed
echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be cleared for %~1.
exit /b 1

:clear_pacman_state
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try { $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true); if (-not $key) { exit 0 }; try { $names=@('Pacman.Packages','Pacman.Shell.Path','Pacman.Toolchain'); foreach ($name in $names) { $key.DeleteValue($name,$false) }; $remaining=@($key.GetValueNames()); if (@($names | Where-Object { $remaining -contains $_ }).Count) { exit 1 }; exit 0 } finally { $key.Dispose() } } catch { exit 2 }" >nul 2>nul
if errorlevel 1 goto clear_pacman_state_failed
exit /b 0

:clear_pacman_state_failed
echo [%ESC%[31mFAILED%ESC%[0m] Setup ownership state could not be cleared for the MSYS2 CP toolchain.
exit /b 1

:assert_state_absent
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try { $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); if ($key) { $key.Dispose(); exit 1 }; exit 0 } catch { exit 2 }" >nul 2>nul
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] CP setup ownership state still exists; the setup folder will not be removed.
exit /b 1

:print_missing
echo [%ESC%[33mMISSING%ESC%[0m] %~1
exit /b 0

:recover_pending_acl
set "PENDING_ACL_WORKER=%CP_RUNTIME_TEMP%\cp_setup_pending_acl_%RANDOM%_%RANDOM%.ps1"
set "PENDING_ACL_COMMIT=%CP_RUNTIME_TEMP%\cp_setup_pending_acl_commit_%RANDOM%_%RANDOM%.ps1"
set "PENDING_ACL_LOG=%CP_RUNTIME_TEMP%\cp_setup_pending_acl.log"
call :export_embedded_block "__CP_PENDING_ACL_WORKER_BEGIN__" "__CP_PENDING_ACL_WORKER_END__" "%PENDING_ACL_WORKER%"
if errorlevel 1 goto pending_acl_failed
call :export_embedded_block "__CP_PENDING_ACL_COMMIT_BEGIN__" "__CP_PENDING_ACL_COMMIT_END__" "%PENDING_ACL_COMMIT%"
if errorlevel 1 goto pending_acl_failed
call :run_medium_worker "%PENDING_ACL_WORKER%" 120 > "%PENDING_ACL_LOG%" 2>&1
set "PENDING_ACL_EXIT=%ERRORLEVEL%"
if "%PENDING_ACL_EXIT%"=="0" "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_ACL_COMMIT%" >> "%PENDING_ACL_LOG%" 2>&1
if "%PENDING_ACL_EXIT%"=="0" set "PENDING_ACL_EXIT=%ERRORLEVEL%"
del "%PENDING_ACL_WORKER%" "%PENDING_ACL_COMMIT%" >nul 2>nul
call :publish_component_log "cp_setup_pending_acl.log"
set "PENDING_ACL_PUBLISH_EXIT=%ERRORLEVEL%"
if "%PENDING_ACL_EXIT%"=="0" if not "%PENDING_ACL_PUBLISH_EXIT%"=="0" set "PENDING_ACL_EXIT=1"
if not "%PENDING_ACL_EXIT%"=="0" goto pending_acl_failed
del "%PENDING_ACL_LOG%" >nul 2>nul
exit /b 0

:pending_acl_failed
call :publish_component_log "cp_setup_pending_acl.log" >nul 2>nul
del "%PENDING_ACL_WORKER%" "%PENDING_ACL_COMMIT%" >nul 2>nul
if "%UNINSTALL_TIMEOUT_SEEN%"=="1" set "PENDING_ACL_EXIT=124"
if not defined PENDING_ACL_EXIT set "PENDING_ACL_EXIT=1"
echo [%ESC%[31mFAILED%ESC%[0m] Pending ac-library recovery failed.
exit /b %PENDING_ACL_EXIT%

:recover_pending_components
set "PENDING_COMPONENT_READ=%CP_RUNTIME_TEMP%\cp_setup_pending_components_%RANDOM%_%RANDOM%.ps1"
set "PENDING_COMPONENT_INFO=%CP_RUNTIME_TEMP%\cp_setup_pending_components_%RANDOM%_%RANDOM%.txt"
set "PENDING_COMPONENT_COMMIT=%CP_RUNTIME_TEMP%\cp_setup_pending_components_commit_%RANDOM%_%RANDOM%.ps1"
set "PENDING_COMPONENT_LOG=%CP_RUNTIME_TEMP%\cp_setup_pending_components.log"
set "PENDING_WINGET_PACKAGE="
set "PENDING_WINGET_COMPONENT="
set "PENDING_WINGET_PRESENT="
set "PENDING_PACMAN_SHELL="
set "PENDING_PACMAN_PACKAGES="
set "PENDING_PACMAN_RECOVERED="
> "%PENDING_COMPONENT_READ%" echo $ErrorActionPreference='Stop'
>> "%PENDING_COMPONENT_READ%" echo function Hash-Bytes^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^).Replace^('-',''^).ToLowerInvariant^(^)^) } finally { $sha.Dispose^(^) } }
>> "%PENDING_COMPONENT_READ%" echo function Read-Atomic^([Microsoft.Win32.RegistryKey]$state,[string]$name^) { if ^(@^($state.GetValueNames^(^)^) -notcontains $name^) { return $null }; if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw ^('Invalid '+$name+' kind.'^) }; $parts=^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)^).Split^([char]'^|'^); if ^($parts.Count -ne 5 -or $parts[0] -cne 'v2' -or $parts[1] -notmatch '^^[0-9a-f]{32}$' -or $parts[2] -notin @^('prepared','committed'^) -or $parts[3] -notmatch '^^[0-9a-f]{64}$'^) { throw ^('Invalid '+$name+' intent.'^) }; $bytes=[Convert]::FromBase64String^($parts[4]^); if ^(^(Hash-Bytes $bytes^) -cne $parts[3]^) { throw ^('Invalid '+$name+' hash.'^) }; [pscustomobject]@{Stage=$parts[2];Nonce=$parts[1];Plan=^([Text.Encoding]::UTF8.GetString^($bytes^) ^| ConvertFrom-Json^)} }
>> "%PENDING_COMPONENT_READ%" echo $map=@{'Git.Git'='Winget.Git';'Neovim.Neovim'='Winget.Neovim';'OpenJS.NodeJS.LTS'='Winget.Node';'EclipseAdoptium.Temurin.21.JDK'='Winget.JDK';'MSYS2.MSYS2'='Winget.MSYS2'}; $allowed=@^($env:PACMAN_PACKAGES_ALLOWED -split ' ' ^| Where-Object { $_ }^)
>> "%PENDING_COMPONENT_READ%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $state^) { [IO.File]::WriteAllText^($env:PENDING_COMPONENT_INFO,''^); exit 0 }; try { $lines=[Collections.Generic.List[string]]::new^(^); $winget=Read-Atomic $state 'Pending.Winget.Intent'; if ^($winget^) { $p=$winget.Plan; if ^([int]$p.Version -ne 2 -or [string]$p.OperationId -cne $winget.Nonce -or -not $map.ContainsKey^([string]$p.Package^) -or $map[[string]$p.Package] -cne [string]$p.Component -or [bool]$p.BaselinePresent^) { throw 'Invalid pending winget plan.' }; $lines.Add^('W^|'+$p.Package+'^|'+$p.Component^) }; $pacman=Read-Atomic $state 'Pending.Pacman.Intent'; if ^($pacman^) { $p=$pacman.Plan; $absent=@^($p.BaselineAbsentPackages^); $recovered=@^($p.RecoveredPackages^); foreach ^($list in @^($absent,$recovered^)^) { $sorted=@^($list ^| Sort-Object -Unique^); if ^($sorted.Count -ne $list.Count -or ^($sorted -join "`0"^) -cne ^($list -join "`0"^) -or @^($list ^| Where-Object { $allowed -notcontains $_ }^).Count^) { throw 'Invalid pending pacman inventory.' } }; $shell=[IO.Path]::GetFullPath^([string]$p.Shell^); $expected=[IO.Path]::GetFullPath^('C:\msys64\msys2_shell.cmd'^); if ^([int]$p.Version -ne 2 -or [string]$p.OperationId -cne $pacman.Nonce -or $shell -ine $expected -or ^($pacman.Stage -eq 'prepared' -and $recovered.Count^)^) { throw 'Invalid pending pacman plan.' }; $lines.Add^('P^|'+$shell+'^|'+^($absent -join ','^)^) }; [IO.File]::WriteAllLines^($env:PENDING_COMPONENT_INFO,$lines,[Text.UTF8Encoding]::new^($false^)^) } finally { $state.Dispose^(^) }
del "%PENDING_COMPONENT_INFO%" "%PENDING_COMPONENT_LOG%" >nul 2>nul
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_COMPONENT_READ%" >nul 2> "%PENDING_COMPONENT_LOG%"
set "PENDING_COMPONENT_EXIT=%ERRORLEVEL%"
del "%PENDING_COMPONENT_READ%" >nul 2>nul
if not "%PENDING_COMPONENT_EXIT%"=="0" goto pending_component_failed
for /F "usebackq tokens=1-3 delims=|" %%A in ("%PENDING_COMPONENT_INFO%") do (
    if /I "%%A"=="W" set "PENDING_WINGET_PACKAGE=%%B" & set "PENDING_WINGET_COMPONENT=%%C"
    if /I "%%A"=="P" set "PENDING_PACMAN_SHELL=%%B" & set "PENDING_PACMAN_PACKAGES=%%C"
)
del "%PENDING_COMPONENT_INFO%" >nul 2>nul
if defined PENDING_WINGET_PACKAGE (
    call :require_winget
    if errorlevel 1 goto pending_component_failed
    call :winget_has_package "%PENDING_WINGET_PACKAGE%"
    set "PENDING_QUERY_EXIT=!ERRORLEVEL!"
    if "!PENDING_QUERY_EXIT!"=="2" goto pending_component_failed
    if "!PENDING_QUERY_EXIT!"=="0" (set "PENDING_WINGET_PRESENT=1") else set "PENDING_WINGET_PRESENT=0"
)
if defined PENDING_PACMAN_PACKAGES if exist "%PENDING_PACMAN_SHELL%" (
    for %%I in ("%PENDING_PACMAN_SHELL%") do set "PENDING_PACMAN_BASH=%%~dpIusr\bin\bash.exe"
    if exist "!PENDING_PACMAN_BASH!" (
        set "PENDING_PACMAN_OUTPUT=%CP_RUNTIME_TEMP%\cp_setup_pending_pacman_%RANDOM%_%RANDOM%.txt"
        set "SILENT_COMMAND="!PENDING_PACMAN_BASH!" -lc "for p in %PENDING_PACMAN_PACKAGES:,= %; do if pacman -Qq -- $p ^>/dev/null 2^>^&1; then printf '%%%%s\n' $p; fi; done; exit 0""
        set "SILENT_OUTPUT=!PENDING_PACMAN_OUTPUT!"
        set "SILENT_ERROR=%PENDING_COMPONENT_LOG%"
        set "SILENT_TIMEOUT_SECONDS=120"
        call :run_silent_command
        if errorlevel 1 goto pending_component_failed
        for /F "usebackq delims=" %%P in ("!PENDING_PACMAN_OUTPUT!") do if defined PENDING_PACMAN_RECOVERED (set "PENDING_PACMAN_RECOVERED=!PENDING_PACMAN_RECOVERED!,%%P") else set "PENDING_PACMAN_RECOVERED=%%P"
        del "!PENDING_PACMAN_OUTPUT!" >nul 2>nul
    )
)
> "%PENDING_COMPONENT_COMMIT%" echo $ErrorActionPreference='Stop'
>> "%PENDING_COMPONENT_COMMIT%" echo function Hash-Bytes^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^).Replace^('-',''^).ToLowerInvariant^(^)^) } finally { $sha.Dispose^(^) } }
>> "%PENDING_COMPONENT_COMMIT%" echo function Read-Atomic^([Microsoft.Win32.RegistryKey]$state,[string]$name^) { if ^(@^($state.GetValueNames^(^)^) -notcontains $name^) { return $null }; if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw ^('Invalid '+$name+' kind.'^) }; $parts=^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)^).Split^([char]'^|'^); if ^($parts.Count -ne 5 -or $parts[0] -cne 'v2' -or $parts[1] -notmatch '^^[0-9a-f]{32}$' -or $parts[2] -notin @^('prepared','committed'^) -or $parts[3] -notmatch '^^[0-9a-f]{64}$'^) { throw ^('Invalid '+$name+' intent.'^) }; $bytes=[Convert]::FromBase64String^($parts[4]^); if ^(^(Hash-Bytes $bytes^) -cne $parts[3]^) { throw ^('Invalid '+$name+' hash.'^) }; [pscustomobject]@{Stage=$parts[2];Nonce=$parts[1];Plan=^([Text.Encoding]::UTF8.GetString^($bytes^) ^| ConvertFrom-Json^)} }
>> "%PENDING_COMPONENT_COMMIT%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$true^); if ^(-not $state^) { exit 0 }; try { $winget=Read-Atomic $state 'Pending.Winget.Intent'; if ^($winget^) { $map=@{'Git.Git'='Winget.Git';'Neovim.Neovim'='Winget.Neovim';'OpenJS.NodeJS.LTS'='Winget.Node';'EclipseAdoptium.Temurin.21.JDK'='Winget.JDK';'MSYS2.MSYS2'='Winget.MSYS2'}; $p=$winget.Plan; if ^([int]$p.Version -ne 2 -or [string]$p.OperationId -cne $winget.Nonce -or -not $map.ContainsKey^([string]$p.Package^) -or $map[[string]$p.Package] -cne [string]$p.Component -or [bool]$p.BaselinePresent^) { throw 'Invalid pending winget plan.' }; if ^($env:PENDING_WINGET_PRESENT -eq '1'^) { if ^(@^($state.GetValueNames^(^)^) -contains [string]$p.Component^) { if ^($state.GetValueKind^([string]$p.Component^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^([string]$p.Component,0^) -ne 1^) { throw 'Invalid recovered winget ownership.' } } else { $state.SetValue^([string]$p.Component,1,[Microsoft.Win32.RegistryValueKind]::DWord^) } }; $state.DeleteValue^('Pending.Winget.Intent',$false^) }; $pacman=Read-Atomic $state 'Pending.Pacman.Intent'; if ^($pacman^) { $p=$pacman.Plan; $allowed=@^($env:PACMAN_PACKAGES_ALLOWED -split ' ' ^| Where-Object { $_ }^); $absent=@^($p.BaselineAbsentPackages^); $reported=@^($env:PENDING_PACMAN_RECOVERED -split ',' ^| Where-Object { $_ } ^| Sort-Object -Unique^); if ^(@^($reported ^| Where-Object { $absent -notcontains $_ -or $allowed -notcontains $_ }^).Count^) { throw 'Invalid recovered pacman package set.' }; $existing=if ^(@^($state.GetValueNames^(^)^) -contains 'Pacman.Packages'^) { if ^($state.GetValueKind^('Pacman.Packages'^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Invalid pacman ownership kind.' }; @^($state.GetValue^('Pacman.Packages'^)^) } else { @^(^) }; $merged=[string[]]@^($existing+$reported ^| Where-Object { $_ } ^| Sort-Object -Unique^); if ^($merged.Count^) { $state.SetValue^('Pacman.Packages',$merged,[Microsoft.Win32.RegistryValueKind]::MultiString^); $state.SetValue^('Pacman.Toolchain',1,[Microsoft.Win32.RegistryValueKind]::DWord^) }; $state.DeleteValue^('Pending.Pacman.Intent',$false^) }; foreach ^($name in @^('Pending.Winget.Intent','Pending.Pacman.Intent'^)^) { if ^(@^($state.GetValueNames^(^)^) -contains $name^) { throw ^('Pending component intent cleanup failed: '+$name^) } } } finally { $state.Dispose^(^) }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_COMPONENT_COMMIT%" >> "%PENDING_COMPONENT_LOG%" 2>&1
set "PENDING_COMPONENT_EXIT=%ERRORLEVEL%"
del "%PENDING_COMPONENT_COMMIT%" >nul 2>nul
call :publish_component_log "cp_setup_pending_components.log"
set "PENDING_COMPONENT_PUBLISH_EXIT=%ERRORLEVEL%"
if "%PENDING_COMPONENT_EXIT%"=="0" if not "%PENDING_COMPONENT_PUBLISH_EXIT%"=="0" set "PENDING_COMPONENT_EXIT=1"
if not "%PENDING_COMPONENT_EXIT%"=="0" goto pending_component_failed
del "%PENDING_COMPONENT_LOG%" >nul 2>nul
exit /b 0

:pending_component_failed
call :publish_component_log "cp_setup_pending_components.log" >nul 2>nul
if "%UNINSTALL_TIMEOUT_SEEN%"=="1" set "PENDING_COMPONENT_EXIT=124"
if not defined PENDING_COMPONENT_EXIT set "PENDING_COMPONENT_EXIT=1"
echo [%ESC%[31mFAILED%ESC%[0m] Setup component ownership recovery failed.
echo Log: %CP_VISIBLE_TEMP%\cp_setup_pending_components.log
exit /b %PENDING_COMPONENT_EXIT%

:recover_pending_mason
set "PENDING_MASON_WORKER=%CP_RUNTIME_TEMP%\cp_setup_pending_mason_%RANDOM%_%RANDOM%.ps1"
set "PENDING_MASON_COMMIT=%CP_RUNTIME_TEMP%\cp_setup_pending_mason_commit_%RANDOM%_%RANDOM%.ps1"
set "PENDING_MASON_INVENTORY=%CP_RUNTIME_TEMP%\cp_setup_pending_mason_%RANDOM%_%RANDOM%.txt"
set "PENDING_MASON_LOG=%CP_RUNTIME_TEMP%\cp_setup_pending_mason.log"
call :export_embedded_block "__CP_PENDING_MASON_WORKER_BEGIN__" "__CP_PENDING_MASON_WORKER_END__" "%PENDING_MASON_WORKER%"
if errorlevel 1 goto pending_mason_failed
call :export_embedded_block "__CP_PENDING_MASON_COMMIT_BEGIN__" "__CP_PENDING_MASON_COMMIT_END__" "%PENDING_MASON_COMMIT%"
if errorlevel 1 goto pending_mason_failed
del "%PENDING_MASON_LOG%" "%PENDING_MASON_INVENTORY%" >nul 2>nul
call :run_medium_worker "%PENDING_MASON_WORKER%" 120 > "%PENDING_MASON_INVENTORY%" 2> "%PENDING_MASON_LOG%"
set "PENDING_MASON_EXIT=%ERRORLEVEL%"
if "%PENDING_MASON_EXIT%"=="0" "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_MASON_COMMIT%" >> "%PENDING_MASON_LOG%" 2>&1
if "%PENDING_MASON_EXIT%"=="0" set "PENDING_MASON_EXIT=%ERRORLEVEL%"
del "%PENDING_MASON_WORKER%" "%PENDING_MASON_COMMIT%" "%PENDING_MASON_INVENTORY%" >nul 2>nul
call :publish_component_log "cp_setup_pending_mason.log"
set "PENDING_MASON_PUBLISH_EXIT=%ERRORLEVEL%"
if "%PENDING_MASON_EXIT%"=="0" if not "%PENDING_MASON_PUBLISH_EXIT%"=="0" set "PENDING_MASON_EXIT=1"
if not "%PENDING_MASON_EXIT%"=="0" goto pending_mason_failed
del "%PENDING_MASON_LOG%" >nul 2>nul
exit /b 0

:pending_mason_failed
call :publish_component_log "cp_setup_pending_mason.log" >nul 2>nul
del "%PENDING_MASON_WORKER%" "%PENDING_MASON_COMMIT%" "%PENDING_MASON_INVENTORY%" >nul 2>nul
if "%UNINSTALL_TIMEOUT_SEEN%"=="1" set "PENDING_MASON_EXIT=124"
if not defined PENDING_MASON_EXIT set "PENDING_MASON_EXIT=1"
echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed Mason inventory recovery failed.
echo Log: %CP_VISIBLE_TEMP%\cp_setup_pending_mason.log
exit /b %PENDING_MASON_EXIT%

:recover_pending_artifacts
set "PENDING_ARTIFACT_WORKER=%CP_RUNTIME_TEMP%\cp_setup_pending_artifacts_%RANDOM%_%RANDOM%.ps1"
set "PENDING_ARTIFACT_LOG=%CP_RUNTIME_TEMP%\cp_setup_pending_artifacts.log"
call :export_embedded_block "__CP_PENDING_ARTIFACTS_WORKER_BEGIN__" "__CP_PENDING_ARTIFACTS_WORKER_END__" "%PENDING_ARTIFACT_WORKER%"
if errorlevel 1 goto pending_artifact_failed
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_ARTIFACT_WORKER%" >nul 2> "%PENDING_ARTIFACT_LOG%"
set "PENDING_ARTIFACT_EXIT=%ERRORLEVEL%"
del "%PENDING_ARTIFACT_WORKER%" >nul 2>nul
call :publish_component_log "cp_setup_pending_artifacts.log"
set "PENDING_ARTIFACT_PUBLISH_EXIT=%ERRORLEVEL%"
if "%PENDING_ARTIFACT_EXIT%"=="0" if not "%PENDING_ARTIFACT_PUBLISH_EXIT%"=="0" set "PENDING_ARTIFACT_EXIT=1"
if not "%PENDING_ARTIFACT_EXIT%"=="0" goto pending_artifact_failed
del "%PENDING_ARTIFACT_LOG%" >nul 2>nul
exit /b 0

:pending_artifact_failed
call :publish_component_log "cp_setup_pending_artifacts.log" >nul 2>nul
del "%PENDING_ARTIFACT_WORKER%" >nul 2>nul
if not defined PENDING_ARTIFACT_EXIT set "PENDING_ARTIFACT_EXIT=1"
echo [%ESC%[31mFAILED%ESC%[0m] Setup-created temporary-file ownership recovery failed.
exit /b %PENDING_ARTIFACT_EXIT%

:recover_pending_registry
set "PENDING_REGISTRY_WORKER=%CP_RUNTIME_TEMP%\cp_setup_pending_registry_%RANDOM%_%RANDOM%.ps1"
set "PENDING_REGISTRY_COMMIT=%CP_RUNTIME_TEMP%\cp_setup_pending_registry_commit_%RANDOM%_%RANDOM%.ps1"
set "PENDING_REGISTRY_LOG=%CP_RUNTIME_TEMP%\cp_setup_pending_registry.log"
> "%PENDING_REGISTRY_WORKER%" echo $ErrorActionPreference='Stop'
>> "%PENDING_REGISTRY_WORKER%" echo function Hash-Bytes^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^).Replace^('-',''^).ToLowerInvariant^(^)^) } finally { $sha.Dispose^(^) } }
>> "%PENDING_REGISTRY_WORKER%" echo function Read-Intent^([Microsoft.Win32.RegistryKey]$state^) { $name='Pending.Registry.Intent'; if ^(@^($state.GetValueNames^(^)^) -notcontains $name^) { return $null }; if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Invalid pending registry kind.' }; $parts=^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)^).Split^([char]'^|'^); if ^($parts.Count -ne 5 -or $parts[0] -cne 'v1' -or $parts[1] -notin @^('Path','Environment','AutoRun','VTL'^) -or $parts[2] -notin @^('prepared','committed'^) -or $parts[3] -notmatch '^^[0-9a-f]{64}$'^) { throw 'Invalid pending registry intent.' }; $bytes=[Convert]::FromBase64String^($parts[4]^); if ^(^(Hash-Bytes $bytes^) -cne $parts[3]^) { throw 'Invalid pending registry hash.' }; $json=[Text.Encoding]::UTF8.GetString^($bytes^); $plan=$json ^| ConvertFrom-Json; $mutationCount=@^($plan.Mutations^).Count; if ^([int]$plan.Version -ne 1 -or [string]$plan.Sid -cne $env:CP_SETUP_TARGET_SID -or [string]$plan.Mode -cne $parts[1] -or ^($parts[1] -eq 'Environment' -and $mutationCount -ne 6^) -or ^($parts[1] -ne 'Environment' -and $mutationCount -ne 1^) -or @^($plan.Metadata^).Count -ne @^($plan.MetadataBefore^).Count^) { throw 'Invalid pending registry plan.' }; [pscustomobject]@{ Stage=$parts[2]; Mode=$parts[1]; Plan=$plan } }
>> "%PENDING_REGISTRY_WORKER%" echo function Read-Value^([Microsoft.Win32.RegistryKey]$key,[string]$name^) { if ^(-not $key -or @^($key.GetValueNames^(^)^) -notcontains $name^) { return [pscustomobject]@{Exists=$false;Kind=0;Value=$null} }; [pscustomobject]@{Exists=$true;Kind=[int]$key.GetValueKind^($name^);Value=$key.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)} }
>> "%PENDING_REGISTRY_WORKER%" echo function Valid-Spec^($spec^) { if ^($null -eq $spec -or $spec.Exists -isnot [bool]^) { return $false }; if ^(-not [bool]$spec.Exists^) { return [int]$spec.Kind -eq 0 -and $null -eq $spec.Value }; [int]$kind=[int]$spec.Kind; if ^($kind -notin @^(1,2,4,7^)^) { return $false }; if ^($kind -eq 4^) { return $spec.Value -is [ValueType] }; if ^($kind -eq 7^) { return $null -ne $spec.Value }; return $spec.Value -is [string] }
>> "%PENDING_REGISTRY_WORKER%" echo function Same^($actual,$spec^) { if ^(-not ^(Valid-Spec $spec^)^ -or [bool]$actual.Exists -ne [bool]$spec.Exists^) { return $false }; if ^(-not [bool]$spec.Exists^) { return $true }; if ^([int]$actual.Kind -ne [int]$spec.Kind^) { return $false }; if ^([int]$spec.Kind -eq 7^) { return ^(@^($actual.Value^) -join "`0"^) -ceq ^(@^($spec.Value^) -join "`0"^) }; if ^([int]$spec.Kind -eq 4^) { return [int64]$actual.Value -eq [int64]$spec.Value }; [string]$actual.Value -ceq [string]$spec.Value }
>> "%PENDING_REGISTRY_WORKER%" echo function Apply^([Microsoft.Win32.RegistryKey]$key,[string]$name,$spec^) { if ^(-not ^(Valid-Spec $spec^)^) { throw 'Invalid pending registry value specification.' }; if ^(-not [bool]$spec.Exists^) { $key.DeleteValue^($name,$false^); return }; $value=if ^([int]$spec.Kind -eq 7^) { [string[]]@^($spec.Value^) } elseif ^([int]$spec.Kind -eq 4^) { [int]$spec.Value } else { [string]$spec.Value }; $key.SetValue^($name,$value,[Microsoft.Win32.RegistryValueKind][int]$spec.Kind^) }
>> "%PENDING_REGISTRY_WORKER%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $state^) { exit 0 }
>> "%PENDING_REGISTRY_WORKER%" echo try { $intent=Read-Intent $state; if ^($null -eq $intent -or $intent.Stage -eq 'committed'^) { exit 0 }; $map=@{ Path=@^('Environment','Path'^); Environment=@^('Environment',$null^); AutoRun=@^('CommandProcessor','AutoRun'^); VTL=@^('Console','VirtualTerminalLevel'^) }; $expectedMap=$map[$intent.Mode]; $mutations=@^($intent.Plan.Mutations^); $allowedEnvironment=@^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^); $seen=[Collections.Generic.HashSet[string]]::new^([StringComparer]::Ordinal^); foreach ^($mutation in $mutations^) { if ^($null -eq $expectedMap -or [string]$mutation.Key -cne $expectedMap[0] -or ^($expectedMap[1] -and [string]$mutation.Name -cne $expectedMap[1]^) -or ^($intent.Mode -eq 'Environment' -and $allowedEnvironment -notcontains [string]$mutation.Name^) -or -not $seen.Add^([string]$mutation.Name^)^) { throw 'Invalid pending registry mutation target.' } }; if ^($intent.Mode -eq 'Environment' -and @^($allowedEnvironment ^| Where-Object { -not $seen.Contains^($_^) }^).Count^) { throw 'Incomplete pending environment mutation set.' }; $users=[Microsoft.Win32.Registry]::Users; $relative=switch ^($intent.Mode^) { {$_ -in @^('Path','Environment'^)} { $env:CP_SETUP_TARGET_SID+'\Environment'; break }; 'AutoRun' { $env:CP_SETUP_TARGET_SID+'\Software\Microsoft\Command Processor'; break }; 'VTL' { $env:CP_SETUP_TARGET_SID+'\Console'; break } }; $key=$users.OpenSubKey^($relative,$true^); if ^(-not $key^) { throw 'Target-user registry key is unavailable.' }; try { [array]::Reverse^($mutations^); foreach ^($mutation in $mutations^) { $current=Read-Value $key ^([string]$mutation.Name^); if ^(Same $current $mutation.Desired^) { Apply $key ^([string]$mutation.Name^) $mutation.Expected; $after=Read-Value $key ^([string]$mutation.Name^); if ^(-not ^(Same $after $mutation.Expected^)^) { throw 'Pending registry rollback verification failed.' } } elseif ^(-not ^(Same $current $mutation.Expected^)^) { } } } finally { $key.Dispose^(^) } } finally { $state.Dispose^(^) }
> "%PENDING_REGISTRY_COMMIT%" echo $ErrorActionPreference='Stop'
>> "%PENDING_REGISTRY_COMMIT%" echo function Hash-Bytes^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^).Replace^('-',''^).ToLowerInvariant^(^)^) } finally { $sha.Dispose^(^) } }
>> "%PENDING_REGISTRY_COMMIT%" echo function Read-Spec^([Microsoft.Win32.RegistryKey]$key,[string]$name^) { if ^(@^($key.GetValueNames^(^)^) -notcontains $name^) { return [pscustomobject]@{Exists=$false;Kind=0;Value=$null} }; [pscustomobject]@{Exists=$true;Kind=[int]$key.GetValueKind^($name^);Value=$key.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)} }
>> "%PENDING_REGISTRY_COMMIT%" echo function Same^($actual,$spec^) { if ^([bool]$actual.Exists -ne [bool]$spec.Exists^) { return $false }; if ^(-not [bool]$spec.Exists^) { return [int]$spec.Kind -eq 0 -and $null -eq $spec.Value }; if ^([int]$actual.Kind -ne [int]$spec.Kind^) { return $false }; if ^([int]$spec.Kind -eq 7^) { return ^(@^($actual.Value^) -join "`0"^) -ceq ^(@^($spec.Value^) -join "`0"^) }; if ^([int]$spec.Kind -eq 4^) { return [int64]$actual.Value -eq [int64]$spec.Value }; [string]$actual.Value -ceq [string]$spec.Value }
>> "%PENDING_REGISTRY_COMMIT%" echo function Apply^([Microsoft.Win32.RegistryKey]$key,$spec^) { $name=[string]$spec.Name; if ^(-not [bool]$spec.Exists^) { $key.DeleteValue^($name,$false^); return }; $value=if ^([int]$spec.Kind -eq 7^) { [string[]]@^($spec.Value^) } elseif ^([int]$spec.Kind -eq 4^) { [int]$spec.Value } else { [string]$spec.Value }; $key.SetValue^($name,$value,[Microsoft.Win32.RegistryValueKind][int]$spec.Kind^) }
>> "%PENDING_REGISTRY_COMMIT%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$true^); if ^(-not $state^) { exit 0 }; $name='Pending.Registry.Intent'
>> "%PENDING_REGISTRY_COMMIT%" echo try { if ^(@^($state.GetValueNames^(^)^) -notcontains $name^) { exit 0 }; if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Invalid pending registry kind.' }; $parts=^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)^).Split^([char]'^|'^); if ^($parts.Count -ne 5 -or $parts[0] -cne 'v1' -or $parts[1] -notin @^('Path','Environment','AutoRun','VTL'^) -or $parts[2] -notin @^('prepared','committed'^) -or $parts[3] -notmatch '^^[0-9a-f]{64}$'^) { throw 'Invalid pending registry intent.' }; $bytes=[Convert]::FromBase64String^($parts[4]^); if ^(^(Hash-Bytes $bytes^) -cne $parts[3]^) { throw 'Invalid pending registry hash.' }; $plan=^([Text.Encoding]::UTF8.GetString^($bytes^) ^| ConvertFrom-Json^); if ^([int]$plan.Version -ne 1 -or [string]$plan.Sid -cne $env:CP_SETUP_TARGET_SID -or [string]$plan.Mode -cne $parts[1] -or @^($plan.Metadata^).Count -ne @^($plan.MetadataBefore^).Count^) { throw 'Invalid pending registry plan.' }; $names=[Collections.Generic.HashSet[string]]::new^([StringComparer]::Ordinal^); foreach ^($spec in @^($plan.Metadata^)^) { if ^([string]$spec.Name -notmatch '^^(?:Path\.|AutoRun\.|Console\.VirtualTerminal\.|Env\.[A-Z0-9_]+\.)' -or -not $names.Add^([string]$spec.Name^)^) { throw 'Invalid pending registry metadata.' } }; foreach ^($spec in @^($plan.MetadataBefore^)^) { if ^(-not $names.Contains^([string]$spec.Name^)^) { throw 'Invalid pending registry metadata baseline.' } }; if ^($parts[2] -eq 'prepared'^) { foreach ^($spec in @^($plan.MetadataBefore^)^) { $desired=@^($plan.Metadata ^| Where-Object { [string]$_.Name -ceq [string]$spec.Name }^); if ^($desired.Count -ne 1^) { throw 'Invalid pending registry metadata pairing.' }; $current=Read-Spec $state ^([string]$spec.Name^); if ^(-not ^(Same $current $spec^) -and -not ^(Same $current $desired[0]^)^) { throw ^('Unexpected protected metadata during rollback: '+$spec.Name^) }; Apply $state $spec; if ^(-not ^(Same ^(Read-Spec $state ^([string]$spec.Name^)^) $spec^)^) { throw 'Pending metadata rollback verification failed.' } } } else { foreach ^($spec in @^($plan.Metadata^)^) { if ^(-not ^(Same ^(Read-Spec $state ^([string]$spec.Name^)^) $spec^)^) { throw 'Committed pending metadata verification failed.' } } }; $state.DeleteValue^($name,$false^); if ^(@^($state.GetValueNames^(^)^) -contains $name^) { throw 'Pending registry intent cleanup failed.' } } finally { $state.Dispose^(^) }
del "%PENDING_REGISTRY_LOG%" >nul 2>nul
call :run_medium_worker "%PENDING_REGISTRY_WORKER%" 120 >nul 2> "%PENDING_REGISTRY_LOG%"
set "PENDING_REGISTRY_EXIT=%ERRORLEVEL%"
if "%PENDING_REGISTRY_EXIT%"=="0" "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PENDING_REGISTRY_COMMIT%" >> "%PENDING_REGISTRY_LOG%" 2>&1
if "%PENDING_REGISTRY_EXIT%"=="0" set "PENDING_REGISTRY_EXIT=%ERRORLEVEL%"
del "%PENDING_REGISTRY_WORKER%" "%PENDING_REGISTRY_COMMIT%" >nul 2>nul
call :publish_component_log "cp_setup_pending_registry.log"
set "PENDING_REGISTRY_PUBLISH_EXIT=%ERRORLEVEL%"
if "%PENDING_REGISTRY_EXIT%"=="0" if not "%PENDING_REGISTRY_PUBLISH_EXIT%"=="0" set "PENDING_REGISTRY_EXIT=1"
if not "%PENDING_REGISTRY_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup configuration recovery failed.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_pending_registry.log
    exit /b %PENDING_REGISTRY_EXIT%
)
del "%PENDING_REGISTRY_LOG%" >nul 2>nul
exit /b 0

:stop_setup_active_operation
set "ACTIVE_STOP_PS=%CP_RUNTIME_TEMP%\cp_setup_active_stop_%RANDOM%_%RANDOM%.ps1"
set "ACTIVE_STOP_LOG=%CP_RUNTIME_TEMP%\cp_setup_active_stop.log"
> "%ACTIVE_STOP_PS%" echo $ErrorActionPreference='Stop'
>> "%ACTIVE_STOP_PS%" echo . $env:PROCESS_TREE_PS
>> "%ACTIVE_STOP_PS%" echo function Hash-Bytes^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^).Replace^('-',''^).ToLowerInvariant^(^)^) } finally { $sha.Dispose^(^) } }
>> "%ACTIVE_STOP_PS%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$true^); if ^(-not $state^) { exit 0 }
>> "%ACTIVE_STOP_PS%" echo try { $name='Active.Operation.Intent'; $names=@^($state.GetValueNames^(^)^); if ^($names -notcontains $name^) { exit 0 }; if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Invalid active-operation registry kind.' }; $parts=^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)^).Split^([char]'^|'^); if ^($parts.Count -ne 11 -or $parts[0] -cne 'v1' -or $parts[1] -notmatch '^^[0-9a-f]{32}$' -or $parts[2] -notin @^('Lazy','Mason'^) -or $parts[6] -cne $env:CP_SETUP_TARGET_SID -or $parts[7] -notmatch '^^[0-9a-f]{64}$' -or $parts[8] -notmatch '^^[0-9a-f]{64}$' -or $parts[9] -notmatch '^^[0-9a-f]{64}$'^) { throw 'Invalid active-operation payload.' }; [int]$runnerPid=0; [long]$startTicks=0; [int]$session=0; if ^(-not [int]::TryParse^($parts[3],[ref]$runnerPid^) -or $runnerPid -le 4 -or -not [long]::TryParse^($parts[4],[ref]$startTicks^) -or $startTicks -le 0 -or -not [int]::TryParse^($parts[5],[ref]$session^) -or $session -lt 0^) { throw 'Invalid active-operation process identity.' }; $pathBytes=[Convert]::FromBase64String^($parts[10]^); if ^(^(Hash-Bytes $pathBytes^) -cne $parts[9]^) { throw 'Invalid active-operation payload hash.' }; $pathText=[Text.Encoding]::UTF8.GetString^($pathBytes^); $expected=[IO.Path]::GetFullPath^($env:POWERSHELL_EXE^); if ^($pathText -cne [IO.Path]::GetFullPath^($pathText^) -or $pathText -ine $expected -or ^(Get-FileHash -LiteralPath $expected -Algorithm SHA256^).Hash.ToLowerInvariant^(^) -cne $parts[7]^) { throw 'Invalid active-operation image.' }; $process=$null; try { $process=[Diagnostics.Process]::GetProcessById^($runnerPid^); $same=$process.SessionId -eq $session -and $process.StartTime.ToUniversalTime^(^).Ticks -eq $startTicks; if ^($same^) { try { $same=[IO.Path]::GetFullPath^($process.MainModule.FileName^) -ieq $expected } catch { throw 'Active-operation image could not be verified.' } }; if ^($same^) { Stop-VerifiedProcessTree $process $null }; try { $again=[Diagnostics.Process]::GetProcessById^($runnerPid^); try { if ^($again.StartTime.ToUniversalTime^(^).Ticks -eq $startTicks^) { throw 'Setup active-operation process is still running.' } } finally { $again.Dispose^(^) } } catch [ArgumentException] {} } catch [ArgumentException] {} finally { if ^($process^) { $process.Dispose^(^) } }; $state.DeleteValue^($name,$false^); if ^(@^($state.GetValueNames^(^)^) -contains $name^) { throw 'Active-operation marker cleanup failed.' } } finally { $state.Dispose^(^) }
del "%ACTIVE_STOP_LOG%" >nul 2>nul
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACTIVE_STOP_PS%" >nul 2> "%ACTIVE_STOP_LOG%"
set "ACTIVE_STOP_EXIT=%ERRORLEVEL%"
del "%ACTIVE_STOP_PS%" >nul 2>nul
call :publish_component_log "cp_setup_active_stop.log"
set "ACTIVE_STOP_PUBLISH_EXIT=%ERRORLEVEL%"
if "%ACTIVE_STOP_EXIT%"=="0" if not "%ACTIVE_STOP_PUBLISH_EXIT%"=="0" set "ACTIVE_STOP_EXIT=1"
if not "%ACTIVE_STOP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-managed Neovim processes could not be stopped.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_active_stop.log
    exit /b %ACTIVE_STOP_EXIT%
)
del "%ACTIVE_STOP_LOG%" >nul 2>nul
exit /b 0

:remove_created_artifacts
set "ARTIFACT_CLEANUP_LOG=%CP_RUNTIME_TEMP%\cp_setup_artifact_cleanup.log"
del "%ARTIFACT_CLEANUP_LOG%" >nul 2>nul
if /I not "%CP_SETUP_STATE_CONTEXT%"=="SNAPSHOT" (
    call :capture_native_msys2_artifacts "recover" > "%ARTIFACT_CLEANUP_LOG%" 2>&1
    if errorlevel 1 (
        call :publish_component_log "cp_setup_artifact_cleanup.log" >nul 2>nul
        echo [%ESC%[31mFAILED%ESC%[0m] Setup-created temporary files could not be removed safely.
        echo Log: %CP_VISIBLE_TEMP%\cp_setup_artifact_cleanup.log
        exit /b 1
    )
)
set "ARTIFACT_CLEANUP_PS=%CP_RUNTIME_TEMP%\cp_setup_artifact_cleanup_%RANDOM%_%RANDOM%.ps1"
> "%ARTIFACT_CLEANUP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ARTIFACT_CLEANUP_PS%" echo $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%ARTIFACT_CLEANUP_PS%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $state^) { exit 0 }
>> "%ARTIFACT_CLEANUP_PS%" echo try {
>> "%ARTIFACT_CLEANUP_PS%" echo     $names=@^($state.GetValueNames^(^)^); $metadataNames=@^('Artifacts.LocalAppData.Roots','Artifacts.Created.Paths','Artifacts.Before.Paths'^); if ^(@^($metadataNames ^| Where-Object { $names -contains $_ }^).Count -eq 0^) { exit 0 }; foreach ^($metadata in $metadataNames^) { if ^($names -notcontains $metadata -or $state.GetValueKind^($metadata^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw ^('Artifact ownership metadata has an unsafe registry kind: '+$metadata^) } }
>> "%ARTIFACT_CLEANUP_PS%" echo     foreach ^($required in @^('Target.Sid','Target.Profile','Target.LocalAppData'^)^) { if ^($names -notcontains $required^) { throw ^('Missing protected artifact metadata: '+$required^) } }
>> "%ARTIFACT_CLEANUP_PS%" echo     $sid=[string]$state.GetValue^('Target.Sid',$null,$option^); $profile=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.Profile',$null,$option^)^).TrimEnd^('\'^); $local=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.LocalAppData',$null,$option^)^).TrimEnd^('\'^)
>> "%ARTIFACT_CLEANUP_PS%" echo     if ^($sid -cne $env:CP_SETUP_TARGET_SID -or $profile -ine [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_PROFILE^).TrimEnd^('\'^) -or $local -ine [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_LOCALAPPDATA^).TrimEnd^('\'^) -or -not $local.StartsWith^($profile+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Protected artifact metadata is invalid' }
>> "%ARTIFACT_CLEANUP_PS%" echo     $locals=[Collections.Generic.HashSet[string]]::new^([StringComparer]::OrdinalIgnoreCase^); foreach ^($rawRoot in @^($state.GetValue^('Artifacts.LocalAppData.Roots',$null,$option^)^)^) { if ^([string]::IsNullOrWhiteSpace^([string]$rawRoot^)^) { throw 'Empty artifact LocalAppData root' }; $text=^([string]$rawRoot^).TrimEnd^('\'^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^('\'^); if ^($full -ine $text -or $full -notmatch '^^[A-Za-z]:\\' -or -not $locals.Add^($full^)^) { throw ^('Unsafe artifact LocalAppData root: '+$text^) } }; if ^(-not $locals.Contains^($local^)^) { throw 'Target LocalAppData is absent from artifact roots' }; $ordered=@^($locals ^| Sort-Object^); for ^($i=0;$i -lt $ordered.Count;$i++^) { for ^($j=$i+1;$j -lt $ordered.Count;$j++^) { if ^($ordered[$i].StartsWith^($ordered[$j]+'\',[StringComparison]::OrdinalIgnoreCase^) -or $ordered[$j].StartsWith^($ordered[$i]+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Artifact LocalAppData roots overlap' } } }; $roots=@^(foreach ^($artifactLocal in $ordered^) { [pscustomobject]@{ Local=$artifactLocal; Kind='nvim'; Parent=[IO.Path]::GetFullPath^(^(Join-Path $artifactLocal 'Temp'^)^).TrimEnd^('\'^); Target=[IO.Path]::GetFullPath^(^(Join-Path $artifactLocal 'Temp\nvim'^)^).TrimEnd^('\'^) }; [pscustomobject]@{ Local=$artifactLocal; Kind='qt'; Parent=[IO.Path]::GetFullPath^(^(Join-Path $artifactLocal 'cache'^)^).TrimEnd^('\'^); Target=[IO.Path]::GetFullPath^(^(Join-Path $artifactLocal 'cache\qt-installer-framework'^)^).TrimEnd^('\'^) } }^)
>> "%ARTIFACT_CLEANUP_PS%" echo     foreach ^($artifactLocal in $ordered^) { $drive=[IO.Path]::GetPathRoot^($artifactLocal^); $cursor=$drive; foreach ^($part in $artifactLocal.Substring^($drive.Length^).Split^([char]92,[StringSplitOptions]::RemoveEmptyEntries^)^) { $cursor=Join-Path $cursor $part; if ^(Test-Path -LiteralPath $cursor^) { $item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe artifact LocalAppData path component: '+$cursor^) } } } }
>> "%ARTIFACT_CLEANUP_PS%" echo     $before=@^(^); foreach ^($raw in @^($state.GetValue^('Artifacts.Before.Paths',$null,$option^)^)^) { if ^(-not $raw^) { throw 'Empty artifact snapshot path' }; $text=^([string]$raw^).TrimEnd^('\'^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^('\'^); $match=@^($roots ^| Where-Object { $full -ieq $_.Target -or $full.StartsWith^($_.Target+'\',[StringComparison]::OrdinalIgnoreCase^) }^); if ^($full -ine $text -or $match.Count -ne 1^) { throw ^('Unsafe artifact snapshot path: '+$text^) }; $before += $full }
>> "%ARTIFACT_CLEANUP_PS%" echo     function Assert-NoReparsePath^([string]$boundary,[string]$path^) { $boundary=[IO.Path]::GetFullPath^($boundary^).TrimEnd^('\'^); $path=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); if ^(-not $path.StartsWith^($boundary+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe artifact cleanup path: '+$path^) }; $cursor=$boundary; if ^(Test-Path -LiteralPath $cursor^) { $item=Get-Item -LiteralPath $cursor -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks artifact cleanup: '+$cursor^) } }; foreach ^($part in $path.Substring^($boundary.Length^).TrimStart^('\'^).Split^('\'^)^) { if ^($part^) { $cursor=Join-Path $cursor $part; if ^(Test-Path -LiteralPath $cursor^) { $item=Get-Item -LiteralPath $cursor -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks artifact cleanup: '+$cursor^) } } } } }
>> "%ARTIFACT_CLEANUP_PS%" echo     function Remove-OwnedLeaf^([string]$path,[string]$boundary^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); Assert-NoReparsePath $boundary $full; if ^(-not ^(Test-Path -LiteralPath $full^)^) { return }; $item=Get-Item -LiteralPath $full -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks artifact cleanup: '+$full^) }; if ^($item.PSIsContainer^) { if ^(@^($item.GetFileSystemInfos^(^)^).Count -eq 0^) { $item.Delete^(^) }; return }; $item.Attributes=[IO.FileAttributes]::Normal; $item.Delete^(^) }
>> "%ARTIFACT_CLEANUP_PS%" echo     $owned=@^(^); foreach ^($raw in @^($state.GetValue^('Artifacts.Created.Paths',$null,$option^)^)^) { if ^(-not $raw^) { throw 'Empty artifact ownership path' }; $text=^([string]$raw^).TrimEnd^('\'^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^('\'^); if ^($full -ine $text^) { throw ^('Artifact ownership path is not canonical: '+$text^) }; $root=@^($roots ^| Where-Object { $full -ieq $_.Target -or $full.StartsWith^($_.Target+'\',[StringComparison]::OrdinalIgnoreCase^) } ^| Select-Object -First 1^); if ^($root.Count -ne 1 -or $before -icontains $full -or ^($root[0].Kind -eq 'nvim' -and $root[0].Local -ine $local^)^) { throw ^('Artifact ownership path is not exclusively setup-created: '+$full^) }; Assert-NoReparsePath $root[0].Parent $full; $owned += [pscustomobject]@{ Path=$full; Root=$root[0].Parent; Local=$root[0].Local; Retained=^((Split-Path -Leaf $full^) -like 'cp_setup_*.log'^) } }
>> "%ARTIFACT_CLEANUP_PS%" echo     if ^($env:ARTIFACT_CLEANUP_SCOPE -notin @^('target','elevated'^)^) { throw 'Invalid artifact cleanup scope' }; $selected=@^($owned ^| Where-Object { if ^($env:ARTIFACT_CLEANUP_SCOPE -eq 'target'^) { $_.Local -ieq $local } else { $_.Local -ine $local } }^)
>> "%ARTIFACT_CLEANUP_PS%" echo     foreach ^($entry in @^($selected ^| Where-Object { -not $_.Retained } ^| Sort-Object { $_.Path.Length } -Descending^)^) { Remove-OwnedLeaf $entry.Path $entry.Root }
>> "%ARTIFACT_CLEANUP_PS%" echo     $remaining=@^($selected ^| Where-Object { if ^($_.Retained -or -not ^(Test-Path -LiteralPath $_.Path^)^) { return $false }; $item=Get-Item -LiteralPath $_.Path -Force; return -not $item.PSIsContainer -or @^($item.GetFileSystemInfos^(^)^).Count -eq 0 }^); if ^($remaining.Count^) { throw ^('Artifact cleanup verification failed: '+^($remaining.Path -join ', '^)^) }
>> "%ARTIFACT_CLEANUP_PS%" echo     # Protected artifact metadata is committed only after both scoped workers succeed.
>> "%ARTIFACT_CLEANUP_PS%" echo } finally { $state.Dispose^(^) }
del "%ARTIFACT_CLEANUP_LOG%" >nul 2>nul
set "ARTIFACT_CLEANUP_SCOPE=target"
call :run_medium_worker "%ARTIFACT_CLEANUP_PS%" 120 >nul 2> "%ARTIFACT_CLEANUP_LOG%"
set "ARTIFACT_CLEANUP_EXIT=%ERRORLEVEL%"
if "%ARTIFACT_CLEANUP_EXIT%"=="0" (
    set "ARTIFACT_CLEANUP_SCOPE=elevated"
    "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ARTIFACT_CLEANUP_PS%" >nul 2>> "%ARTIFACT_CLEANUP_LOG%"
    set "ARTIFACT_CLEANUP_EXIT=!ERRORLEVEL!"
)
del "%ARTIFACT_CLEANUP_PS%" >nul 2>nul
call :publish_component_log "cp_setup_artifact_cleanup.log"
set "ARTIFACT_CLEANUP_PUBLISH_EXIT=%ERRORLEVEL%"
if "%ARTIFACT_CLEANUP_EXIT%"=="0" if not "%ARTIFACT_CLEANUP_PUBLISH_EXIT%"=="0" set "ARTIFACT_CLEANUP_EXIT=1"
if not "%ARTIFACT_CLEANUP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Setup-created temporary files could not be removed safely.
    echo Log: %CP_VISIBLE_TEMP%\cp_setup_artifact_cleanup.log
    exit /b %ARTIFACT_CLEANUP_EXIT%
)
del "%ARTIFACT_CLEANUP_LOG%" >nul 2>nul
set "STATE_METADATA_NAMES=Artifacts.LocalAppData.Roots;Artifacts.Created.Paths;Artifacts.Before.Paths"
call :commit_state_metadata
if errorlevel 1 exit /b %ERRORLEVEL%
exit /b 0

:clear_empty_state
"%POWERSHELL_EXE%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$config=@('Path.HadValue','Path.Entries','Path.Before','Path.Before.Kind','Path.Written','Path.Written.Kind','AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','AutoRun.Entry','AutoRun.Written','AutoRun.Written.Kind','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','Console.VirtualTerminal.Written','Console.VirtualTerminal.Written.Kind','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths','Pending.Artifacts.Intent','Acl.SourceArchive.Hash','Config.Managed','Config.MutationStarted','Snapshot.Complete','NvimData.Existed','Nvim.BootstrapStarted','Mason.Packages.Before','Mason.Packages','JdtlsWorkspace.Existed','JdtlsWorkspace.Path'); $components=@('Winget.Git','Winget.Neovim','Winget.Node','Winget.JDK','Winget.MSYS2','Pacman.Toolchain','Pacman.Packages'); $allowed=@('SchemaVersion','Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root','Install.Root'); try { $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); if (-not $key) { exit 0 }; try { $names=@($key.GetValueNames()); if (@($names | Where-Object { $_ -in $components }).Count) { exit 3 }; if (@($names | Where-Object { $_ -in $config -or $_ -like 'Env.*' }).Count) { exit 1 }; if (@($names | Where-Object { $_ -notin $allowed }).Count -or $key.SubKeyCount -ne 0) { exit 2 } } finally { $key.Dispose() }; [Microsoft.Win32.Registry]::LocalMachine.DeleteSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); $verify=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false); if ($verify) { $verify.Dispose(); exit 2 }; exit 0 } catch { exit 2 }" >nul 2>nul
set "CLEAR_EMPTY_EXIT=%ERRORLEVEL%"
if "%CLEAR_EMPTY_EXIT%"=="0" exit /b 0
if "%CLEAR_EMPTY_EXIT%"=="3" exit /b 0
if "%CLEAR_EMPTY_EXIT%"=="1" (
    echo [%ESC%[31mFAILED%ESC%[0m] CP setup configuration ownership state could not be cleared.
    exit /b 1
)
echo [%ESC%[31mFAILED%ESC%[0m] CP setup ownership state could not be cleared.
exit /b 1

:remove_nvim_generated_data
set "NVIM_CLEANUP_PS=%CP_RUNTIME_TEMP%\cp_setup_nvim_cleanup_%RANDOM%_%RANDOM%.ps1"
> "%NVIM_CLEANUP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%NVIM_CLEANUP_PS%" echo $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%NVIM_CLEANUP_PS%" echo $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $state^) { exit 0 }
>> "%NVIM_CLEANUP_PS%" echo try {
>> "%NVIM_CLEANUP_PS%" echo     $names=@^($state.GetValueNames^(^)^); if ^($names -notcontains 'NvimData.Existed'^) { exit 0 }; $metadata=@^('NvimData.Existed','Nvim.BootstrapStarted','Mason.Packages.Before','Mason.Packages','JdtlsWorkspace.Existed','JdtlsWorkspace.Path'^); $bootstrapStarted=0
>> "%NVIM_CLEANUP_PS%" echo     if ^($names -contains 'Nvim.BootstrapStarted'^) { if ^($state.GetValueKind^('Nvim.BootstrapStarted'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord^) { throw 'Invalid Neovim bootstrap state' }; $bootstrapStarted=[int]$state.GetValue^('Nvim.BootstrapStarted',0,$option^); if ^($bootstrapStarted -ne 1^) { throw 'Invalid Neovim bootstrap state' } }
>> "%NVIM_CLEANUP_PS%" echo     if ^($bootstrapStarted -eq 0^) { if ^($names -contains 'Mason.Packages'^) { throw 'Invalid Neovim bootstrap state' }; exit 0 }
>> "%NVIM_CLEANUP_PS%" echo     foreach ^($required in @^('Target.Sid','Target.Profile','Target.LocalAppData','NvimData.Root'^)^) { if ^($names -notcontains $required^) { throw ^('Missing protected path metadata: '+$required^) } }
>> "%NVIM_CLEANUP_PS%" echo     $sid=[string]$state.GetValue^('Target.Sid',$null,$option^); $profile=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.Profile',$null,$option^)^).TrimEnd^('\'^); $local=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.LocalAppData',$null,$option^)^).TrimEnd^('\'^); $target=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root',$null,$option^)^).TrimEnd^('\'^)
>> "%NVIM_CLEANUP_PS%" echo     if ^($sid -cne $env:CP_SETUP_TARGET_SID -or -not $local.StartsWith^($profile+'\',[StringComparison]::OrdinalIgnoreCase^) -or $target -ine ^(Join-Path $local 'nvim-data'^)^) { throw 'Protected Neovim path metadata is invalid' }
>> "%NVIM_CLEANUP_PS%" echo     function Assert-NoReparsePath^([string]$boundary,[string]$path^) { $boundary=[IO.Path]::GetFullPath^($boundary^).TrimEnd^('\'^); $path=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); if ^($path -ine $boundary -and -not $path.StartsWith^($boundary+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe cleanup path: '+$path^) }; $cursor=$boundary; if ^(Test-Path -LiteralPath $cursor^) { if ^([bool]^((Get-Item -LiteralPath $cursor -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$cursor^) } }; if ^($path.Length -gt $boundary.Length^) { foreach ^($part in $path.Substring^($boundary.Length^).TrimStart^('\'^).Split^('\'^)^) { if ^($part^) { $cursor=Join-Path $cursor $part; if ^(Test-Path -LiteralPath $cursor^) { if ^([bool]^((Get-Item -LiteralPath $cursor -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$cursor^) } } } } } }
>> "%NVIM_CLEANUP_PS%" echo     function Remove-SafeTree^([string]$path,[string]$boundary^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); Assert-NoReparsePath $boundary $full; if ^(-not ^(Test-Path -LiteralPath $full^)^) { return }; $item=Get-Item -LiteralPath $full -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$full^) }; if ^(-not $item.PSIsContainer^) { $item.Attributes=[IO.FileAttributes]::Normal; $item.Delete^(^); return }; foreach ^($child in @^($item.GetFileSystemInfos^(^)^)^) { $childFull=[IO.Path]::GetFullPath^($child.FullName^); if ^(-not $childFull.StartsWith^($full+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe cleanup child: '+$childFull^) }; if ^([bool]^($child.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$childFull^) }; Remove-SafeTree $childFull $full }; $item.Refresh^(^); $item.Delete^(^) }
>> "%NVIM_CLEANUP_PS%" echo     $existed=[int]$state.GetValue^('NvimData.Existed',1,$option^); $removedRoot=$false
>> "%NVIM_CLEANUP_PS%" echo     if ^($existed -eq 0^) { Assert-NoReparsePath $local $target; if ^(Test-Path -LiteralPath $target^) { Remove-SafeTree $target $local; $removedRoot=$true }; if ^(Test-Path -LiteralPath $target^) { throw 'Neovim data cleanup verification failed' } } else { $jdtlsExisted=[int]$state.GetValue^('JdtlsWorkspace.Existed',1,$option^); if ^($jdtlsExisted -eq 0 -and $names -contains 'JdtlsWorkspace.Path'^) { $workspaceRoot=[IO.Path]::GetFullPath^(^(Join-Path $target 'jdtls-workspaces'^)^).TrimEnd^('\'^); $jdtls=[IO.Path]::GetFullPath^([string]$state.GetValue^('JdtlsWorkspace.Path',$null,$option^)^).TrimEnd^('\'^); if ^(-not $jdtls.StartsWith^($workspaceRoot+'\',[StringComparison]::OrdinalIgnoreCase^) -or ^(Split-Path -Leaf $jdtls^) -notmatch '^cp-[0-9a-f]{16}$'^) { throw ^('Unsafe JDT LS workspace path: '+$jdtls^) }; Assert-NoReparsePath $target $jdtls; if ^(Test-Path -LiteralPath $jdtls^) { Remove-SafeTree $jdtls $target }; if ^(Test-Path -LiteralPath $jdtls^) { throw 'JDT LS workspace cleanup verification failed' } } }
>> "%NVIM_CLEANUP_PS%" echo     # Protected Neovim metadata is committed only after this target-user worker succeeds.
>> "%NVIM_CLEANUP_PS%" echo     if ^($removedRoot^) { $esc=[char]27; Write-Host ^('['+$esc+'[38;5;114mREMOVED'+$esc+'[0m] '+$target^) }
>> "%NVIM_CLEANUP_PS%" echo } finally { $state.Dispose^(^) }
call :run_medium_worker "%NVIM_CLEANUP_PS%" 600
set "NVIM_CLEANUP_EXIT=%ERRORLEVEL%"
del "%NVIM_CLEANUP_PS%" >nul 2>nul
if not "%NVIM_CLEANUP_EXIT%"=="0" exit /b %NVIM_CLEANUP_EXIT%
set "STATE_METADATA_NAMES=NvimData.Existed;Nvim.BootstrapStarted;Mason.Packages.Before;JdtlsWorkspace.Existed;JdtlsWorkspace.Path"
call :commit_state_metadata
exit /b %ERRORLEVEL%

:remove_managed_mason_packages
call :stop_setup_active_operation
if errorlevel 1 exit /b %ERRORLEVEL%
set "MASON_CLEANUP_PS=%CP_RUNTIME_TEMP%\cp_setup_mason_cleanup_%RANDOM%_%RANDOM%.ps1"
> "%MASON_CLEANUP_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MASON_CLEANUP_PS%" echo $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames; $state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $state^) { exit 0 }
>> "%MASON_CLEANUP_PS%" echo try {
>> "%MASON_CLEANUP_PS%" echo     $stateNames=@^($state.GetValueNames^(^)^); if ^($stateNames -notcontains 'Mason.Packages'^) { exit 0 }; if ^($stateNames -notcontains 'Nvim.BootstrapStarted' -or $state.GetValueKind^('Nvim.BootstrapStarted'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('Nvim.BootstrapStarted',0,$option^) -ne 1^) { throw 'Invalid Neovim bootstrap state' }; if ^([int]$state.GetValue^('NvimData.Existed',1,$option^) -eq 0^) { exit 0 }; foreach ^($required in @^('Target.Sid','Target.Profile','Target.LocalAppData','NvimData.Root'^)^) { if ^($stateNames -notcontains $required^) { throw ^('Missing protected path metadata: '+$required^) } }
>> "%MASON_CLEANUP_PS%" echo     $sid=[string]$state.GetValue^('Target.Sid',$null,$option^); $profile=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.Profile',$null,$option^)^).TrimEnd^('\'^); $local=[IO.Path]::GetFullPath^([string]$state.GetValue^('Target.LocalAppData',$null,$option^)^).TrimEnd^('\'^); $nvim=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root',$null,$option^)^).TrimEnd^('\'^); if ^($sid -cne $env:CP_SETUP_TARGET_SID -or -not $local.StartsWith^($profile+'\',[StringComparison]::OrdinalIgnoreCase^) -or $nvim -ine ^(Join-Path $local 'nvim-data'^)^) { throw 'Protected Mason path metadata is invalid' }
>> "%MASON_CLEANUP_PS%" echo     function Assert-NoReparsePath^([string]$boundary,[string]$path^) { $boundary=[IO.Path]::GetFullPath^($boundary^).TrimEnd^('\'^); $path=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); if ^($path -ine $boundary -and -not $path.StartsWith^($boundary+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe cleanup path: '+$path^) }; $cursor=$boundary; if ^(Test-Path -LiteralPath $cursor^) { if ^([bool]^((Get-Item -LiteralPath $cursor -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$cursor^) } }; if ^($path.Length -gt $boundary.Length^) { foreach ^($part in $path.Substring^($boundary.Length^).TrimStart^('\'^).Split^('\'^)^) { if ^($part^) { $cursor=Join-Path $cursor $part; if ^(Test-Path -LiteralPath $cursor^) { if ^([bool]^((Get-Item -LiteralPath $cursor -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$cursor^) } } } } } }
>> "%MASON_CLEANUP_PS%" echo     function Remove-SafeTree^([string]$path,[string]$boundary^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); Assert-NoReparsePath $boundary $full; if ^(-not ^(Test-Path -LiteralPath $full^)^) { return }; $item=Get-Item -LiteralPath $full -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$full^) }; if ^(-not $item.PSIsContainer^) { $item.Attributes=[IO.FileAttributes]::Normal; $item.Delete^(^); return }; foreach ^($child in @^($item.GetFileSystemInfos^(^)^)^) { $childFull=[IO.Path]::GetFullPath^($child.FullName^); if ^(-not $childFull.StartsWith^($full+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe cleanup child: '+$childFull^) }; if ^([bool]^($child.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point blocks cleanup: '+$childFull^) }; Remove-SafeTree $childFull $full }; $item.Refresh^(^); $item.Delete^(^) }
>> "%MASON_CLEANUP_PS%" echo     if ^($state.GetValueKind^('Mason.Packages'^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Invalid Mason ownership inventory kind.' }; $owned=@^($state.GetValue^('Mason.Packages',$null,$option^) ^| Where-Object { $_ }^); $seen=[Collections.Generic.HashSet[string]]::new^([StringComparer]::OrdinalIgnoreCase^); foreach ^($name in $owned^) { if ^([string]$name -notmatch '^^[A-Za-z0-9._-]+$' -or $name -in @^('.','..'^) -or -not $seen.Add^([string]$name^)^) { throw ^('Unsafe Mason package name: '+$name^) } }; $mason=[IO.Path]::GetFullPath^(^(Join-Path $nvim 'mason'^)^).TrimEnd^('\'^); $packagesRoot=[IO.Path]::GetFullPath^(^(Join-Path $mason 'packages'^)^).TrimEnd^('\'^); Assert-NoReparsePath $nvim $packagesRoot
>> "%MASON_CLEANUP_PS%" echo     foreach ^($name in $owned^) { $package=[IO.Path]::GetFullPath^(^(Join-Path $packagesRoot $name^)^); if ^(-not $package.StartsWith^($packagesRoot+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe Mason package path: '+$package^) }; Assert-NoReparsePath $nvim $package; $receipt=Join-Path $package 'mason-receipt.json'; if ^(Test-Path -LiteralPath $receipt^) { Assert-NoReparsePath $package $receipt; $data=Get-Content -LiteralPath $receipt -Raw ^| ConvertFrom-Json; foreach ^($group in @^('bin','share','opt'^)^) { $links=$data.links.$group; if ^($links^) { foreach ^($property in $links.PSObject.Properties^) { $base=[IO.Path]::GetFullPath^(^(Join-Path $mason $group^)^).TrimEnd^('\'^); $target=[IO.Path]::GetFullPath^(^(Join-Path $base $property.Name^)^); if ^(-not $target.StartsWith^($base+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe Mason link path: '+$target^) }; Assert-NoReparsePath $nvim $target; if ^(Test-Path -LiteralPath $target^) { Remove-SafeTree $target $nvim }; if ^(Test-Path -LiteralPath $target^) { throw ^('Mason link cleanup verification failed: '+$target^) } } } } }; if ^(Test-Path -LiteralPath $package^) { Remove-SafeTree $package $nvim }; if ^(Test-Path -LiteralPath $package^) { throw ^('Mason package cleanup verification failed: '+$package^) } }
>> "%MASON_CLEANUP_PS%" echo     $esc=[char]27; Write-Host ^('['+$esc+'[38;5;114mREMOVED'+$esc+'[0m] setup-managed Mason packages'^)
>> "%MASON_CLEANUP_PS%" echo } finally { $state.Dispose^(^) }
call :run_medium_worker "%MASON_CLEANUP_PS%" 600
set "MASON_CLEANUP_EXIT=%ERRORLEVEL%"
del "%MASON_CLEANUP_PS%" >nul 2>nul
if not "%MASON_CLEANUP_EXIT%"=="0" exit /b %MASON_CLEANUP_EXIT%
set "STATE_METADATA_NAMES=Mason.Packages;Mason.Inventory.Frozen"
call :commit_state_metadata
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
set "WINGET_FIND_PS=%CP_RUNTIME_TEMP%\cp_setup_find_winget_%RANDOM%_%RANDOM%.ps1"
> "%WINGET_FIND_PS%" echo $ErrorActionPreference = 'Stop'
>> "%WINGET_FIND_PS%" echo . $env:PROCESS_TREE_PS
>> "%WINGET_FIND_PS%" echo try {
>> "%WINGET_FIND_PS%" echo     $programFiles = [IO.Path]::GetFullPath^([Environment]::GetFolderPath^([Environment+SpecialFolder]::ProgramFiles^)^).TrimEnd^('\'^)
>> "%WINGET_FIND_PS%" echo     $windowsApps = [IO.Path]::GetFullPath^(^(Join-Path $programFiles 'WindowsApps'^)^).TrimEnd^('\'^)
>> "%WINGET_FIND_PS%" echo     if ^(-not ^(Test-Path -LiteralPath $windowsApps -PathType Container^)^) { exit 1 }
>> "%WINGET_FIND_PS%" echo     $trustedOwners=@^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^); $untrusted=@^('S-1-1-0','S-1-5-11','S-1-5-32-545',$env:CP_SETUP_TARGET_SID^); $mask=[Security.AccessControl.FileSystemRights]::WriteData -bor [Security.AccessControl.FileSystemRights]::AppendData -bor [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor [Security.AccessControl.FileSystemRights]::WriteAttributes -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%WINGET_FIND_PS%" echo     function Assert-Protected^([string]$path^) { $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Reparse point in protected path: '+$path^) }; $acl=Get-Acl -LiteralPath $path; try { $ownerSid=^([Security.Principal.NTAccount]$acl.Owner^).Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { $ownerSid=$acl.Owner }; if ^($trustedOwners -notcontains $ownerSid^) { throw ^('Untrusted protected-path owner: '+$path^) }; foreach ^($ace in $acl.Access^) { if ^($ace.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or -not ^([int64]$ace.FileSystemRights -band [int64]$mask^)^) { continue }; try { $sid=$ace.IdentityReference.Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { $sid=[string]$ace.IdentityReference }; if ^($untrusted -contains $sid^) { throw ^('Protected path is writable by an untrusted identity: '+$path^) } } }
>> "%WINGET_FIND_PS%" echo     Assert-Protected $programFiles; Assert-Protected $windowsApps
>> "%WINGET_FIND_PS%" echo     $packages = @^(Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction Stop ^| Where-Object { $_.Name -ceq 'Microsoft.DesktopAppInstaller' -and $_.PackageFamilyName -match '_8wekyb3d8bbwe$' } ^| Sort-Object Version -Descending^)
>> "%WINGET_FIND_PS%" echo     foreach ^($package in $packages^) {
>> "%WINGET_FIND_PS%" echo         try {
>> "%WINGET_FIND_PS%" echo             if ^(-not $package.InstallLocation^) { continue }
>> "%WINGET_FIND_PS%" echo             $location=[IO.Path]::GetFullPath^([string]$package.InstallLocation^).TrimEnd^('\'^); $prefix=$windowsApps+'\'
>> "%WINGET_FIND_PS%" echo             if ^(-not $location.StartsWith^($prefix,[StringComparison]::OrdinalIgnoreCase^) -or ^(Split-Path -Leaf $location^) -notmatch '^Microsoft\.DesktopAppInstaller_'^) { continue }
>> "%WINGET_FIND_PS%" echo             $candidate=[IO.Path]::GetFullPath^(^(Join-Path $location 'winget.exe'^)^); if ^(-not $candidate.StartsWith^($location+'\',[StringComparison]::OrdinalIgnoreCase^) -or ^(Split-Path -Leaf $candidate^) -cne 'winget.exe' -or -not ^(Test-Path -LiteralPath $candidate -PathType Leaf^)^) { continue }
>> "%WINGET_FIND_PS%" echo             $cursor=$windowsApps; foreach ^($part in $location.Substring^($windowsApps.Length^).TrimStart^('\'^).Split^('\'^)^) { if ^($part^) { $cursor=Join-Path $cursor $part; Assert-Protected $cursor } }; Assert-Protected $candidate
>> "%WINGET_FIND_PS%" echo             $signature=Get-AuthenticodeSignature -LiteralPath $candidate; if ^($signature.Status -ne [Management.Automation.SignatureStatus]::Valid -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation'^) { continue }
>> "%WINGET_FIND_PS%" echo             $stdout=Join-Path $env:CP_RUNTIME_TEMP ^('cp_setup_winget_probe_'+[guid]::NewGuid^(^).ToString^('N'^)+'.out'^); $stderr=$stdout+'.err'
>> "%WINGET_FIND_PS%" echo             try { $process=Start-Process -FilePath $candidate -ArgumentList '--version' -WorkingDirectory $location -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr; $probeExit=Wait-BoundedProcess $process 15000 $env:TASKKILL_EXE; if ^($probeExit -eq 124^) { exit 124 }; if ^($probeExit -eq 0^) { Write-Output $candidate; exit 0 } } finally { Remove-Item -LiteralPath $stdout,$stderr -ErrorAction SilentlyContinue }
>> "%WINGET_FIND_PS%" echo         } catch { continue }
>> "%WINGET_FIND_PS%" echo     }
>> "%WINGET_FIND_PS%" echo     exit 1
>> "%WINGET_FIND_PS%" echo } catch { exit 1 }
set "WINGET_FINDER_OUT=%CP_RUNTIME_TEMP%\cp_setup_winget_path_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%WINGET_FIND_PS%" > "%WINGET_FINDER_OUT%" 2>nul
for /F "usebackq delims=" %%P in ("%WINGET_FINDER_OUT%") do if not defined WINGET set "WINGET=%%P"
del "%WINGET_FINDER_OUT%" >nul 2>nul
del "%WINGET_FIND_PS%" >nul 2>nul
if defined WINGET exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] winget was not found.
exit /b 1

:winget_has_package
call :require_winget
if errorlevel 1 exit /b 2
set "WINGET_LIST=%CP_RUNTIME_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.txt"
set "WINGET_QUERY_ERROR=%CP_RUNTIME_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.err"
set "WINGET_QUERY_EXIT_FILE=%CP_RUNTIME_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.exit"
set "WINGET_QUERY_PS=%CP_RUNTIME_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.ps1"
set "WINGET_PACKAGE_ID=%~1"
> "%WINGET_QUERY_PS%" echo $ErrorActionPreference = 'Stop'
>> "%WINGET_QUERY_PS%" echo . $env:PROCESS_TREE_PS
>> "%WINGET_QUERY_PS%" echo try {
>> "%WINGET_QUERY_PS%" echo     $arguments = @^('list','--id',$env:WINGET_PACKAGE_ID,'--exact','--source','winget','--scope','machine','--disable-interactivity'^)
>> "%WINGET_QUERY_PS%" echo     $process = Start-Process -FilePath $env:WINGET -ArgumentList $arguments -WorkingDirectory ^(Split-Path -Parent $env:WINGET^) -WindowStyle Hidden -PassThru -RedirectStandardOutput $env:WINGET_LIST -RedirectStandardError $env:WINGET_QUERY_ERROR
>> "%WINGET_QUERY_PS%" echo     $queryExit=Wait-BoundedProcess $process 60000 $env:TASKKILL_EXE; if ^($queryExit -eq 124^) { exit 124 }
>> "%WINGET_QUERY_PS%" echo     [IO.File]::WriteAllText^($env:WINGET_QUERY_EXIT_FILE,[string]$queryExit^)
>> "%WINGET_QUERY_PS%" echo     exit 0
>> "%WINGET_QUERY_PS%" echo } catch { exit 1 }
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%WINGET_QUERY_PS%"
set "WINGET_QUERY_RUN_EXIT=%ERRORLEVEL%"
if "%WINGET_QUERY_RUN_EXIT%"=="124" set "UNINSTALL_TIMEOUT_SEEN=1"
del "%WINGET_QUERY_PS%" >nul 2>nul
if not "%WINGET_QUERY_RUN_EXIT%"=="0" (
    del "%WINGET_LIST%" "%WINGET_QUERY_ERROR%" "%WINGET_QUERY_EXIT_FILE%" >nul 2>nul
    echo [%ESC%[31mFAILED%ESC%[0m] winget could not query installed package %~1.
    exit /b 2
)
set "WINGET_QUERY_EXIT="
set /p "WINGET_QUERY_EXIT="<"%WINGET_QUERY_EXIT_FILE%"
del "%WINGET_QUERY_ERROR%" "%WINGET_QUERY_EXIT_FILE%" >nul 2>nul
if "%WINGET_QUERY_EXIT%"=="-1978335212" (
    del "%WINGET_LIST%" >nul 2>nul
    exit /b 1
)
if not "%WINGET_QUERY_EXIT%"=="0" (
    del "%WINGET_LIST%" >nul 2>nul
    echo [%ESC%[31mFAILED%ESC%[0m] winget could not query installed package %~1.
    exit /b 2
)
"%FINDSTR_EXE%" /I /C:"%~1" "%WINGET_LIST%" >nul
set "WINGET_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST%" >nul 2>nul
exit /b %WINGET_EXIT%

:find_msys2_shell
set "MSYS2_SHELL="
set "MSYS2_FINDER=%CP_RUNTIME_TEMP%\cp_setup_find_msys2_%RANDOM%_%RANDOM%.cmd"
set "MSYS2_FIND_PS=%CP_RUNTIME_TEMP%\cp_setup_find_msys2_%RANDOM%_%RANDOM%.ps1"
> "%MSYS2_FIND_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MSYS2_FIND_PS%" echo try {
>> "%MSYS2_FIND_PS%" echo     $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames; $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey^($env:CP_SETUP_TARGET_STATE_RELATIVE,$false^); if ^(-not $key^) { exit 1 }
>> "%MSYS2_FIND_PS%" echo     try { $names=@^($key.GetValueNames^(^)^); $value=$null; foreach ^($name in @^('Pacman.Shell.Path','Winget.MSYS2.Path'^)^) { if ^($names -contains $name^) { $value=[string]$key.GetValue^($name,$null,$option^); break } }; if ^(-not $value^) { exit 1 } } finally { $key.Dispose^(^) }
>> "%MSYS2_FIND_PS%" echo     $shell=[IO.Path]::GetFullPath^($value^); $expected=[IO.Path]::GetFullPath^('C:\msys64\msys2_shell.cmd'^); $root=[IO.Path]::GetFullPath^('C:\msys64'^).TrimEnd^('\'^); $bash=[IO.Path]::GetFullPath^(^(Join-Path $root 'usr\bin\bash.exe'^)^)
>> "%MSYS2_FIND_PS%" echo     if ^($shell -ine $expected -or -not ^(Test-Path -LiteralPath $shell -PathType Leaf^) -or -not ^(Test-Path -LiteralPath $bash -PathType Leaf^)^) { exit 2 }
>> "%MSYS2_FIND_PS%" echo     $trustedOwners=@^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^); $untrusted=@^('S-1-1-0','S-1-5-11','S-1-5-32-545',$env:CP_SETUP_TARGET_SID^); $mask=[Security.AccessControl.FileSystemRights]::WriteData -bor [Security.AccessControl.FileSystemRights]::AppendData -bor [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor [Security.AccessControl.FileSystemRights]::WriteAttributes -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%MSYS2_FIND_PS%" echo     foreach ^($path in @^($root,^(Join-Path $root 'usr'^),^(Join-Path $root 'usr\bin'^),$shell,$bash^)^) { $item=Get-Item -LiteralPath $path -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { exit 2 }; $acl=Get-Acl -LiteralPath $path; try { $ownerSid=^([Security.Principal.NTAccount]$acl.Owner^).Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { $ownerSid=$acl.Owner }; if ^($trustedOwners -notcontains $ownerSid^) { exit 2 }; foreach ^($ace in $acl.Access^) { if ^($ace.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or -not ^([int64]$ace.FileSystemRights -band [int64]$mask^)^) { continue }; try { $sid=$ace.IdentityReference.Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { $sid=[string]$ace.IdentityReference }; if ^($untrusted -contains $sid^) { exit 2 } } }
>> "%MSYS2_FIND_PS%" echo     Write-Output $shell; exit 0
>> "%MSYS2_FIND_PS%" echo } catch { exit 2 }
> "%MSYS2_FINDER%" echo @echo off
>> "%MSYS2_FINDER%" echo "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%MSYS2_FIND_PS%"
>> "%MSYS2_FINDER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call "%MSYS2_FINDER%""
call :search_command "MSYS2" "@env" "MSYS2_SHELL"
set "MSYS2_EXIT=!ERRORLEVEL!"
del "%MSYS2_FINDER%" >nul 2>nul
del "%MSYS2_FIND_PS%" >nul 2>nul
exit /b !MSYS2_EXIT!

:detect_msys2_shell
set "SEARCH_COMMAND_INPUT=if exist ""C:\msys64\msys2_shell.cmd"" if exist ""C:\msys64\usr\bin\bash.exe"" echo C:\msys64\msys2_shell.cmd"
call :search_command "MSYS2" "@env" "MSYS2_SHELL"
exit /b %ERRORLEVEL%

:has_pacman_toolchain
call :load_managed_pacman_packages
if errorlevel 1 exit /b 2
call :find_msys2_shell
if errorlevel 2 exit /b 2
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
set "PACMAN_CHECKER=%CP_RUNTIME_TEMP%\cp_setup_find_pacman_%RANDOM%_%RANDOM%.cmd"
> "%PACMAN_CHECKER%" echo @echo off
>> "%PACMAN_CHECKER%" echo set "MSYSTEM=MINGW64"
>> "%PACMAN_CHECKER%" echo set "CHERE_INVOKING=enabled_from_arguments"
>> "%PACMAN_CHECKER%" echo "%MSYS2_BASH%" -lc "p=$(mktemp) || exit 2; pacman -Qq >$p || { rm -f $p; exit 2; }; for package in %PACMAN_PACKAGES%; do grep -Fxq -- $package $p; s=$?; if [ $s -eq 0 ]; then rm -f $p; exit 0; fi; if [ $s -ne 1 ]; then rm -f $p; exit 2; fi; done; rm -f $p; exit 1"
>> "%PACMAN_CHECKER%" echo exit /b %%ERRORLEVEL%%
set "SEARCH_COMMAND_INPUT=call "%PACMAN_CHECKER%""
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
set "SEARCH_RESULT_FILE=%CP_RUNTIME_TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.txt"
set "SEARCH_PS=%CP_RUNTIME_TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.ps1"
> "%SEARCH_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SEARCH_PS%" echo . $env:PROCESS_TREE_PS
>> "%SEARCH_PS%" echo $label=$env:SEARCH_LABEL; $command=$env:SEARCH_COMMAND; $output=$env:SEARCH_RESULT_FILE
>> "%SEARCH_PS%" echo $wrapper=Join-Path $env:CP_RUNTIME_TEMP ^('cp_setup_search_'+[guid]::NewGuid^(^).ToString^('N'^)+'.cmd'^); $q=[char]34
>> "%SEARCH_PS%" echo $esc=[char]27; $cr=[char]13; $clear=$esc+'[2K'; $action='['+$esc+'[38;5;183m'+$env:SEARCH_ACTION+$esc+'[0m]'; $success='['+$esc+'['+$env:SEARCH_SUCCESS_COLOR+'m'+$env:SEARCH_SUCCESS+$esc+'[0m]'; $successNoNewline=$env:SEARCH_SUCCESS_NO_NEWLINE -eq '1'
>> "%SEARCH_PS%" echo [int]$timeoutSeconds=0; if ^(-not [int]::TryParse^($env:UNINSTALL_SEARCH_TIMEOUT_SECONDS,[ref]$timeoutSeconds^) -or $timeoutSeconds -lt 1^) { $timeoutSeconds=120 }
>> "%SEARCH_PS%" echo try {
>> "%SEARCH_PS%" echo     [IO.File]::WriteAllLines^($wrapper,@^('@echo off',^($command+' 1^>'+$q+$output+$q+' 2^>nul'^),'exit /b %%ERRORLEVEL%%'^)^)
>> "%SEARCH_PS%" echo     $arguments='/d /s /c ""'+$wrapper+'""'; $process=Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:CP_RUNTIME_TEMP -WindowStyle Hidden -PassThru
>> "%SEARCH_PS%" echo     $frames=@^([char]92,'-','/','^|'^); $i=0; $started=[Diagnostics.Stopwatch]::StartNew^(^); $timedOut=$false
>> "%SEARCH_PS%" echo     while ^(-not $process.HasExited^) { Write-Host -NoNewline ^($cr+$clear+$action+' '+$frames[$i %% $frames.Count]+' '+$label^); [Console]::Out.Flush^(^); if ^($started.Elapsed.TotalSeconds -ge $timeoutSeconds^) { $timedOut=$true; Stop-VerifiedProcessTree $process $env:TASKKILL_EXE; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SEARCH_PS%" echo     if ^($timedOut^) { $exitCode=124 } else { $exitCode=Wait-BoundedProcess $process 1000 $env:TASKKILL_EXE }
>> "%SEARCH_PS%" echo     if ^(-not ^(Test-Path -LiteralPath $output^)^) { [IO.File]::WriteAllText^($output,''^) }
>> "%SEARCH_PS%" echo     if ^($exitCode -eq 0^) { if ^($successNoNewline^) { Write-Host -NoNewline ^($cr+$clear+$success+' '+$label^) } else { Write-Host ^($cr+$clear+$success+' '+$label^) } } else { Write-Host -NoNewline ^($cr+$clear^) }
>> "%SEARCH_PS%" echo     exit $exitCode
>> "%SEARCH_PS%" echo } finally { Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue }
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SEARCH_PS%"
set "SEARCH_EXIT=%ERRORLEVEL%"
set "SEARCH_VALUE="
for /F "usebackq delims=" %%P in ("%SEARCH_RESULT_FILE%") do if not defined SEARCH_VALUE set "SEARCH_VALUE=%%P"
del "%SEARCH_PS%" >nul 2>nul
del "%SEARCH_RESULT_FILE%" >nul 2>nul
if "%SEARCH_EXIT%"=="124" (
    endlocal & set "%~3=%SEARCH_VALUE%" & set "UNINSTALL_TIMEOUT_SEEN=1" & exit /b 124
)
endlocal & set "%~3=%SEARCH_VALUE%" & exit /b %SEARCH_EXIT%

:run_command_spinner
set "SPIN_LABEL=%~1"
set "SPIN_HINT=%~2"
for %%L in ("%~3") do set "SPIN_LOG_NAME=%%~nxL"
set "SPIN_LOG=%CP_RUNTIME_TEMP%\%SPIN_LOG_NAME%"
set "SPIN_ACTION=%~4"
set "SPIN_SUCCESS=%~5"
set "SPIN_DEFER_RESULT=%~6"
set "SPIN_HIDE_FAILURE=%~7"
set "SPIN_PS=%CP_RUNTIME_TEMP%\cp_setup_command_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo . $env:PROCESS_TREE_PS
>> "%SPIN_PS%" echo $label = $env:SPIN_LABEL
>> "%SPIN_PS%" echo $hint = $env:SPIN_HINT
>> "%SPIN_PS%" echo $log = $env:SPIN_LOG
>> "%SPIN_PS%" echo $cmd = [string]$env:UNINSTALL_CMD
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:CP_RUNTIME_TEMP ('cp_setup_command_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:SPIN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:SPIN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo $deferResult = $env:SPIN_DEFER_RESULT -eq '1'
>> "%SPIN_PS%" echo $hideFailure = $env:SPIN_HIDE_FAILURE -eq '1'
>> "%SPIN_PS%" echo [int]$timeoutSeconds = 0
>> "%SPIN_PS%" echo if ^(-not [int]::TryParse^($env:UNINSTALL_COMMAND_TIMEOUT_SECONDS, [ref]$timeoutSeconds^) -or $timeoutSeconds -lt 1^) { $timeoutSeconds = 1800 }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $cmd + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SPIN_PS%" echo $workingDirectory=$env:SPIN_WORKDIR; if ^(-not $workingDirectory^) { $workingDirectory=$env:CP_RUNTIME_TEMP }; $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $workingDirectory -WindowStyle Hidden -PassThru
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo $started = [Diagnostics.Stopwatch]::StartNew^(^)
>> "%SPIN_PS%" echo $timedOut = $false
>> "%SPIN_PS%" echo while ^(-not $process.HasExited^) { $text = $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label; if ^($hint^) { $text += ' ^(' + $hint + '^)' }; Write-Host -NoNewline ^($cr + $clear + $text^); [Console]::Out.Flush^(^); if ^($started.Elapsed.TotalSeconds -ge $timeoutSeconds^) { $timedOut = $true; Stop-VerifiedProcessTree $process $env:TASKKILL_EXE; try { ^('Timed out after ' + $timeoutSeconds + ' seconds.'^) ^| Add-Content -LiteralPath $log -ErrorAction Stop } catch {}; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo if ^($timedOut^) { $exitCode = 124 } else { $exitCode = Wait-BoundedProcess $process 1000 $env:TASKKILL_EXE }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0 -and $deferResult) { Write-Host -NoNewline ($cr + $clear) } elseif ($exitCode -eq 0) { Write-Host ($cr + $clear + $success + ' ' + $label) } elseif ($hideFailure) { Write-Host -NoNewline ($cr + $clear) } else { Write-Host ($cr + $clear + '[' + $esc + '[31mFAILED' + $esc + '[0m] ' + $label) }
>> "%SPIN_PS%" echo exit $exitCode
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="124" set "UNINSTALL_TIMEOUT_SEEN=1"
del "%SPIN_PS%" >nul 2>nul
call :publish_component_log "%SPIN_LOG_NAME%"
set "SPIN_PUBLISH_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="0" if not "%SPIN_PUBLISH_EXIT%"=="0" set "SPIN_EXIT=1"
set "SPIN_LOG_NAME="
exit /b %SPIN_EXIT%

:run_pacman_spinner
set "PACMAN_ACTION=%~1"
set "PACMAN_SUCCESS=%~2"
set "PACMAN_DEFER_RESULT=%~3"
set "SPIN_PS=%CP_RUNTIME_TEMP%\cp_setup_pacman_uninstall_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo . $env:PROCESS_TREE_PS
>> "%SPIN_PS%" echo $label = 'MSYS2 CP toolchain via pacman'
>> "%SPIN_PS%" echo $hint = 'this may take a while'
>> "%SPIN_PS%" echo $log = Join-Path $env:CP_RUNTIME_TEMP 'cp_setup_pacman_uninstall.log'
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:CP_RUNTIME_TEMP ('cp_setup_pacman_uninstall_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:PACMAN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:PACMAN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo $deferResult = $env:PACMAN_DEFER_RESULT -eq '1'
>> "%SPIN_PS%" echo [int]$timeoutSeconds = 0
>> "%SPIN_PS%" echo if ^(-not [int]::TryParse^($env:UNINSTALL_COMMAND_TIMEOUT_SECONDS, [ref]$timeoutSeconds^) -or $timeoutSeconds -lt 1^) { $timeoutSeconds = 1800 }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $bash = Join-Path (Split-Path -Parent $env:MSYS2_SHELL) 'usr\bin\bash.exe'
>> "%SPIN_PS%" echo if (-not (Test-Path -LiteralPath $bash)) { 'Could not find MSYS2 bash.exe.' ^| Set-Content -LiteralPath $log; Write-Host ($action + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $q + $bash + $q + ' -lc ' + $q + $env:PACMAN_COMMAND + $q + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off','set "MSYSTEM=MINGW64"','set "CHERE_INVOKING=enabled_from_arguments"',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SPIN_PS%" echo $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:CP_RUNTIME_TEMP -WindowStyle Hidden -PassThru
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo $started = [Diagnostics.Stopwatch]::StartNew^(^)
>> "%SPIN_PS%" echo $timedOut = $false
>> "%SPIN_PS%" echo while ^(-not $process.HasExited^) { Write-Host -NoNewline ^($cr + $clear + $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label + ' ^(' + $hint + '^)'^); [Console]::Out.Flush^(^); if ^($started.Elapsed.TotalSeconds -ge $timeoutSeconds^) { $timedOut = $true; Stop-VerifiedProcessTree $process $env:TASKKILL_EXE; try { ^('Timed out after ' + $timeoutSeconds + ' seconds.'^) ^| Add-Content -LiteralPath $log -ErrorAction Stop } catch {}; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo if ^($timedOut^) { $exitCode = 124 } else { $exitCode = Wait-BoundedProcess $process 1000 $env:TASKKILL_EXE }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0 -and $deferResult) { Write-Host -NoNewline ($cr + $clear) } elseif ($exitCode -eq 0) { Write-Host ($cr + $clear + $success + ' ' + $label) } else { Write-Host ($cr + $clear + '[' + $esc + '[31mFAILED' + $esc + '[0m] ' + $label) }
>> "%SPIN_PS%" echo exit $exitCode
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="124" set "UNINSTALL_TIMEOUT_SEEN=1"
del "%SPIN_PS%" >nul 2>nul
call :publish_component_log "cp_setup_pacman_uninstall.log"
set "SPIN_PUBLISH_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="0" if not "%SPIN_PUBLISH_EXIT%"=="0" set "SPIN_EXIT=1"
exit /b %SPIN_EXIT%

:schedule_repo_removal
set "CP_DELETE_ROOT=%ROOT%"
set "DELETE_PS=%CP_RUNTIME_TEMP%\cp_setup_delete_%RANDOM%_%RANDOM%.ps1"
if "%CP_ELEVATION_PARENT%"=="1" (
    set "ELEVATED_REMOVE_REQUEST=1"
    cd /d "%SYSTEM32%"
    exit /b 0
)
cd /d "%CP_RUNTIME_TEMP%"
> "%DELETE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%DELETE_PS%" echo $root = [IO.Path]::GetFullPath^($env:CP_DELETE_ROOT^)
>> "%DELETE_PS%" echo $marker = Join-Path $root 'scripts\install.bat'
>> "%DELETE_PS%" echo function Remove-TreeNoFollow^([string]$path,[string]$boundary^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^('\'^); if ^($full -ine $boundary -and -not $full.StartsWith^($boundary+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Unsafe repository cleanup path' }; if ^(-not ^(Test-Path -LiteralPath $full^)^) { return }; $item=Get-Item -LiteralPath $full -Force; if ^([bool]^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { $item.Delete^(^); return }; if ^(-not $item.PSIsContainer^) { $item.Attributes=[IO.FileAttributes]::Normal; $item.Delete^(^); return }; foreach ^($child in @^($item.GetFileSystemInfos^(^)^)^) { $childFull=[IO.Path]::GetFullPath^($child.FullName^); if ^(-not $childFull.StartsWith^($full+'\',[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Unsafe repository cleanup child' }; Remove-TreeNoFollow $childFull $full }; $item.Refresh^(^); $item.Delete^(^) }
>> "%DELETE_PS%" echo try {
>> "%DELETE_PS%" echo     if ^($root -eq [IO.Path]::GetPathRoot^($root^) -or -not ^(Test-Path -LiteralPath $marker^) -or [bool]^((Get-Item -LiteralPath $root -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw 'Unsafe CP setup folder path' }
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
>> "%DELETE_PS%" echo         try { Remove-TreeNoFollow $staged $staged; if ^(-not ^(Test-Path -LiteralPath $staged^)^) { exit 0 } } catch { Start-Sleep -Milliseconds 500 }
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
>> "%DELETE_PS%" echo     if ^($env:CP_RUNTIME_SECURE -eq '1'^) { try { $runtime=[IO.Path]::GetFullPath^($env:CP_RUNTIME_TEMP^).TrimEnd^('\'^); $programData=[IO.Path]::GetFullPath^([Environment]::GetFolderPath^([Environment+SpecialFolder]::CommonApplicationData^)^).TrimEnd^('\'^); $base=[IO.Path]::GetFullPath^(^(Join-Path $programData 'my-cp-setup-runtime'^)^).TrimEnd^('\'^); if ^($runtime.StartsWith^($base+'\',[StringComparison]::OrdinalIgnoreCase^) -and ^(Split-Path -Leaf $runtime^) -match '^[0-9a-f]{32}$' -and ^(Test-Path -LiteralPath $runtime^)^) { $runtimeItem=Get-Item -LiteralPath $runtime -Force; if ^(-not [bool]^($runtimeItem.Attributes -band [IO.FileAttributes]::ReparsePoint^) -and @^($runtimeItem.GetFileSystemInfos^(^)^).Count -eq 0^) { $runtimeItem.Delete^(^) } }; if ^(Test-Path -LiteralPath $base^) { $baseItem=Get-Item -LiteralPath $base -Force; if ^(-not [bool]^($baseItem.Attributes -band [IO.FileAttributes]::ReparsePoint^) -and @^($baseItem.GetFileSystemInfos^(^)^).Count -eq 0^) { $baseItem.Delete^(^) } } } catch {} }
>> "%DELETE_PS%" echo }
if "%EARLY_ELEVATED%"=="1" (
    start "" /b /d "%SYSTEM32%" "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%DELETE_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32%" -ExecTemp "%CP_RUNTIME_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 300 -CleanupExecTemp
    set "DELETE_START_EXIT=%ERRORLEVEL%"
    if "!DELETE_START_EXIT!"=="0" set "KEEP_RUNTIME_FOR_DELETE=1"
    exit /b !DELETE_START_EXIT!
)
start "" /b /d "%SYSTEM32%" "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%DELETE_PS%"
set "DELETE_START_EXIT=%ERRORLEVEL%"
if "%DELETE_START_EXIT%"=="0" if "%CP_RUNTIME_SECURE%"=="1" set "KEEP_RUNTIME_FOR_DELETE=1"
exit /b %DELETE_START_EXIT%

:failed
set "UNINSTALL_FAILURE_EXIT=%ERRORLEVEL%"
if "%UNINSTALL_FAILURE_EXIT%"=="0" set "UNINSTALL_FAILURE_EXIT=1"
if "%UNINSTALL_TIMEOUT_SEEN%"=="1" set "UNINSTALL_FAILURE_EXIT=124"
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup uninstall did not complete.
call :wait_to_finish
call :cleanup_secure_runtime >nul 2>nul
exit /b %UNINSTALL_FAILURE_EXIT%

::__CP_SOURCE_LOCK_NATIVE_BEGIN__
::using System;
::using System.ComponentModel;
::using System.IO;
::using System.Runtime.InteropServices;
::using System.Security.Cryptography;
::using System.Text;
::using Microsoft.Win32.SafeHandles;
::namespace CpSetup.Native {
::public sealed class SourceLease : IDisposable {
::const uint GENERIC_READ=0x80000000,FILE_SHARE_READ=1,OPEN_EXISTING=3,FILE_FLAG_OPEN_REPARSE_POINT=0x00200000;
::static readonly IntPtr InvalidHandle=new IntPtr(-1);IntPtr fileHandle=IntPtr.Zero;public string Hash{get;private set;}
::[StructLayout(LayoutKind.Sequential)]struct FILETIME{public uint Low,High;}
::[StructLayout(LayoutKind.Sequential)]struct BY_HANDLE_FILE_INFORMATION{public uint Attributes;public FILETIME Creation,Access,Write;public uint VolumeSerial,SizeHigh,SizeLow,Links,IndexHigh,IndexLow;}
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern IntPtr CreateFileW(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
::[DllImport("kernel32.dll")]static extern bool CloseHandle(IntPtr handle);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool GetFileInformationByHandle(IntPtr handle,out BY_HANDLE_FILE_INFORMATION info);
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern uint GetFinalPathNameByHandleW(IntPtr handle,System.Text.StringBuilder path,uint length,uint flags);
::static string FinalPath(IntPtr handle){System.Text.StringBuilder text=new System.Text.StringBuilder(32768);uint length=GetFinalPathNameByHandleW(handle,text,(uint)text.Capacity,0);if(length==0||length>=text.Capacity)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not resolve locked source path.");string value=text.ToString();if(value.StartsWith("\\\\?\\UNC\\",StringComparison.OrdinalIgnoreCase))value="\\\\"+value.Substring(8);else if(value.StartsWith("\\\\?\\",StringComparison.OrdinalIgnoreCase))value=value.Substring(4);return Path.GetFullPath(value).TrimEnd('\\');}
::static IntPtr Open(string path,uint access,uint share,uint flags){IntPtr handle=CreateFileW(path,access,share,IntPtr.Zero,OPEN_EXISTING,flags,IntPtr.Zero);if(handle==InvalidHandle)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not lock source path: "+path);try{BY_HANDLE_FILE_INFORMATION info;if(!GetFileInformationByHandle(handle,out info))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not inspect locked source path.");if((info.Attributes&0x400)!=0)throw new IOException("Locked source path is a reparse point: "+path);if(!String.Equals(FinalPath(handle),Path.GetFullPath(path).TrimEnd('\\'),StringComparison.OrdinalIgnoreCase))throw new IOException("Locked source path identity changed: "+path);return handle;}catch{CloseHandle(handle);throw;}}
::static void NoReparseChain(string path){string full=Path.GetFullPath(path);string root=Path.GetPathRoot(full);string current=root;string relative=full.Substring(root.Length);foreach(string part in relative.Split(new[]{'\\'},StringSplitOptions.RemoveEmptyEntries)){current=Path.Combine(current,part);FileAttributes attributes=File.GetAttributes(current);if((attributes&FileAttributes.ReparsePoint)!=0)throw new IOException("Source path contains a reparse point: "+current);}}
::string ComputeHash(){using(SafeFileHandle safe=new SafeFileHandle(fileHandle,false)){using(FileStream stream=new FileStream(safe,FileAccess.Read,4096,false)){stream.Position=0;using(SHA256 sha=SHA256.Create()){return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-","").ToLowerInvariant();}}}}
::public static SourceLease Acquire(string source){SourceLease lease=new SourceLease();try{string full=Path.GetFullPath(source);if(!File.Exists(full))throw new FileNotFoundException("Uninstaller source is missing.",full);NoReparseChain(full);lease.fileHandle=Open(full,GENERIC_READ,FILE_SHARE_READ,FILE_FLAG_OPEN_REPARSE_POINT);lease.Hash=lease.ComputeHash();return lease;}catch{lease.Dispose();throw;}}
::public string ReadAllText(){using(SafeFileHandle safe=new SafeFileHandle(fileHandle,false)){using(FileStream stream=new FileStream(safe,FileAccess.Read,4096,false)){stream.Position=0;using(StreamReader reader=new StreamReader(stream,new UTF8Encoding(false,true),true,4096,true)){return reader.ReadToEnd();}}}}
::public SourceLease CopyTo(string destination){string full=Path.GetFullPath(destination);string parent=Path.GetDirectoryName(full);if(String.IsNullOrEmpty(parent)||!Directory.Exists(parent))throw new DirectoryNotFoundException("Protected copy parent is missing.");NoReparseChain(parent);if(File.Exists(full)||Directory.Exists(full))throw new IOException("Protected source copy already exists.");try{using(SafeFileHandle safe=new SafeFileHandle(fileHandle,false)){using(FileStream source=new FileStream(safe,FileAccess.Read,4096,false)){source.Position=0;using(FileStream target=new FileStream(full,FileMode.CreateNew,FileAccess.Write,FileShare.Read)){source.CopyTo(target);target.Flush(true);}}}SourceLease copy=Acquire(full);if(!String.Equals(copy.Hash,Hash,StringComparison.Ordinal)){copy.Dispose();throw new IOException("Protected source copy hash mismatch.");}return copy;}catch{try{if(File.Exists(full))File.Delete(full);}catch{}throw;}}
::public void Dispose(){if(fileHandle!=IntPtr.Zero&&fileHandle!=InvalidHandle){CloseHandle(fileHandle);fileHandle=IntPtr.Zero;}}
::}
::}
::__CP_SOURCE_LOCK_NATIVE_END__

::__CP_MEDIUM_LAUNCHER_BEGIN__
::param(
::    [Parameter(Mandatory=$true)][string]$WorkerScript,
::    [Parameter(Mandatory=$true)][string]$TargetSid,
::    [Parameter(Mandatory=$true)][string]$System32,
::    [Parameter(Mandatory=$true)][string]$ExecTemp,
::    [Parameter(Mandatory=$true)][string]$NativeSource,
::    [ValidateRange(1,3600)][int]$TimeoutSeconds,
::    [switch]$CleanupExecTemp
::)
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Full([string]$path){[IO.Path]::GetFullPath($path).TrimEnd([char]92)}
::function Assert-NoReparse([string]$path){
::    $full=Full $path;$root=[IO.Path]::GetPathRoot($full);$current=$root
::    foreach($part in $full.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)){$current=[IO.Path]::Combine($current,$part);if([IO.File]::GetAttributes($current)-band[IO.FileAttributes]::ReparsePoint){throw('Reparse point rejected: '+$current)}}
::    $full
::}
::try{
::    $execRoot=Assert-NoReparse $ExecTemp;$prefix=$execRoot+[char]92;$worker=Assert-NoReparse $WorkerScript;$native=Assert-NoReparse $NativeSource
::    foreach($path in @($worker,$native)){if(-not$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or-not[IO.File]::Exists($path)){throw'Medium-worker source is outside protected runtime.'}}
::    $system32Full=Assert-NoReparse $System32;$windows=Full([IO.Directory]::GetParent($system32Full).FullName)
::    $powershell=Assert-NoReparse([IO.Path]::Combine($system32Full,'WindowsPowerShell\v1.0\powershell.exe'))
::    $explorer=Assert-NoReparse([IO.Path]::Combine($windows,'explorer.exe'))
::    $sid=([Security.Principal.SecurityIdentifier]::new($TargetSid)).Value;$source=[IO.File]::ReadAllText($worker)
::    if([string]::IsNullOrWhiteSpace($source)){throw'Medium-worker payload is empty.'}
::    $preamble=[Collections.Generic.List[string]]::new()
::    foreach($name in @('CP_SETUP_TARGET_SID','CP_SETUP_TARGET_STATE_RELATIVE','CP_SETUP_TARGET_PROFILE','CP_SETUP_TARGET_LOCALAPPDATA','CP_SETUP_TARGET_APPDATA','CP_SETUP_PROTECTED_NVIMDATA','CP_VISIBLE_TEMP','ROOT','PROCESS_TREE_NATIVE_CS','PROCESS_TREE_PS','CP_DELETE_ROOT','CP_RUNTIME_TEMP','CP_RUNTIME_SECURE','CP_LOG_NAME','CP_LOG_SOURCE')){$value=[Environment]::GetEnvironmentVariable($name,'Process');if($null-ne$value){$bytes=[Text.Encoding]::UTF8.GetBytes($value);$encodedValue=[Convert]::ToBase64String($bytes);$preamble.Add("`$env:$name=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encodedValue'))")}}
::    $source=($preamble-join[Environment]::NewLine)+[Environment]::NewLine+$source
::    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($source));Add-Type -Path $native -ErrorAction Stop
::    $code=[CpSetup.Native.MediumTokenRunner]::Run($sid,$explorer,$powershell,$system32Full,$encoded,$TimeoutSeconds)
::    if($CleanupExecTemp){function Remove-NoFollow([string]$path,[string]$boundary){$full=Full $path;if($full-ine$boundary-and-not$full.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe protected-runtime cleanup path.'};if(-not(Test-Path -LiteralPath $full)){return};$item=Get-Item -LiteralPath $full -Force;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Reparse point in protected-runtime cleanup.'};if($item.PSIsContainer){foreach($child in @($item.GetFileSystemInfos())){Remove-NoFollow $child.FullName $full}}else{$item.Attributes=[IO.FileAttributes]::Normal};$item.Delete()};Remove-NoFollow $execRoot $execRoot}
::    exit $code
::}catch{[Console]::Error.WriteLine('Target-user worker could not start: '+$_.Exception.Message);exit 125}
::__CP_MEDIUM_LAUNCHER_END__

::__CP_MEDIUM_NATIVE_BEGIN__
::using System;
::using System.ComponentModel;
::using System.Diagnostics;
::using System.IO;
::using System.Runtime.InteropServices;
::using System.Security.Principal;
::using System.Text;
::namespace CpSetup.Native {
::public static class MediumTokenRunner {
::const uint PROCESS_QUERY_LIMITED_INFORMATION=0x1000,TOKEN_ASSIGN_PRIMARY=1,TOKEN_DUPLICATE=2,TOKEN_QUERY=8,TOKEN_ADJUST_PRIVILEGES=0x20,TOKEN_ADJUST_DEFAULT=0x80,SE_PRIVILEGE_ENABLED=2;
::const uint CREATE_SUSPENDED=4,CREATE_UNICODE_ENVIRONMENT=0x400,EXTENDED_STARTUPINFO_PRESENT=0x80000,CREATE_NO_WINDOW=0x08000000,STARTF_USESTDHANDLES=0x100,DUPLICATE_SAME_ACCESS=2,JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE=0x2000;
::const uint WAIT_OBJECT_0=0,WAIT_TIMEOUT=258,WAIT_FAILED=0xffffffff,GENERIC_READ=0x80000000,GENERIC_WRITE=0x40000000,FILE_SHARE_READ=1,FILE_SHARE_WRITE=2,OPEN_EXISTING=3,FILE_ATTRIBUTE_NORMAL=0x80;
::const int TokenUser=1,TokenElevationType=18,TokenElevation=20,TokenIntegrityLevel=25,TokenSessionId=12,SecurityImpersonation=2,TokenPrimary=1,JobObjectExtendedLimitInformation=9;
::static readonly IntPtr InvalidHandle=new IntPtr(-1),HandleListAttribute=new IntPtr(0x00020002);
::[StructLayout(LayoutKind.Sequential)]struct LUID{public uint LowPart;public int HighPart;}
::[StructLayout(LayoutKind.Sequential)]struct LUID_AND_ATTRIBUTES{public LUID Luid;public uint Attributes;}
::[StructLayout(LayoutKind.Sequential)]struct TOKEN_PRIVILEGES{public uint PrivilegeCount;public LUID_AND_ATTRIBUTES Privileges;}
::[StructLayout(LayoutKind.Sequential)]struct SID_AND_ATTRIBUTES{public IntPtr Sid;public uint Attributes;}
::[StructLayout(LayoutKind.Sequential)]struct TOKEN_MANDATORY_LABEL{public SID_AND_ATTRIBUTES Label;}
::[StructLayout(LayoutKind.Sequential)]struct SECURITY_ATTRIBUTES{public int nLength;public IntPtr lpSecurityDescriptor;[MarshalAs(UnmanagedType.Bool)]public bool bInheritHandle;}
::[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]struct STARTUPINFO{public int cb;public string lpReserved,lpDesktop,lpTitle;public uint dwX,dwY,dwXSize,dwYSize,dwXCountChars,dwYCountChars,dwFillAttribute,dwFlags;public short wShowWindow,cbReserved2;public IntPtr lpReserved2,hStdInput,hStdOutput,hStdError;}
::[StructLayout(LayoutKind.Sequential)]struct STARTUPINFOEX{public STARTUPINFO StartupInfo;public IntPtr lpAttributeList;}
::[StructLayout(LayoutKind.Sequential)]struct PROCESS_INFORMATION{public IntPtr hProcess,hThread;public uint dwProcessId,dwThreadId;}
::[StructLayout(LayoutKind.Sequential)]struct JOBOBJECT_BASIC_LIMIT_INFORMATION{public long PerProcessUserTimeLimit,PerJobUserTimeLimit;public uint LimitFlags;public UIntPtr MinimumWorkingSetSize,MaximumWorkingSetSize;public uint ActiveProcessLimit;public IntPtr Affinity;public uint PriorityClass,SchedulingClass;}
::[StructLayout(LayoutKind.Sequential)]struct IO_COUNTERS{public ulong ReadOperationCount,WriteOperationCount,OtherOperationCount,ReadTransferCount,WriteTransferCount,OtherTransferCount;}
::[StructLayout(LayoutKind.Sequential)]struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION{public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;public IO_COUNTERS IoInfo;public UIntPtr ProcessMemoryLimit,JobMemoryLimit,PeakProcessMemoryUsed,PeakJobMemoryUsed;}
::[DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr OpenProcess(uint access,bool inherit,uint processId);
::[DllImport("advapi32.dll",SetLastError=true)]static extern bool OpenProcessToken(IntPtr process,uint access,out IntPtr token);
::[DllImport("advapi32.dll",SetLastError=true)]static extern bool DuplicateTokenEx(IntPtr token,uint access,IntPtr attrs,int level,int type,out IntPtr duplicate);
::[DllImport("advapi32.dll",SetLastError=true)]static extern bool GetTokenInformation(IntPtr token,int kind,IntPtr info,int size,out int returned);
::[DllImport("advapi32.dll",SetLastError=true)]static extern bool LookupPrivilegeValue(string system,string name,out LUID luid);
::[DllImport("advapi32.dll",SetLastError=true)]static extern bool AdjustTokenPrivileges(IntPtr token,bool disableAll,ref TOKEN_PRIVILEGES state,int size,IntPtr previous,IntPtr returned);
::[DllImport("kernel32.dll")]static extern IntPtr GetCurrentProcess();
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool QueryFullProcessImageName(IntPtr process,uint flags,StringBuilder path,ref uint size);
::[DllImport("advapi32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern bool CreateProcessWithTokenW(IntPtr token,uint logonFlags,string app,StringBuilder command,uint flags,IntPtr environment,string cwd,ref STARTUPINFOEX startup,out PROCESS_INFORMATION processInfo);
::[DllImport("userenv.dll",SetLastError=true)]static extern bool CreateEnvironmentBlock(out IntPtr environment,IntPtr token,bool inherit);
::[DllImport("userenv.dll",SetLastError=true)]static extern bool DestroyEnvironmentBlock(IntPtr environment);
::[DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr CreateJobObject(IntPtr attrs,string name);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool SetInformationJobObject(IntPtr job,int kind,ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION info,uint length);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool TerminateJobObject(IntPtr job,uint code);
::[DllImport("kernel32.dll",SetLastError=true)]static extern uint ResumeThread(IntPtr thread);
::[DllImport("kernel32.dll",SetLastError=true)]static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool GetExitCodeProcess(IntPtr process,out uint code);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool TerminateProcess(IntPtr process,uint code);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool CloseHandle(IntPtr handle);
::[DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr GetStdHandle(int id);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool DuplicateHandle(IntPtr sourceProcess,IntPtr source,IntPtr targetProcess,out IntPtr target,uint access,bool inherit,uint options);
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern IntPtr CreateFile(string path,uint access,uint share,ref SECURITY_ATTRIBUTES attrs,uint creation,uint flags,IntPtr template);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool InitializeProcThreadAttributeList(IntPtr list,int count,uint flags,ref IntPtr size);
::[DllImport("kernel32.dll",SetLastError=true)]static extern bool UpdateProcThreadAttribute(IntPtr list,uint flags,IntPtr attribute,IntPtr value,IntPtr size,IntPtr previous,IntPtr returned);
::[DllImport("kernel32.dll")]static extern void DeleteProcThreadAttributeList(IntPtr list);
::[DllImport("advapi32.dll",SetLastError=true)]static extern IntPtr GetSidSubAuthorityCount(IntPtr sid);
::[DllImport("advapi32.dll",SetLastError=true)]static extern IntPtr GetSidSubAuthority(IntPtr sid,uint index);
::static void Fail(string operation){throw new Win32Exception(Marshal.GetLastWin32Error(),operation);}
::static void Close(ref IntPtr handle){if(handle!=IntPtr.Zero&&handle!=InvalidHandle){CloseHandle(handle);handle=IntPtr.Zero;}}
::static bool EnablePrivilege(string name){IntPtr token=IntPtr.Zero;try{if(!OpenProcessToken(GetCurrentProcess(),TOKEN_QUERY|TOKEN_ADJUST_PRIVILEGES,out token))return false;LUID luid;if(!LookupPrivilegeValue(null,name,out luid))return false;TOKEN_PRIVILEGES state=new TOKEN_PRIVILEGES();state.PrivilegeCount=1;state.Privileges=new LUID_AND_ATTRIBUTES{Luid=luid,Attributes=SE_PRIVILEGE_ENABLED};if(!AdjustTokenPrivileges(token,false,ref state,Marshal.SizeOf(typeof(TOKEN_PRIVILEGES)),IntPtr.Zero,IntPtr.Zero))return false;return Marshal.GetLastWin32Error()!=1300;}finally{Close(ref token);}}
::static IntPtr TokenInfo(IntPtr token,int kind){int size;GetTokenInformation(token,kind,IntPtr.Zero,0,out size);if(size<=0)Fail("GetTokenInformation(size)");IntPtr buffer=Marshal.AllocHGlobal(size);if(!GetTokenInformation(token,kind,buffer,size,out size)){Marshal.FreeHGlobal(buffer);Fail("GetTokenInformation");}return buffer;}
::static uint TokenUInt(IntPtr token,int kind){IntPtr buffer=TokenInfo(token,kind);try{return unchecked((uint)Marshal.ReadInt32(buffer));}finally{Marshal.FreeHGlobal(buffer);}}
::static string TokenSid(IntPtr token){using(WindowsIdentity identity=new WindowsIdentity(token)){return identity.User.Value;}}
::static uint IntegrityRid(IntPtr token){IntPtr buffer=TokenInfo(token,TokenIntegrityLevel);try{TOKEN_MANDATORY_LABEL label=(TOKEN_MANDATORY_LABEL)Marshal.PtrToStructure(buffer,typeof(TOKEN_MANDATORY_LABEL));IntPtr countPointer=GetSidSubAuthorityCount(label.Label.Sid);if(countPointer==IntPtr.Zero)Fail("GetSidSubAuthorityCount");byte count=Marshal.ReadByte(countPointer);if(count==0)throw new InvalidOperationException("Token has no integrity RID.");IntPtr rid=GetSidSubAuthority(label.Label.Sid,(uint)(count-1));if(rid==IntPtr.Zero)Fail("GetSidSubAuthority");return unchecked((uint)Marshal.ReadInt32(rid));}finally{Marshal.FreeHGlobal(buffer);}}
::static bool ExpectedToken(IntPtr token,string sid,int session){if(!String.Equals(TokenSid(token),sid,StringComparison.OrdinalIgnoreCase))return false;if(TokenUInt(token,TokenSessionId)!=(uint)session)return false;if(TokenUInt(token,TokenElevation)!=0||TokenUInt(token,TokenElevationType)==2)return false;uint rid=IntegrityRid(token);return rid>=0x2000&&rid<0x3000;}
::static string ImagePath(IntPtr process){StringBuilder path=new StringBuilder(32768);uint size=(uint)path.Capacity;if(!QueryFullProcessImageName(process,0,path,ref size))Fail("QueryFullProcessImageName");return Path.GetFullPath(path.ToString());}
::static IntPtr ExplorerToken(string sid,string expectedPath,int session){EnablePrivilege("SeDebugPrivilege");foreach(Process candidate in Process.GetProcessesByName("explorer")){IntPtr process=IntPtr.Zero,token=IntPtr.Zero,duplicate=IntPtr.Zero;try{if(candidate.SessionId!=session)continue;process=OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,false,(uint)candidate.Id);if(process==IntPtr.Zero)continue;if(!String.Equals(ImagePath(process).TrimEnd('\\'),expectedPath.TrimEnd('\\'),StringComparison.OrdinalIgnoreCase))continue;if(!OpenProcessToken(process,TOKEN_QUERY|TOKEN_DUPLICATE,out token)||!ExpectedToken(token,sid,session))continue;uint rights=TOKEN_ASSIGN_PRIMARY|TOKEN_DUPLICATE|TOKEN_QUERY|TOKEN_ADJUST_DEFAULT;if(!DuplicateTokenEx(token,rights,IntPtr.Zero,SecurityImpersonation,TokenPrimary,out duplicate))continue;if(!ExpectedToken(duplicate,sid,session)){Close(ref duplicate);continue;}return duplicate;}catch{Close(ref duplicate);}finally{Close(ref token);Close(ref process);candidate.Dispose();}}throw new InvalidOperationException("No medium, non-elevated Explorer token matched the invoking user and session.");}
::static IntPtr StandardHandle(int id){IntPtr source=GetStdHandle(id),duplicate;if(source!=IntPtr.Zero&&source!=InvalidHandle&&DuplicateHandle(GetCurrentProcess(),source,GetCurrentProcess(),out duplicate,0,true,DUPLICATE_SAME_ACCESS))return duplicate;SECURITY_ATTRIBUTES attrs=new SECURITY_ATTRIBUTES{nLength=Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES)),bInheritHandle=true};uint access=id==-10?GENERIC_READ:GENERIC_WRITE;duplicate=CreateFile("NUL",access,FILE_SHARE_READ|FILE_SHARE_WRITE,ref attrs,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,IntPtr.Zero);if(duplicate==InvalidHandle)Fail("CreateFile(NUL)");return duplicate;}
::public static int Run(string sid,string explorer,string powershell,string systemDirectory,string payload,int timeoutSeconds){
::if(timeoutSeconds<1||timeoutSeconds>3600)throw new ArgumentOutOfRangeException("timeoutSeconds");string commandText="\""+powershell+"\" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand "+payload;if(commandText.Length>=32760)throw new InvalidOperationException("Encoded worker payload exceeds the Windows command-line limit.");StringBuilder command=new StringBuilder(commandText,32768);int session=Process.GetCurrentProcess().SessionId;
::IntPtr userToken=IntPtr.Zero,environment=IntPtr.Zero,job=IntPtr.Zero,input=IntPtr.Zero,output=IntPtr.Zero,error=IntPtr.Zero,attributes=IntPtr.Zero,handleArray=IntPtr.Zero;PROCESS_INFORMATION child=new PROCESS_INFORMATION();bool created=false,assigned=false,exited=false;
::try{if(!EnablePrivilege("SeImpersonatePrivilege"))throw new InvalidOperationException("SeImpersonatePrivilege is unavailable.");userToken=ExplorerToken(sid,Path.GetFullPath(explorer),session);if(!CreateEnvironmentBlock(out environment,userToken,false))Fail("CreateEnvironmentBlock");input=StandardHandle(-10);output=StandardHandle(-11);error=StandardHandle(-12);IntPtr attributeSize=IntPtr.Zero;InitializeProcThreadAttributeList(IntPtr.Zero,1,0,ref attributeSize);if(attributeSize==IntPtr.Zero)Fail("InitializeProcThreadAttributeList(size)");attributes=Marshal.AllocHGlobal(attributeSize);if(!InitializeProcThreadAttributeList(attributes,1,0,ref attributeSize))Fail("InitializeProcThreadAttributeList");handleArray=Marshal.AllocHGlobal(IntPtr.Size*3);Marshal.WriteIntPtr(handleArray,0,input);Marshal.WriteIntPtr(handleArray,IntPtr.Size,output);Marshal.WriteIntPtr(handleArray,IntPtr.Size*2,error);if(!UpdateProcThreadAttribute(attributes,0,HandleListAttribute,handleArray,new IntPtr(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero))Fail("UpdateProcThreadAttribute");STARTUPINFOEX startup=new STARTUPINFOEX();startup.StartupInfo.cb=Marshal.SizeOf(typeof(STARTUPINFOEX));startup.StartupInfo.lpDesktop="winsta0\\default";startup.StartupInfo.dwFlags=STARTF_USESTDHANDLES;startup.StartupInfo.hStdInput=input;startup.StartupInfo.hStdOutput=output;startup.StartupInfo.hStdError=error;startup.lpAttributeList=attributes;job=CreateJobObject(IntPtr.Zero,null);if(job==IntPtr.Zero)Fail("CreateJobObject");JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits=new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();limits.BasicLimitInformation.LimitFlags=JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;if(!SetInformationJobObject(job,JobObjectExtendedLimitInformation,ref limits,(uint)Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION))))Fail("SetInformationJobObject");uint flags=CREATE_SUSPENDED|CREATE_UNICODE_ENVIRONMENT|EXTENDED_STARTUPINFO_PRESENT|CREATE_NO_WINDOW;if(!CreateProcessWithTokenW(userToken,0,powershell,command,flags,environment,systemDirectory,ref startup,out child))Fail("CreateProcessWithTokenW");created=true;if(!AssignProcessToJobObject(job,child.hProcess))Fail("AssignProcessToJobObject");assigned=true;if(ResumeThread(child.hThread)==0xffffffff)Fail("ResumeThread");Close(ref child.hThread);uint wait=WaitForSingleObject(child.hProcess,checked((uint)timeoutSeconds*1000));if(wait==WAIT_TIMEOUT){Console.Error.WriteLine("Target-user worker timed out after "+timeoutSeconds+" seconds.");TerminateJobObject(job,124);WaitForSingleObject(child.hProcess,5000);return 124;}if(wait==WAIT_FAILED)Fail("WaitForSingleObject");if(wait!=WAIT_OBJECT_0)throw new InvalidOperationException("Unexpected worker wait result.");exited=true;uint code;if(!GetExitCodeProcess(child.hProcess,out code))Fail("GetExitCodeProcess");return unchecked((int)code);}
::finally{if(created&&!exited){if(assigned&&job!=IntPtr.Zero)TerminateJobObject(job,125);else if(child.hProcess!=IntPtr.Zero)TerminateProcess(child.hProcess,125);if(child.hProcess!=IntPtr.Zero)WaitForSingleObject(child.hProcess,5000);}Close(ref child.hThread);Close(ref child.hProcess);Close(ref job);if(attributes!=IntPtr.Zero){DeleteProcThreadAttributeList(attributes);Marshal.FreeHGlobal(attributes);}if(handleArray!=IntPtr.Zero)Marshal.FreeHGlobal(handleArray);Close(ref input);Close(ref output);Close(ref error);if(environment!=IntPtr.Zero)DestroyEnvironmentBlock(environment);Close(ref userToken);}
::}
::}
::}
::__CP_MEDIUM_NATIVE_END__

::__CP_PROCESS_TREE_NATIVE_BEGIN__
::using System;
::using System.Collections.Generic;
::using System.ComponentModel;
::using System.Runtime.InteropServices;
::namespace CpSetup.Native {
::public static class ProcessTree {
::const uint TH32CS_SNAPPROCESS=2,PROCESS_QUERY_LIMITED_INFORMATION=0x1000;
::static readonly IntPtr InvalidHandle=new IntPtr(-1);
::[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]
::struct PROCESSENTRY32 { public uint dwSize,cntUsage,th32ProcessID; public UIntPtr th32DefaultHeapID; public uint th32ModuleID,cntThreads,th32ParentProcessID; public int pcPriClassBase; public uint dwFlags; [MarshalAs(UnmanagedType.ByValTStr,SizeConst=260)] public string szExeFile; }
::[DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr CreateToolhelp32Snapshot(uint flags,uint processId);
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern bool Process32FirstW(IntPtr snapshot,ref PROCESSENTRY32 entry);
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern bool Process32NextW(IntPtr snapshot,ref PROCESSENTRY32 entry);
::[DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr OpenProcess(uint access,bool inherit,int processId);
::[DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern bool QueryFullProcessImageNameW(IntPtr process,uint flags,System.Text.StringBuilder path,ref uint size);
::[DllImport("kernel32.dll")]static extern bool CloseHandle(IntPtr handle);
::public static string ImagePath(int processId){IntPtr process=OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,false,processId);if(process==IntPtr.Zero)throw new Win32Exception(Marshal.GetLastWin32Error(),"OpenProcess(image)");try{uint size=32768;System.Text.StringBuilder path=new System.Text.StringBuilder((int)size);if(!QueryFullProcessImageNameW(process,0,path,ref size))throw new Win32Exception(Marshal.GetLastWin32Error(),"QueryFullProcessImageName");return path.ToString();}finally{CloseHandle(process);}}
::public static int[] Snapshot(int root) {
::    IntPtr snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
::    if(snapshot==InvalidHandle)throw new Win32Exception(Marshal.GetLastWin32Error(),"CreateToolhelp32Snapshot");
::    try {
::        Dictionary<int,List<int>> children=new Dictionary<int,List<int>>();
::        PROCESSENTRY32 entry=new PROCESSENTRY32();entry.dwSize=(uint)Marshal.SizeOf(typeof(PROCESSENTRY32));
::        if(Process32FirstW(snapshot,ref entry))do { int parent=unchecked((int)entry.th32ParentProcessID); List<int> list; if(!children.TryGetValue(parent,out list)){list=new List<int>();children.Add(parent,list);} list.Add(unchecked((int)entry.th32ProcessID)); entry.dwSize=(uint)Marshal.SizeOf(typeof(PROCESSENTRY32)); } while(Process32NextW(snapshot,ref entry));
::        List<int> result=new List<int>();Queue<int> queue=new Queue<int>();HashSet<int> seen=new HashSet<int>();queue.Enqueue(root);
::        while(queue.Count!=0){int current=queue.Dequeue();if(!seen.Add(current))continue;result.Add(current);List<int> list;if(children.TryGetValue(current,out list))foreach(int child in list)queue.Enqueue(child);}
::        return result.ToArray();
::    } finally { CloseHandle(snapshot); }
::}
::}
::}
::__CP_PROCESS_TREE_NATIVE_END__

::__CP_PROCESS_TREE_PS_BEGIN__
::if(-not('CpSetup.Native.ProcessTree'-as[type])){Add-Type -Path $env:PROCESS_TREE_NATIVE_CS -ErrorAction Stop}
::function Get-ProcessTreeMembers([int]$RootPid,[datetime]$NotAfter){
::    $members=[Collections.Generic.Dictionary[int,Diagnostics.Process]]::new()
::    foreach($pidValue in [CpSetup.Native.ProcessTree]::Snapshot($RootPid)){
::        try{$candidate=[Diagnostics.Process]::GetProcessById($pidValue);$started=$candidate.StartTime.ToUniversalTime();if($started-le$NotAfter){$members[$pidValue]=$candidate}else{$candidate.Dispose()}}catch{}
::    }
::    $members
::}
::function Stop-VerifiedProcessTree([Diagnostics.Process]$Root,[string]$Taskkill){
::    $notAfter=[DateTime]::UtcNow.AddSeconds(5);$members=Get-ProcessTreeMembers $Root.Id $notAfter
::    try{
::        foreach($member in @($members.Values|Sort-Object Id -Descending)){try{if(-not$member.HasExited){$member.Kill()}}catch{}}
::        foreach($entry in (Get-ProcessTreeMembers $Root.Id $notAfter).GetEnumerator()){if(-not$members.ContainsKey($entry.Key)){$members[$entry.Key]=$entry.Value}else{$entry.Value.Dispose()}}
::        $deadline=[DateTime]::UtcNow.AddSeconds(5)
::        foreach($member in $members.Values){try{if(-not$member.HasExited){$remaining=[Math]::Max(0,[int]($deadline-[DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt0){[void]$member.WaitForExit($remaining)}}}catch{}}
::        foreach($member in $members.Values){try{if(-not$member.HasExited){$member.Kill()}}catch{}}
::        $verifyDeadline=[DateTime]::UtcNow.AddSeconds(2);$survivors=[Collections.Generic.List[int]]::new()
::        foreach($member in $members.Values){try{if(-not$member.HasExited){$remaining=[Math]::Max(0,[int]($verifyDeadline-[DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt0){[void]$member.WaitForExit($remaining)}};if(-not$member.HasExited){$survivors.Add($member.Id)}}catch{}}
::        if($survivors.Count){throw('Process-tree survivors: '+($survivors-join', '))}
::    }finally{foreach($member in $members.Values){$member.Dispose()}}
::}
::function Wait-BoundedProcess([Diagnostics.Process]$Process,[int]$TimeoutMilliseconds,[string]$Taskkill){
::    if($TimeoutMilliseconds-lt1){throw'Invalid process timeout.'}
::    if(-not$Process.WaitForExit($TimeoutMilliseconds)){try{Stop-VerifiedProcessTree $Process $Taskkill}catch{[Console]::Error.WriteLine($_.Exception.Message)};return 124}
::    if(-not$Process.WaitForExit(1000)){throw'Process exit could not be finalized.'}
::    [int]$Process.ExitCode
::}
::__CP_PROCESS_TREE_PS_END__

::__CP_PENDING_ARTIFACTS_WORKER_BEGIN__
::$ErrorActionPreference='Stop'
::function Hash-Bytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
::function New-PathSet{return ,([Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase))}
::function Assert-CanonicalRoot([string]$raw){
::    if([string]::IsNullOrWhiteSpace($raw)){throw'Empty artifact LocalAppData root.'};$text=$raw.TrimEnd([char]92);$full=[IO.Path]::GetFullPath($text).TrimEnd([char]92)
::    if($full-ine$text-or$full-notmatch'^[A-Za-z]:\\'){throw('Artifact LocalAppData root is not canonical and local: '+$text)}
::    $drive=[IO.Path]::GetPathRoot($full);$cursor=$drive;foreach($part in $full.Substring($drive.Length).Split([char]92,[StringSplitOptions]::RemoveEmptyEntries)){$cursor=Join-Path $cursor $part;if(Test-Path -LiteralPath $cursor){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw('Unsafe artifact LocalAppData root: '+$cursor)}}};$full
::}
::function Set-Roots($values){
::    $set=New-PathSet;foreach($raw in @($values)){$full=Assert-CanonicalRoot ([string]$raw);if(-not$set.Add($full)){throw('Duplicate artifact LocalAppData root: '+$full)}}
::    if(-not$set.Count-or-not$set.Contains($targetLocal)){throw'Target LocalAppData is absent from artifact roots.'};$ordered=[string[]]@($set|Sort-Object)
::    for($i=0;$i-lt$ordered.Count;$i++){for($j=$i+1;$j-lt$ordered.Count;$j++){if($ordered[$i].StartsWith($ordered[$j]+[char]92,[StringComparison]::OrdinalIgnoreCase)-or$ordered[$j].StartsWith($ordered[$i]+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Artifact LocalAppData roots overlap.'}}}
::    $script:locals=$ordered;$built=[Collections.Generic.List[object]]::new();foreach($local in $ordered){$built.Add([pscustomobject]@{Local=$local;Kind='nvim';Parent=Join-Path $local 'Temp';Target=Join-Path $local 'Temp\nvim'});$built.Add([pscustomobject]@{Local=$local;Kind='qt';Parent=Join-Path $local 'cache';Target=Join-Path $local 'cache\qt-installer-framework'})};$script:roots=@($built)
::}
::function Assert-NoReparse([string]$path){
::    $full=[IO.Path]::GetFullPath($path).TrimEnd([char]92);$match=@($locals|Where-Object{$full-ieq$_-or$full.StartsWith($_+[char]92,[StringComparison]::OrdinalIgnoreCase)}|Sort-Object Length -Descending|Select-Object -First 1);if($match.Count-ne1){throw('Artifact path escaped LocalAppData roots: '+$full)}
::    $cursor=[string]$match[0];if(Test-Path -LiteralPath $cursor){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw('Unsafe artifact path component: '+$cursor)}}
::    if($full.Length-gt$cursor.Length){foreach($part in $full.Substring($cursor.Length+1).Split([char]92,[StringSplitOptions]::RemoveEmptyEntries)){$cursor=Join-Path $cursor $part;if(Test-Path -LiteralPath $cursor){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw('Unsafe artifact reparse point: '+$cursor)}}}}
::}
::function Assert-ArtifactPath([string]$raw){
::    if([string]::IsNullOrWhiteSpace($raw)){throw'Empty artifact inventory path.'};$text=$raw.TrimEnd([char]92);$full=[IO.Path]::GetFullPath($text).TrimEnd([char]92);if($full-ine$text){throw('Artifact inventory path is not canonical: '+$text)}
::    $entry=@($roots|Where-Object{$full-ieq$_.Target-or$full.StartsWith($_.Target+[char]92,[StringComparison]::OrdinalIgnoreCase)});if($entry.Count-ne1){throw('Artifact inventory path escaped the allowlist: '+$full)};Assert-NoReparse $full;[pscustomobject]@{Path=$full;Entry=$entry[0]}
::}
::function Add-Validated($set,$values,[bool]$owned){foreach($raw in @($values)){$validated=Assert-ArtifactPath ([string]$raw);if($owned-and$validated.Entry.Kind-eq'nvim'-and$validated.Entry.Local-ine$targetLocal){throw('Non-target nvim artifact cannot be setup-owned: '+$validated.Path)};if(-not$set.Add($validated.Path)){throw('Duplicate artifact inventory path: '+$validated.Path)}}}
::function Get-Inventory{
::    $found=New-PathSet;foreach($entry in $roots){Assert-NoReparse $entry.Parent;if(-not(Test-Path -LiteralPath $entry.Target)){continue};$rootItem=Get-Item -LiteralPath $entry.Target -Force -ErrorAction Stop;if(-not$rootItem.PSIsContainer-or($rootItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw('Unsafe artifact root: '+$entry.Target)};$stack=[Collections.Generic.Stack[IO.FileSystemInfo]]::new();$stack.Push($rootItem);while($stack.Count){$item=$stack.Pop();$validated=Assert-ArtifactPath $item.FullName;[void]$found.Add($validated.Path);if($item-is[IO.DirectoryInfo]){foreach($child in $item.EnumerateFileSystemInfos()){if($child.Attributes-band[IO.FileAttributes]::ReparsePoint){throw('Unsafe artifact reparse point: '+$child.FullName)};$stack.Push($child)}}}};@($found|Sort-Object)
::}
::function Read-Intent([Microsoft.Win32.RegistryKey]$state){
::    $name='Pending.Artifacts.Intent';if(@($state.GetValueNames())-notcontains$name){return$null};if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw'Pending artifact intent has an invalid kind.'}
::    $raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$parts=$raw.Split(@('|'),5);if($parts.Count-ne5-or$parts[0]-cne'v1'-or$parts[1]-notmatch'^[0-9a-f]{32}$'-or$parts[2]-notin@('prepared','committed')-or$parts[3]-notmatch'^[0-9a-f]{64}$'){throw'Invalid pending artifact intent.'}
::    $bytes=[Convert]::FromBase64String($parts[4]);if((Hash-Bytes $bytes)-cne$parts[3]){throw'Invalid pending artifact intent hash.'};$json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json;$schema=@('Version','OperationId','Sid','OperatorSid','LocalAppDataRoots','StartedTicks','BeforePaths')
::    if(($plan|ConvertTo-Json -Compress)-cne$json-or(@($plan.PSObject.Properties.Name)-join"`0")-cne($schema-join"`0")-or[int]$plan.Version-ne1-or[string]$plan.OperationId-cne$parts[1]-or[string]$plan.Sid-cne$env:CP_SETUP_TARGET_SID-or[string]$plan.OperatorSid-notmatch'^S-1-(?:[0-9]+-)+[0-9]+$'){throw'Invalid pending artifact plan.'}
::    [long]$ticks=0;if(-not[long]::TryParse([string]$plan.StartedTicks,[ref]$ticks)-or$ticks-lt[DateTime]::MinValue.Ticks-or$ticks-gt[DateTime]::UtcNow.AddMinutes(1).Ticks){throw'Invalid pending artifact timestamp.'};[pscustomobject]@{Raw=$raw;Nonce=$parts[1];Stage=$parts[2];Hash=$parts[3];Json=$json;Plan=$plan;Ticks=$ticks}
::}
::$targetLocal=[IO.Path]::GetFullPath($env:CP_SETUP_TARGET_LOCALAPPDATA).TrimEnd([char]92);$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$state=$machine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true);if(-not$state){$machine.Dispose();exit 0}
::try{
::    $intent=Read-Intent $state;if(-not$intent){exit 0};$names=@($state.GetValueNames());foreach($name in @('Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths')){if($names-notcontains$name-or$state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::MultiString){throw'Artifact ownership metadata is incomplete.'}}
::    if([string]$state.GetValue('Target.Sid',$null,$option)-cne$env:CP_SETUP_TARGET_SID-or[IO.Path]::GetFullPath([string]$state.GetValue('Target.LocalAppData',$null,$option)).TrimEnd([char]92)-ine$targetLocal){throw'Protected artifact target metadata is invalid.'}
::    $metadataRoots=[string[]]@($state.GetValue('Artifacts.LocalAppData.Roots',$null,$option));$intentRoots=[string[]]@($intent.Plan.LocalAppDataRoots);Set-Roots @($metadataRoots+$intentRoots)
::    $before=New-PathSet;Add-Validated $before @($state.GetValue('Artifacts.Before.Paths',$null,$option)) $false;$owned=New-PathSet;Add-Validated $owned @($state.GetValue('Artifacts.Created.Paths',$null,$option)) $true;foreach($path in $owned){if($before.Contains($path)){throw('Artifact path is both preexisting and setup-owned: '+$path)}}
::    $operation=New-PathSet;Add-Validated $operation @($intent.Plan.BeforePaths) $false
::    if($intent.Stage-eq'committed'){
::        foreach($root in $intentRoots){if($metadataRoots-inotcontains(Assert-CanonicalRoot $root)){throw'Committed artifact roots are absent from metadata.'}};foreach($path in $operation){if(-not$before.Contains($path)-and-not$owned.Contains($path)){throw'Committed artifact baseline is absent from metadata.'}}
::    }else{
::        foreach($path in $operation){if(-not$owned.Contains($path)){[void]$before.Add($path)}};$current=@(Get-Inventory);$candidates=New-PathSet;foreach($path in $current){if(-not$before.Contains($path)-and-not$owned.Contains($path)-and-not$operation.Contains($path)-and(Split-Path -Leaf $path)-notlike'cp_setup_*.log'){[void]$candidates.Add($path)}}
::        $candidateRoots=[Collections.Generic.List[string]]::new();foreach($path in $candidates){$parent=Split-Path -Parent $path;if(-not$candidates.Contains($parent)){if((Get-Item -LiteralPath $path -Force -ErrorAction Stop).CreationTimeUtc-ge([DateTime]::new($intent.Ticks,[DateTimeKind]::Utc)).AddSeconds(-5)){$candidateRoots.Add($path)}}}
::        $targetSid=([Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)).Value;$allowedQt=@($targetSid,[string]$intent.Plan.OperatorSid,'S-1-5-18','S-1-5-32-544');foreach($path in $candidates){$root=@($candidateRoots|Where-Object{$path-ieq$_-or$path.StartsWith($_+[char]92,[StringComparison]::OrdinalIgnoreCase)}|Select-Object -First 1);if($root.Count-ne1){continue};$validated=Assert-ArtifactPath $path;$owner=(Get-Acl -LiteralPath $path -ErrorAction Stop).GetOwner([Security.Principal.SecurityIdentifier]).Value;if(($validated.Entry.Kind-eq'nvim'-and($validated.Entry.Local-ine$targetLocal-or$owner-ine$targetSid))-or($validated.Entry.Kind-eq'qt'-and$allowedQt-inotcontains$owner)){continue};[void]$owned.Add($path)}
::        $rootResult=[string[]]@($locals|Sort-Object);$beforeResult=[string[]]@($before|Sort-Object);$ownedResult=[string[]]@($owned|Sort-Object);$state.SetValue('Artifacts.LocalAppData.Roots',$rootResult,[Microsoft.Win32.RegistryValueKind]::MultiString);$state.SetValue('Artifacts.Before.Paths',$beforeResult,[Microsoft.Win32.RegistryValueKind]::MultiString);$state.SetValue('Artifacts.Created.Paths',$ownedResult,[Microsoft.Win32.RegistryValueKind]::MultiString)
::        foreach($entry in @(@('Artifacts.LocalAppData.Roots',$rootResult),@('Artifacts.Before.Paths',$beforeResult),@('Artifacts.Created.Paths',$ownedResult))){$verify=@($state.GetValue([string]$entry[0],$null,$option));if($state.GetValueKind([string]$entry[0])-ne[Microsoft.Win32.RegistryValueKind]::MultiString-or$verify.Count-ne$entry[1].Count-or@($entry[1]|Where-Object{$verify-inotcontains$_}).Count){throw'Artifact ownership write did not verify.'}}
::        $committed='v1|'+$intent.Nonce+'|committed|'+$intent.Hash+'|'+[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($intent.Json));$state.SetValue('Pending.Artifacts.Intent',$committed,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue('Pending.Artifacts.Intent',$null,$option)-cne$committed){throw'Committed artifact intent did not verify.'}
::    }
::    $state.DeleteValue('Pending.Artifacts.Intent',$false);if(@($state.GetValueNames())-contains'Pending.Artifacts.Intent'){throw'Pending artifact intent cleanup failed.'}
::}finally{$state.Dispose();$machine.Dispose()}
::__CP_PENDING_ARTIFACTS_WORKER_END__

::__CP_PENDING_ACL_WORKER_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Hash-Bytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
::function Read-Plan([Microsoft.Win32.RegistryKey]$state){$name='Pending.Acl.Intent';if(@($state.GetValueNames())-notcontains$name){return$null};if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw'Invalid pending ac-library kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne5-or$p[0]-cne'v1'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw'Invalid pending ac-library intent.'};$bytes=[Convert]::FromBase64String($p[4]);if((Hash-Bytes $bytes)-cne$p[3]){throw'Invalid pending ac-library hash.'};$json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json;$schema=@('Version','OperationId','Root','Commit','StageRoot','StagePath','BackupPath');if(($plan|ConvertTo-Json -Compress)-cne$json-or(@($plan.PSObject.Properties.Name)-join"`0")-cne($schema-join"`0")-or[int]$plan.Version-ne1-or[string]$plan.OperationId-cne$p[1]-or[string]$plan.Commit-notmatch'^[0-9a-f]{40}$'){throw'Invalid pending ac-library plan.'};[pscustomobject]@{Stage=$p[2];Nonce=$p[1];Plan=$plan}}
::function Assert-NoReparse([string]$path){if(-not(Test-Path -LiteralPath $path)){return};$item=Get-Item -LiteralPath $path -Force;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw('ac-library recovery encountered a reparse point: '+$path)};if($item-is[IO.DirectoryInfo]){$stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($item);while($stack.Count){foreach($child in $stack.Pop().EnumerateFileSystemInfos()){if($child.Attributes-band[IO.FileAttributes]::ReparsePoint){throw('ac-library recovery encountered a reparse point: '+$child.FullName)};if($child-is[IO.DirectoryInfo]){$stack.Push($child)}}}}}
::function Remove-Safe([string]$path){if(-not(Test-Path -LiteralPath $path)){return};Assert-NoReparse $path;[IO.Directory]::Delete($path,$true);if(Test-Path -LiteralPath $path){throw'ac-library recovery cleanup failed.'}}
::$state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false);if(-not$state){exit 0}
::try{$pending=Read-Plan $state;if(-not$pending){exit 0};$p=$pending.Plan;$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd([char]92);if([IO.Path]::GetFullPath([string]$p.Root).TrimEnd([char]92)-ine$root){throw'Pending ac-library root changed.'};$libraries=[IO.Path]::GetFullPath((Join-Path $root 'libraries')).TrimEnd([char]92);$stageRoot=[IO.Path]::GetFullPath([string]$p.StageRoot).TrimEnd([char]92);$stage=[IO.Path]::GetFullPath([string]$p.StagePath).TrimEnd([char]92);$backup=[IO.Path]::GetFullPath([string]$p.BackupPath).TrimEnd([char]92);$target=[IO.Path]::GetFullPath((Join-Path $libraries 'ac-library')).TrimEnd([char]92);if([IO.Path]::GetDirectoryName($stageRoot)-ine$libraries-or[IO.Path]::GetFileName($stageRoot)-cne('.ac-library-stage-'+$pending.Nonce)-or[IO.Path]::GetDirectoryName($backup)-ine$libraries-or[IO.Path]::GetFileName($backup)-cne('.ac-library-backup-'+$pending.Nonce)-or$stage-ine[IO.Path]::Combine($stageRoot,'ac-library-'+[string]$p.Commit)){throw'Unsafe pending ac-library paths.'};foreach($path in @($libraries,$stageRoot,$stage,$backup,$target)){Assert-NoReparse $path};if($pending.Stage-eq'committed'){if(Test-Path -LiteralPath $stageRoot-or Test-Path -LiteralPath $backup){throw'Committed ac-library transaction files remain.'};exit 0};if(-not(Test-Path -LiteralPath $backup)){Remove-Safe $stageRoot;exit 0};if(Test-Path -LiteralPath $target){if(Test-Path -LiteralPath $stage){throw'The ac-library rollback staging path already exists.'};if(-not(Test-Path -LiteralPath $stageRoot)){[IO.Directory]::CreateDirectory($stageRoot)|Out-Null};[IO.Directory]::Move($target,$stage)};[IO.Directory]::Move($backup,$target);Remove-Safe $stageRoot}finally{$state.Dispose()}
::__CP_PENDING_ACL_WORKER_END__

::__CP_PENDING_ACL_COMMIT_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Hash-Bytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
::$state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true);if(-not$state){exit 0};$name='Pending.Acl.Intent'
::try{if(@($state.GetValueNames())-notcontains$name){exit 0};if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw'Invalid pending ac-library kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne5-or$p[0]-cne'v1'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw'Invalid pending ac-library intent.'};$bytes=[Convert]::FromBase64String($p[4]);if((Hash-Bytes $bytes)-cne$p[3]){throw'Invalid pending ac-library hash.'};$json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json;$schema=@('Version','OperationId','Root','Commit','StageRoot','StagePath','BackupPath');if(($plan|ConvertTo-Json -Compress)-cne$json-or(@($plan.PSObject.Properties.Name)-join"`0")-cne($schema-join"`0")-or[int]$plan.Version-ne1-or[string]$plan.OperationId-cne$p[1]-or[string]$plan.Commit-notmatch'^[0-9a-f]{40}$'){throw'Invalid pending ac-library plan.'};$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd([char]92);$libraries=[IO.Path]::GetFullPath((Join-Path $root 'libraries')).TrimEnd([char]92);$stageRoot=[IO.Path]::GetFullPath([string]$plan.StageRoot).TrimEnd([char]92);$backup=[IO.Path]::GetFullPath([string]$plan.BackupPath).TrimEnd([char]92);if([IO.Path]::GetFullPath([string]$plan.Root).TrimEnd([char]92)-ine$root-or[IO.Path]::GetDirectoryName($stageRoot)-ine$libraries-or[IO.Path]::GetFileName($stageRoot)-cne('.ac-library-stage-'+$p[1])-or[IO.Path]::GetDirectoryName($backup)-ine$libraries-or[IO.Path]::GetFileName($backup)-cne('.ac-library-backup-'+$p[1])){throw'Unsafe pending ac-library paths.'};if(Test-Path -LiteralPath $stageRoot-or Test-Path -LiteralPath $backup){throw'ac-library transaction files remain.'};if($p[2]-eq'prepared'){$committed='v1|'+$p[1]+'|committed|'+$p[3]+'|'+$p[4];$state.SetValue($name,$committed,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$committed){throw'Pending ac-library commit did not verify.'}};$state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw'Pending ac-library intent cleanup failed.'}}finally{$state.Dispose()}
::__CP_PENDING_ACL_COMMIT_END__

::__CP_PENDING_MASON_WORKER_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Hash-Bytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
::function Valid-List($values){$list=[string[]]@($values);$sorted=[string[]]@($list|Sort-Object -Unique);if($sorted.Count-ne$list.Count-or($sorted-join"`0")-cne($list-join"`0")-or@($list|Where-Object{$_-notmatch'^[A-Za-z0-9._-]+$'-or$_-in@('.','..')}).Count){throw'Invalid pending Mason inventory.'};$list}
::function Read-Plan([Microsoft.Win32.RegistryKey]$state){
::    $name='Pending.Mason.Intent';if(@($state.GetValueNames())-notcontains$name){return $null}
::    if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw'Invalid pending Mason registry kind.'}
::    $parts=([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)).Split([char]'|')
::    if($parts.Count-ne6-or$parts[0]-cne'v1'-or$parts[1]-notmatch'^[0-9a-f]{32}$'-or$parts[2]-notin@('prepared','committed')-or$parts[3]-notmatch'^[0-9]{1,19}$'-or$parts[4]-notmatch'^[0-9a-f]{64}$'){throw'Invalid pending Mason intent.'}
::    $bytes=[Convert]::FromBase64String($parts[5]);if((Hash-Bytes $bytes)-cne$parts[4]){throw'Invalid pending Mason hash.'}
::    $json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json
::    $schema=@('Version','BeforePackages','OwnedPackages','Frozen','CandidatePackages','ExcludedPackages','AttemptBeforePackages');$properties=@($plan.PSObject.Properties.Name)
::    if(($plan|ConvertTo-Json -Compress)-cne$json-or($properties-join"`0")-cne($schema-join"`0")-or[int]$plan.Version-ne1){throw'Invalid pending Mason plan.'}
::    $before=Valid-List $plan.BeforePackages;$owned=Valid-List $plan.OwnedPackages;$candidate=Valid-List $plan.CandidatePackages;$excluded=Valid-List $plan.ExcludedPackages;$attempt=Valid-List $plan.AttemptBeforePackages
::    if(@($candidate|Where-Object{$before-icontains$_-or$excluded-icontains$_}).Count-or@($excluded|Where-Object{$before-icontains$_}).Count){throw'Invalid pending Mason ownership sets.'}
::    if($parts[2]-eq'prepared'){if($owned.Count-or[bool]$plan.Frozen){throw'Invalid prepared Mason plan.'}}elseif(-not[bool]$plan.Frozen){throw'Invalid committed Mason plan.'}
::    [pscustomobject]@{Stage=$parts[2];Before=$before;Owned=$owned;Candidate=$candidate;Excluded=$excluded}
::}
::$state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$false)
::if(-not$state){exit 0}
::try{
::    $pending=Read-Plan $state;if(-not$pending-or$pending.Stage-eq'committed'){exit 0}
::    $boundary=[IO.Path]::GetFullPath($env:CP_SETUP_PROTECTED_NVIMDATA).TrimEnd([char]92);$root=[IO.Path]::GetFullPath((Join-Path $boundary 'mason\packages')).TrimEnd([char]92)
::    if(-not$root.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe Mason inventory root.'}
::    $cursor=$boundary;foreach($part in $root.Substring($boundary.Length).TrimStart([char]92).Split([char]92)){if($part){$cursor=Join-Path $cursor $part;if(Test-Path -LiteralPath $cursor){$item=Get-Item -LiteralPath $cursor -Force;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Reparse point blocks Mason inventory.'}}}}
::    if(Test-Path -LiteralPath $root){foreach($item in @(Get-ChildItem -LiteralPath $root -Force)){if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-or$item.Name-notmatch'^[A-Za-z0-9._-]+$'-or$item.Name-in@('.','..')){throw'Unsafe Mason package inventory entry.'};Write-Output $item.Name}}
::}finally{$state.Dispose()}
::__CP_PENDING_MASON_WORKER_END__

::__CP_PENDING_MASON_COMMIT_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Hash-Bytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
::function Valid-List($values){$list=[string[]]@($values);$sorted=[string[]]@($list|Sort-Object -Unique);if($sorted.Count-ne$list.Count-or($sorted-join"`0")-cne($list-join"`0")-or@($list|Where-Object{$_-notmatch'^[A-Za-z0-9._-]+$'-or$_-in@('.','..')}).Count){throw'Invalid pending Mason inventory.'};$list}
::function Read-Plan([Microsoft.Win32.RegistryKey]$state){
::    $name='Pending.Mason.Intent';if(@($state.GetValueNames())-notcontains$name){return $null}
::    if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw'Invalid pending Mason registry kind.'}
::    $raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$parts=$raw.Split([char]'|')
::    if($parts.Count-ne6-or$parts[0]-cne'v1'-or$parts[1]-notmatch'^[0-9a-f]{32}$'-or$parts[2]-notin@('prepared','committed')-or$parts[3]-notmatch'^[0-9]{1,19}$'-or$parts[4]-notmatch'^[0-9a-f]{64}$'){throw'Invalid pending Mason intent.'}
::    $bytes=[Convert]::FromBase64String($parts[5]);if((Hash-Bytes $bytes)-cne$parts[4]){throw'Invalid pending Mason hash.'}
::    $json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json;$schema=@('Version','BeforePackages','OwnedPackages','Frozen','CandidatePackages','ExcludedPackages','AttemptBeforePackages');$properties=@($plan.PSObject.Properties.Name)
::    if(($plan|ConvertTo-Json -Compress)-cne$json-or($properties-join"`0")-cne($schema-join"`0")-or[int]$plan.Version-ne1){throw'Invalid pending Mason plan.'}
::    $before=Valid-List $plan.BeforePackages;$owned=Valid-List $plan.OwnedPackages;$candidate=Valid-List $plan.CandidatePackages;$excluded=Valid-List $plan.ExcludedPackages;$attempt=Valid-List $plan.AttemptBeforePackages
::    if(@($candidate|Where-Object{$before-icontains$_-or$excluded-icontains$_}).Count-or@($excluded|Where-Object{$before-icontains$_}).Count){throw'Invalid pending Mason ownership sets.'}
::    if($parts[2]-eq'prepared'){if($owned.Count-or[bool]$plan.Frozen){throw'Invalid prepared Mason plan.'}}elseif(-not[bool]$plan.Frozen){throw'Invalid committed Mason plan.'}
::    [pscustomobject]@{Raw=$raw;Parts=$parts;Plan=$plan;Before=$before;Owned=$owned;Candidate=$candidate;Excluded=$excluded;Attempt=$attempt}
::}
::$state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true)
::if(-not$state){exit 0}
::$name='Pending.Mason.Intent'
::try{
::    $pending=Read-Plan $state;if(-not$pending){exit 0};$parts=$pending.Parts;$owned=$pending.Owned
::    if($parts[2]-eq'prepared'){
::        $current=Valid-List @([IO.File]::ReadAllLines($env:PENDING_MASON_INVENTORY)|Where-Object{$_}|Sort-Object -Unique)
::        $owned=[string[]]@($current|Where-Object{$pending.Candidate-icontains$_-and$pending.Before-inotcontains$_-and$pending.Excluded-inotcontains$_}|Sort-Object -Unique)
::        $committedPlan=[ordered]@{Version=1;BeforePackages=[string[]]$pending.Before;OwnedPackages=$owned;Frozen=$true;CandidatePackages=[string[]]$pending.Candidate;ExcludedPackages=[string[]]$pending.Excluded;AttemptBeforePackages=[string[]]$pending.Attempt}
::        $json=$committedPlan|ConvertTo-Json -Compress;$bytes=[Text.Encoding]::UTF8.GetBytes($json);$committed='v1|'+$parts[1]+'|committed|'+$parts[3]+'|'+(Hash-Bytes $bytes)+'|'+[Convert]::ToBase64String($bytes)
::        $state.SetValue('Mason.Packages',$owned,[Microsoft.Win32.RegistryValueKind]::MultiString);$state.SetValue('Mason.Inventory.Frozen',1,[Microsoft.Win32.RegistryValueKind]::DWord);$state.SetValue($name,$committed,[Microsoft.Win32.RegistryValueKind]::String)
::        if([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$committed){throw'Pending Mason commit did not verify.'}
::    }
::    if($state.GetValueKind('Mason.Packages')-ne[Microsoft.Win32.RegistryValueKind]::MultiString-or$state.GetValueKind('Mason.Inventory.Frozen')-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$state.GetValue('Mason.Inventory.Frozen',0)-ne1){throw'Mason inventory commit failed.'}
::    $recorded=Valid-List $state.GetValue('Mason.Packages');if(($recorded-join"`0")-cne($owned-join"`0")){throw'Committed Mason inventory is invalid.'}
::    $state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw'Pending Mason intent cleanup failed.'}
::}finally{$state.Dispose()}
::__CP_PENDING_MASON_COMMIT_END__

::__CP_SECURE_RUNTIME_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::$admin=[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
::$system=[Security.Principal.SecurityIdentifier]::new('S-1-5-18')
::$target=[Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)
::function New-Security([bool]$includeTarget) {
::    $acl=[Security.AccessControl.DirectorySecurity]::new()
::    $acl.SetAccessRuleProtection($true,$false)
::    $acl.SetOwner($admin)
::    $inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit
::    foreach($sid in @($admin,$system)){
::        $rule=[Security.AccessControl.FileSystemAccessRule]::new($sid,[Security.AccessControl.FileSystemRights]::Modify,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow)
::        [void]$acl.AddAccessRule($rule)
::    }
::    if($includeTarget){$rule=[Security.AccessControl.FileSystemAccessRule]::new($target,[Security.AccessControl.FileSystemRights]::ReadAndExecute,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow);[void]$acl.AddAccessRule($rule)}
::    $acl
::}
::function Get-Sid([Security.Principal.IdentityReference]$identity){try{$identity.Translate([Security.Principal.SecurityIdentifier]).Value}catch{[string]$identity}}
::function Assert-RuntimeSecurity([string]$path,[bool]$includeTarget){
::    $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
::    if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Runtime path is unsafe.'}
::    $acl=$item.GetAccessControl();$owner=Get-Sid([Security.Principal.NTAccount]$acl.Owner)
::    if($owner-notin@($admin.Value,$system.Value)-or-not$acl.AreAccessRulesProtected){throw'Runtime path ACL is not protected.'}
::    $allowed=@($admin.Value,$system.Value);if($includeTarget){$allowed+=$target.Value};foreach($ace in $acl.Access){$sid=Get-Sid $ace.IdentityReference;if($sid-notin$allowed-or$ace.AccessControlType-ne[Security.AccessControl.AccessControlType]::Allow-or$ace.IsInherited){throw'Runtime ACL contains an untrusted rule.'};if($sid-eq$target.Value-and($ace.FileSystemRights-ne[Security.AccessControl.FileSystemRights]::ReadAndExecute-or$ace.InheritanceFlags-ne([Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit)-or$ace.PropagationFlags-ne[Security.AccessControl.PropagationFlags]::None)){throw'Runtime target-user rule is unsafe.'}}
::}
::function Assert-MarkerDirectory([string]$path){
::    $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
::    if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Runtime marker directory is unsafe.'}
::    $acl=$item.GetAccessControl();$owner=Get-Sid([Security.Principal.NTAccount]$acl.Owner)
::    if($owner-notin@($admin.Value,$system.Value)-or-not$acl.AreAccessRulesProtected){throw'Runtime marker ACL is not protected.'}
::    $writeMask=[Security.AccessControl.FileSystemRights]::WriteData-bor[Security.AccessControl.FileSystemRights]::AppendData-bor[Security.AccessControl.FileSystemRights]::WriteExtendedAttributes-bor[Security.AccessControl.FileSystemRights]::WriteAttributes-bor[Security.AccessControl.FileSystemRights]::ChangePermissions-bor[Security.AccessControl.FileSystemRights]::TakeOwnership
::    foreach($ace in $acl.Access){$sid=Get-Sid $ace.IdentityReference;if($sid-notin@($admin.Value,$system.Value)-and$ace.AccessControlType-eq[Security.AccessControl.AccessControlType]::Allow-and([int64]$ace.FileSystemRights-band[int64]$writeMask)){throw'Runtime marker directory is writable by an untrusted identity.'}}
::}
::function Remove-NoFollow([string]$path,[string]$boundary){
::    $full=[IO.Path]::GetFullPath($path).TrimEnd([char]92)
::    if($full-ine$boundary-and-not$full.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe runtime cleanup path.'}
::    if(-not(Test-Path -LiteralPath $full)){return}
::    $item=Get-Item -LiteralPath $full -Force
::    if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Runtime cleanup encountered a reparse point.'}
::    if($item.PSIsContainer){foreach($child in @($item.GetFileSystemInfos())){Remove-NoFollow $child.FullName $full}}else{$item.Attributes=[IO.FileAttributes]::Normal}
::    $item.Delete()
::}
::$programData=[IO.Path]::GetFullPath([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)).TrimEnd([char]92)
::$base=[IO.Path]::GetFullPath((Join-Path $programData 'my-cp-setup-runtime')).TrimEnd([char]92)
::if(-not$base.StartsWith($programData+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe runtime root.'}
::$run=[IO.Path]::GetFullPath((Join-Path $base([guid]::NewGuid().ToString('N')))).TrimEnd([char]92)
::$marker=$null
::try{
::    if(-not$run.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe runtime directory.'}
::    if($env:CP_RUNTIME_OPERATION_ID){
::        if($env:CP_RUNTIME_OPERATION_ID-notmatch'^[0-9a-f]{32}$'){throw'Invalid runtime operation id.'}
::        $transcript=[IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR).TrimEnd([char]92)
::        $transcriptBase=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)
::        if(-not$transcript.StartsWith($transcriptBase+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($transcript)-notmatch'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'){throw'Invalid runtime marker destination.'}
::        Assert-MarkerDirectory $transcript
::        $marker=Join-Path $transcript 'runtime.marker'
::        [int]$wrapperPid=0;[long]$wrapperTicks=0;if(-not[int]::TryParse($env:CP_ELEVATED_WRAPPER_PID,[ref]$wrapperPid)-or$wrapperPid-le4-or-not[long]::TryParse($env:CP_ELEVATED_WRAPPER_START_TICKS,[ref]$wrapperTicks)-or$wrapperTicks-le0){throw'Invalid elevated-wrapper identity.'}
::        $stream=[IO.FileStream]::new($marker,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
::        try{$bytes=[Text.Encoding]::UTF8.GetBytes($env:CP_RUNTIME_OPERATION_ID+'|'+$run+'|'+$wrapperPid+'|'+$wrapperTicks);$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
::    }
::    if(-not[IO.Directory]::Exists($base)){[IO.Directory]::CreateDirectory($base,(New-Security $false))|Out-Null}
::    Assert-RuntimeSecurity $base $false
::    [IO.Directory]::CreateDirectory($run,(New-Security $true))|Out-Null
::    Assert-RuntimeSecurity $run $true
::    $bootstrap=[IO.Path]::GetFullPath($env:SECURE_RUNTIME_BOOTSTRAP).TrimEnd([char]92)
::    $output=[IO.Path]::GetFullPath($env:SECURE_RUNTIME_OUTPUT)
::    if([IO.Path]::GetDirectoryName($output)-ine$bootstrap-or[IO.Path]::GetFileName($output)-cne'runtime.txt'){throw'Unsafe secure-runtime output path.'}
::    if($env:SECURE_RUNTIME_BOOTSTRAP_OWNED-eq'1'){Assert-RuntimeSecurity $bootstrap}else{Assert-MarkerDirectory $bootstrap}
::    $outputStream=[IO.FileStream]::new($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
::    try{$bytes=[Text.Encoding]::UTF8.GetBytes($run);$outputStream.Write($bytes,0,$bytes.Length);$outputStream.Flush($true)}finally{$outputStream.Dispose()}
::}catch{
::    if($marker-and[IO.File]::Exists($marker)){[IO.File]::Delete($marker)}
::    if($run-and[IO.Directory]::Exists($run)){Remove-NoFollow $run $run}
::    if([IO.Directory]::Exists($base)){$baseItem=Get-Item -LiteralPath $base -Force;if(-not($baseItem.Attributes-band[IO.FileAttributes]::ReparsePoint)-and@($baseItem.GetFileSystemInfos()).Count-eq0){$baseItem.Delete()}}
::    throw
::}
::__CP_SECURE_RUNTIME_END__

::__CP_NATIVE_ARTIFACTS_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::$phase=[string]$env:NATIVE_ARTIFACT_PHASE
::if($phase-notin@('before','after','recover')){throw'Invalid native artifact inventory phase.'}
::$local=[IO.Path]::GetFullPath($env:CP_SETUP_TARGET_LOCALAPPDATA).TrimEnd([char]92)
::$runtime=[IO.Path]::GetFullPath($env:CP_RUNTIME_TEMP).TrimEnd([char]92)
::$temp=[IO.Path]::GetFullPath($env:TEMP).TrimEnd([char]92)
::$tmp=[IO.Path]::GetFullPath($env:TMP).TrimEnd([char]92)
::$programData=[IO.Path]::GetFullPath([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)).TrimEnd([char]92)
::$runtimeBase=[IO.Path]::GetFullPath((Join-Path $programData 'my-cp-setup-runtime')).TrimEnd([char]92)
::if($temp-ine$runtime-or$tmp-ine$runtime-or-not$runtime.StartsWith($runtimeBase+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($runtime)-notmatch'^[0-9a-f]{32}$'){throw'Native uninstaller TEMP and TMP are not protected.'}
::$snapshot=$null
::if($phase-ne'recover'){$snapshot=[IO.Path]::GetFullPath($env:MSYS2_ARTIFACT_SNAPSHOT);if(-not$snapshot.StartsWith($runtime+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($snapshot)-notmatch'^cp_setup_msys2_artifacts_[0-9]+_[0-9]+\.txt$'){throw'Unsafe native artifact snapshot path.'}}
::$cacheRoot=[IO.Path]::GetFullPath((Join-Path $local 'cache')).TrimEnd([char]92)
::$qtRoot=[IO.Path]::GetFullPath((Join-Path $cacheRoot 'qt-installer-framework')).TrimEnd([char]92)
::$tempArtifactRoot=[IO.Path]::GetFullPath((Join-Path $local 'Temp\nvim')).TrimEnd([char]92)
::function Assert-NoReparsePath([string]$boundary,[string]$path){
::    $boundary=[IO.Path]::GetFullPath($boundary).TrimEnd([char]92);$path=[IO.Path]::GetFullPath($path).TrimEnd([char]92)
::    if($path-ine$boundary-and-not$path.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw('Unsafe artifact inventory path: '+$path)}
::    $cursor=$boundary
::    if([IO.File]::Exists($cursor)-or[IO.Directory]::Exists($cursor)){if((Get-Item -LiteralPath $cursor -Force).Attributes-band[IO.FileAttributes]::ReparsePoint){throw('Reparse point blocks artifact inventory: '+$cursor)}}
::    if($path.Length-gt$boundary.Length){foreach($part in $path.Substring($boundary.Length).TrimStart([char]92).Split([char]92)){if($part){$cursor=Join-Path $cursor $part;if([IO.File]::Exists($cursor)-or[IO.Directory]::Exists($cursor)){if((Get-Item -LiteralPath $cursor -Force).Attributes-band[IO.FileAttributes]::ReparsePoint){throw('Reparse point blocks artifact inventory: '+$cursor)}}}}}
::}
::Assert-NoReparsePath $runtime $runtime
::function Get-Inventory {
::    $result=[Collections.Generic.List[string]]::new()
::    if(-not[IO.Directory]::Exists($qtRoot)){return $result.ToArray()}
::    Assert-NoReparsePath $local $qtRoot
::    $root=Get-Item -LiteralPath $qtRoot -Force
::    if(-not$root.PSIsContainer){throw'Qt Installer Framework cache root is not a directory.'}
::    $stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root);$result.Add($qtRoot)
::    while($stack.Count){$dir=$stack.Pop();foreach($item in @($dir.GetFileSystemInfos())){$full=[IO.Path]::GetFullPath($item.FullName).TrimEnd([char]92);if(-not$full.StartsWith($qtRoot+[char]92,[StringComparison]::OrdinalIgnoreCase)-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw('Unsafe Qt Installer Framework cache entry: '+$full)};$result.Add($full);if($item-is[IO.DirectoryInfo]){$stack.Push($item)}}}
::    $result.ToArray()
::}
::function Get-StrictCandidate([string]$directory){
::    $full=[IO.Path]::GetFullPath($directory).TrimEnd([char]92)
::    if([IO.Path]::GetDirectoryName($full)-ine$qtRoot-or[IO.Path]::GetFileName($full)-notmatch'^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$'-or-not[IO.Directory]::Exists($full)){return @()}
::    Assert-NoReparsePath $local $full
::    $dir=Get-Item -LiteralPath $full -Force;$items=@($dir.GetFileSystemInfos())
::    if($items.Count-ne1-or$items[0]-is[IO.DirectoryInfo]-or$items[0].Name-cne'manifest.json'-or($items[0].Attributes-band[IO.FileAttributes]::ReparsePoint)){return @()}
::    $manifest=[IO.Path]::GetFullPath($items[0].FullName)
::    if($items[0].Length-gt4096){return @()}
::    try{$data=Get-Content -LiteralPath $manifest -Raw -Encoding UTF8|ConvertFrom-Json}catch{return @()}
::    $properties=@($data.PSObject.Properties.Name)
::    if($properties.Count-ne3-or$properties-notcontains'items'-or$properties-notcontains'type'-or$properties-notcontains'version'-or[string]$data.type-cne'Metadata'-or[string]$data.version-notmatch'^\d+\.\d+\.\d+$'-or@($data.items).Count-ne0){return @()}
::    @($manifest,$full)
::}
::function New-PathSet {return ,([Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase))}
::function Read-OwnedPaths([Microsoft.Win32.RegistryKey]$state,[string]$name){
::    $set=New-PathSet
::    foreach($raw in @($state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames))){
::        if(-not$raw){throw('Empty artifact state path: '+$name)}
::        $text=([string]$raw).TrimEnd([char]92);$full=[IO.Path]::GetFullPath($text).TrimEnd([char]92)
::        $allowed=$full-ieq$qtRoot-or$full.StartsWith($qtRoot+[char]92,[StringComparison]::OrdinalIgnoreCase)-or$full-ieq$tempArtifactRoot-or$full.StartsWith($tempArtifactRoot+[char]92,[StringComparison]::OrdinalIgnoreCase)
::        if($full-ine$text-or-not$allowed){throw('Unsafe artifact state path: '+$text)}
::        if([IO.File]::Exists($full)-or[IO.Directory]::Exists($full)){Assert-NoReparsePath $local $full}
::        if(-not$set.Add($full)){throw('Duplicate artifact state path: '+$full)}
::    }
::    return ,$set
::}
::$state=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($env:CP_SETUP_TARGET_STATE_RELATIVE,$true)
::if(-not$state){if($phase-eq'recover'){exit 0};throw'Protected setup state is missing during native artifact inventory.'}
::try{
::    $option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames;$names=@($state.GetValueNames())
::    foreach($required in @('Target.Sid','Target.LocalAppData')){if($names-notcontains$required){throw('Missing protected artifact metadata: '+$required)}}
::    if([string]$state.GetValue('Target.Sid',$null,$option)-cne$env:CP_SETUP_TARGET_SID-or[IO.Path]::GetFullPath([string]$state.GetValue('Target.LocalAppData',$null,$option)).TrimEnd([char]92)-ine$local){throw'Protected artifact target metadata is invalid.'}
::    $hasBefore=$names-contains'Artifacts.Before.Paths';$hasCreated=$names-contains'Artifacts.Created.Paths'
::    if($hasBefore-xor$hasCreated){throw'Artifact ownership metadata is incomplete.'}
::    if(-not$hasBefore){
::        $initial=[string[]]@(Get-Inventory)
::        $state.SetValue('Artifacts.Before.Paths',$initial,[Microsoft.Win32.RegistryValueKind]::MultiString)
::        $state.SetValue('Artifacts.Created.Paths',[string[]]@(),[Microsoft.Win32.RegistryValueKind]::MultiString)
::    }else{foreach($name in @('Artifacts.Before.Paths','Artifacts.Created.Paths')){if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::MultiString){throw('Unsafe artifact state kind: '+$name)}}}
::    $before=Read-OwnedPaths $state 'Artifacts.Before.Paths';$created=Read-OwnedPaths $state 'Artifacts.Created.Paths'
::    function Add-Owned([string]$path){$full=[IO.Path]::GetFullPath($path).TrimEnd([char]92);if(-not$before.Contains($full)){[void]$created.Add($full)}}
::    if($phase-in@('before','recover')){
::        $inventory=[string[]]@(Get-Inventory)
::        foreach($path in $inventory){if([IO.Directory]::Exists($path)-and[IO.Path]::GetDirectoryName($path)-ieq$qtRoot){$candidate=@(Get-StrictCandidate $path);if($candidate.Count-eq2){foreach($owned in $candidate){Add-Owned $owned};Add-Owned $qtRoot}}}
::        if($phase-eq'before'){[IO.File]::WriteAllLines($snapshot,$inventory,[Text.UTF8Encoding]::new($false))}
::    }else{
::        if(-not[IO.File]::Exists($snapshot)){throw'Native artifact before-snapshot is missing.'};Assert-NoReparsePath $runtime $snapshot
::        $prior=New-PathSet;foreach($line in [IO.File]::ReadAllLines($snapshot)){if($line){[void]$prior.Add([IO.Path]::GetFullPath($line).TrimEnd([char]92))}}
::        $inventory=[string[]]@(Get-Inventory);$new=@($inventory|Where-Object{-not$prior.Contains($_)})
::        $candidateDirs=New-PathSet
::        foreach($path in $new){
::            if($path-ieq$qtRoot){Add-Owned $qtRoot;continue}
::            if([IO.Directory]::Exists($path)-and[IO.Path]::GetDirectoryName($path)-ieq$qtRoot){[void]$candidateDirs.Add($path);continue}
::            if([IO.File]::Exists($path)-and[IO.Path]::GetFileName($path)-ceq'manifest.json'-and[IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($path))-ieq$qtRoot){[void]$candidateDirs.Add([IO.Path]::GetDirectoryName($path));continue}
::            throw('Native uninstaller created a non-allowlisted cache entry: '+$path)
::        }
::        foreach($directory in $candidateDirs){$candidate=@(Get-StrictCandidate $directory);if($candidate.Count-ne2){throw('Native uninstaller created an invalid Qt cache entry: '+$directory)};foreach($owned in $candidate){Add-Owned $owned};if(-not$before.Contains($qtRoot)){Add-Owned $qtRoot}}
::    }
::    $ordered=[string[]]@($created|Sort-Object);$state.SetValue('Artifacts.Created.Paths',$ordered,[Microsoft.Win32.RegistryValueKind]::MultiString)
::    $verify=Read-OwnedPaths $state 'Artifacts.Created.Paths';if(-not$verify.SetEquals($created)){throw'Native artifact ownership state verification failed.'}
::}finally{$state.Dispose()}
::__CP_NATIVE_ARTIFACTS_END__

::__CP_UNINSTALL_ELEVATE_BEGIN__
::$ErrorActionPreference = 'Stop'
::Set-StrictMode -Version 2
::function Read-Block([string]$begin,[string]$end) {
::    $lines=[IO.File]::ReadAllLines($env:CP_UNINSTALL_SCRIPT)
::    $first=[Array]::IndexOf($lines,'::'+$begin)
::    $last=[Array]::IndexOf($lines,'::'+$end)
::    if($first-lt 0-or$last-le$first){throw('Missing source block: '+$begin)}
::    $content=[Collections.Generic.List[string]]::new()
::    for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw'Malformed source block.'};$content.Add($lines[$i].Substring(2))}
::    $content-join[Environment]::NewLine
::}
::function Read-TextBlock([string]$text,[string]$begin,[string]$end) {
::    $lines=$text-split'\r?\n';$first=[Array]::IndexOf($lines,'::'+$begin);$last=[Array]::IndexOf($lines,'::'+$end)
::    if($first-lt0-or$last-le$first){throw('Missing verified source block: '+$begin)}
::    $content=[Collections.Generic.List[string]]::new();for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw'Malformed verified source block.'};$content.Add($lines[$i].Substring(2))};$content-join[Environment]::NewLine
::}
::function Parse-Seconds([string]$value,[int]$fallback){[int]$parsed=0;if(-not[int]::TryParse($value,[ref]$parsed)-or$parsed-lt 1){return$fallback};$parsed}
::function Assert-LogDestination([string]$path){
::    if([string]::IsNullOrWhiteSpace($path)){$path=Join-Path $env:CP_VISIBLE_TEMP 'cp_setup_uninstall.log'}
::    if(-not[IO.Path]::IsPathRooted($path)){$path=Join-Path $env:ROOT $path}
::    $full=[IO.Path]::GetFullPath($path);$parent=[IO.Path]::GetDirectoryName($full)
::    if(-not$parent-or-not[IO.Directory]::Exists($parent)){throw'Transcript destination directory does not exist.'}
::    $root=[IO.Path]::GetPathRoot($parent);$current=$root
::    foreach($part in $parent.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)){$current=[IO.Path]::Combine($current,$part);if([IO.File]::GetAttributes($current)-band[IO.FileAttributes]::ReparsePoint){throw'Transcript destination contains a reparse point.'}}
::    if([IO.File]::Exists($full)-and([IO.File]::GetAttributes($full)-band[IO.FileAttributes]::ReparsePoint)){throw'Transcript destination is a reparse point.'}
::    $full
::}
::function Remove-ProtectedTranscript([string]$path){
::    if(-not[IO.Directory]::Exists($path)){return}
::    $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)+[char]92
::    $full=[IO.Path]::GetFullPath($path).TrimEnd([char]92)
::    if(-not$full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($full)-notmatch'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'){throw'Unsafe transcript cleanup path.'}
::    $root=[IO.DirectoryInfo]::new($full)
::    if($root.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Transcript root is a reparse point.'}
::    $stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root)
::    while($stack.Count){$dir=$stack.Pop();foreach($item in $dir.EnumerateFileSystemInfos()){if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Transcript contains a reparse point.'};if($item-is[IO.DirectoryInfo]){$stack.Push($item)}}}
::    [IO.Directory]::Delete($full,$true)
::}
::function Get-TranscriptSummary([string]$path){
::    $raw=[IO.File]::ReadAllText($path,[Text.Encoding]::Default)
::    $ansi=[string][char]27+'\[[0-?]*[ -/]*[@-~]'
::    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
::    $summary=[Collections.Generic.List[string]]::new()
::    foreach($fragment in [regex]::Split($raw,'[\r\n]+')){
::        $plain=[regex]::Replace($fragment,$ansi,'')
::        $plain=[regex]::Replace($plain,'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]','').Trim()
::        if($plain.Length-gt512-or$plain-notmatch'^\[(FOUND|KEPT|MISSING|REMOVED|UNINSTALLED)\] .+'){continue}
::        if($seen.Add($plain)){$summary.Add($plain)}
::        if($summary.Count-ge100){break}
::    }
::    @($summary)
::}
::function Save-AuthoritativeTranscript([string]$source,[string]$destination,[int]$exitCode,[string]$fallbackEvent){
::    $lines=[Collections.Generic.List[string]]::new()
::    if($source -and [IO.File]::Exists($source)){foreach($line in [IO.File]::ReadAllLines($source,[Text.Encoding]::Default)){if($line-notmatch'^\[CP-SETUP\] END(?:\s|$)'){$lines.Add($line)}}}
::    if(-not$lines.Count-or$lines[0]-notmatch'^\[CP-SETUP\] START(?:\s|$)'){$lines.Insert(0,'[CP-SETUP] START timestamp='+[DateTimeOffset]::Now.ToString('o')+' runnerPid='+$PID+' targetSid='+$env:CP_SETUP_TARGET_SID+' elevatedSid=none')}
::    if($fallbackEvent){$lines.Add('[CP-SETUP] ORCHESTRATOR '+$fallbackEvent)}
::    $lines.Add('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit='+$exitCode)
::    [IO.File]::WriteAllLines($destination,$lines,[Text.Encoding]::Default)
::}
::function Read-DeferredCompletion([string]$path){
::    $full=[IO.Path]::GetFullPath($path);if([IO.Path]::GetDirectoryName($full)-ine$transcriptDir-or[IO.Path]::GetFileName($full)-cne'completion.txt'){throw'Unsafe deferred-completion path.'}
::    if(-not[IO.File]::Exists($full)){throw'Deferred uninstall completion is missing.'};$item=Get-Item -LiteralPath $full -Force -ErrorAction Stop;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint-or$item.Length-lt1-or$item.Length-gt4096){throw'Invalid deferred uninstall completion.'}
::    $bytes=[IO.File]::ReadAllBytes($full);if($bytes.Length-ne$item.Length){throw'Deferred uninstall completion changed while being read.'};[Text.Encoding]::Default.GetString($bytes)
::}
::function Publish-DeferredCompletion([string]$text){
::    $path=[IO.Path]::GetFullPath($env:CP_ELEVATE_PROTOCOL_FILE);$parent=[IO.Path]::GetFullPath($env:CP_VISIBLE_TEMP).TrimEnd([char]92)
::    if([IO.Path]::GetDirectoryName($path)-ine$parent-or[IO.Path]::GetFileName($path)-notmatch'^cp_setup_uninstall_protocol_[0-9]+_[0-9]+\.txt$'-or[IO.File]::Exists($path)-or[IO.Directory]::Exists($path)){throw'Unsafe uninstall protocol destination.'}
::    $bytes=[Text.Encoding]::Default.GetBytes($text);if($bytes.Length-lt1-or$bytes.Length-gt4096){throw'Invalid uninstall protocol payload.'}
::    $stream=[IO.FileStream]::new($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
::}
::$tokens=@($env:CP_UNINSTALL_ARGS-split'\s+'|Where-Object{$_})
::$allowed=@('--all','--non-interactive','--no-pause','--check')
::if(@($tokens|Where-Object{$allowed-notcontains$_}).Count){throw'Unsafe elevated uninstaller arguments.'}
::$isCheck=$tokens-contains'--check'
::$uacTimeout=Parse-Seconds $env:CP_ELEVATE_UAC_TIMEOUT_SECONDS 300
::$childTimeout=Parse-Seconds $env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS 7200
::$destination=Assert-LogDestination $env:UNINSTALL_LOG_REQUESTED
::$transcriptDir=Join-Path(Join-Path $env:SystemRoot 'Temp')('cp-setup-uninstall-transcript-'+[guid]::NewGuid().ToString('N'))
::$transcript=Join-Path $transcriptDir 'uninstall.log'
::$sourceGuard=Read-Block '__CP_SOURCE_LOCK_NATIVE_BEGIN__' '__CP_SOURCE_LOCK_NATIVE_END__'
::if(-not('CpSetup.Native.SourceLease'-as[type])){Add-Type -TypeDefinition $sourceGuard -Language CSharp -ErrorAction Stop}
::$sourceLease=[CpSetup.Native.SourceLease]::Acquire($env:CP_UNINSTALL_SCRIPT)
::$sourceSha256=$sourceLease.Hash
::$verifiedSource=$sourceLease.ReadAllText();$verifiedGuard=Read-TextBlock $verifiedSource '__CP_SOURCE_LOCK_NATIVE_BEGIN__' '__CP_SOURCE_LOCK_NATIVE_END__'
::if($verifiedGuard-cne$sourceGuard){throw'Uninstaller source changed before its lease was acquired.'}
::$transport=[IO.Path]::GetFullPath($env:CP_SOURCE_TRANSPORT_PATH);$transportParent=[IO.Path]::GetFullPath($env:CP_VISIBLE_TEMP).TrimEnd([char]92);if([IO.Path]::GetDirectoryName($transport)-ine$transportParent-or[IO.Path]::GetFileName($transport)-notmatch'^cp_setup_uninstall_source_[0-9]+_[0-9]+\.transport$'){throw'Unsafe source transport path.'};$transportLease=$sourceLease.CopyTo($transport)
::$payload=Read-TextBlock $verifiedSource '__CP_UNINSTALL_CHILD_BEGIN__' '__CP_UNINSTALL_CHILD_END__'
::$guardB64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sourceGuard));$childSource=$payload
::$input=[IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($childSource));$packed=[IO.MemoryStream]::new();$gzip=[IO.Compression.GzipStream]::new($packed,[IO.Compression.CompressionMode]::Compress,$true);try{$input.CopyTo($gzip)}finally{$gzip.Dispose();$input.Dispose()};$encoded=[Convert]::ToBase64String($packed.ToArray());$packed.Dispose()
::$processTreeSource=Read-TextBlock $verifiedSource '__CP_PROCESS_TREE_NATIVE_BEGIN__' '__CP_PROCESS_TREE_NATIVE_END__'
::if(-not('CpSetup.Native.ProcessTree'-as[type])){Add-Type -TypeDefinition $processTreeSource -Language CSharp -ErrorAction Stop}
::$startedFile=Join-Path $transcriptDir 'started.marker'
::$elevationNonce=[guid]::NewGuid().ToString('N')
::$cancelFile=Join-Path $env:CP_VISIBLE_TEMP ('cp_setup_uninstall_cancel_'+$elevationNonce+'.signal');if([IO.File]::Exists($cancelFile)){throw'Elevation cancellation path already exists.'}
::function Stop-ElevatedTree {
::    if(-not[IO.File]::Exists($startedFile)){return}
::    $parts=([IO.File]::ReadAllText($startedFile).Trim()).Split([char]'|');[int]$processId=0;[long]$startTicks=0
::    if($parts.Count-ne3-or$parts[0]-cne$elevationNonce-or-not[int]::TryParse($parts[1],[ref]$processId)-or$processId-le4-or-not[long]::TryParse($parts[2],[ref]$startTicks)-or$startTicks-le0){throw'Invalid elevated-process marker.'}
::    try{$root=[Diagnostics.Process]::GetProcessById($processId)}catch [ArgumentException]{return}
::    try{
::        if($root.StartTime.ToUniversalTime().Ticks-ne$startTicks-or[IO.Path]::GetFullPath([CpSetup.Native.ProcessTree]::ImagePath($processId))-ine[IO.Path]::GetFullPath($env:POWERSHELL_EXE)){throw'Elevated-process identity changed.'}
::        $members=[Collections.Generic.List[Diagnostics.Process]]::new();foreach($pidValue in [CpSetup.Native.ProcessTree]::Snapshot($processId)){try{$candidate=[Diagnostics.Process]::GetProcessById($pidValue);if($candidate.StartTime.ToUniversalTime().Ticks-le[DateTime]::UtcNow.AddSeconds(2).Ticks){$members.Add($candidate)}else{$candidate.Dispose()}}catch{}}
::        try{for($index=$members.Count-1;$index-ge0;$index--){try{if(-not$members[$index].HasExited){$members[$index].Kill()}}catch{}};$deadline=[DateTime]::UtcNow.AddSeconds(5);foreach($member in $members){try{if(-not$member.HasExited){$remaining=[Math]::Max(0,[int]($deadline-[DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt0){[void]$member.WaitForExit($remaining)}}}catch{}};$survivors=@($members|Where-Object{try{-not$_.HasExited}catch{$false}});if($survivors.Count){throw('Elevated process-tree survivors: '+(($survivors.Id|Sort-Object)-join', '))}}finally{foreach($member in $members){$member.Dispose()}}
::    }finally{$root.Dispose()}
::}
::Remove-Item -LiteralPath $startedFile -Force -ErrorAction SilentlyContinue
::$env:CP_ELEVATE_PAYLOAD=$encoded
::$env:CP_ELEVATE_TRANSCRIPT_TARGET=$transcriptDir
::$env:CP_ELEVATE_NONCE=$elevationNonce
::$env:CP_ELEVATE_CANCEL_FILE=$cancelFile
::$env:CP_ELEVATE_ALREADY_ADMIN_VALUE=if($env:ELEVATE_ALREADY_ADMIN-eq'1'){'1'}else{'0'}
::$env:CP_ELEVATE_WINDOW_STYLE=if($isCheck-or$tokens-contains'--non-interactive'){'Hidden'}else{'Normal'}
::$env:CP_UNINSTALL_SOURCE_SHA256=$sourceSha256
::$env:CP_SOURCE_GUARD_B64=$guardB64
::$env:CP_SETUP_ORIGINAL_ROOT=$env:ROOT
::$env:CP_DEFER_COMPLETION_FILE=Join-Path $transcriptDir 'completion.txt'
::$launcher={
::    $ErrorActionPreference='Stop'
::    try{
::        $env:CP_ELEVATE_TRANSCRIPT_DIR=$env:CP_ELEVATE_TRANSCRIPT_TARGET;$env:CP_UNINSTALL_SCRIPT=''
::        $env:CP_SETUP_ELEVATED_CHILD='1';$env:CP_ELEVATION_PARENT='1';$env:CP_RUNTIME_OPERATION_ID=$env:CP_ELEVATE_NONCE
::        [int]$childTimeout=0;if(-not[int]::TryParse($env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS,[ref]$childTimeout)-or$childTimeout-lt1){$childTimeout=7200}
::        $bootstrap={$ErrorActionPreference='Stop';$packed=[Convert]::FromBase64String('__CP_PACKED_PAYLOAD__');$input=[IO.MemoryStream]::new($packed);$gzip=[IO.Compression.GzipStream]::new($input,[IO.Compression.CompressionMode]::Decompress);$reader=[IO.StreamReader]::new($gzip,[Text.Encoding]::UTF8,$true);try{$childSource=$reader.ReadToEnd()}finally{$reader.Dispose();$gzip.Dispose();$input.Dispose()};&([scriptblock]::Create($childSource))}
::        $bootstrapSource=$bootstrap.ToString().Replace('__CP_PACKED_PAYLOAD__',$env:CP_ELEVATE_PAYLOAD);$env:CP_ELEVATE_PAYLOAD=$null;$bootstrapEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrapSource));if($bootstrapEncoded.Length-ge30000){throw'Elevated uninstaller bootstrap exceeds the safe Windows command-line budget.'};$windowStyle=[string]$env:CP_ELEVATE_WINDOW_STYLE;if($windowStyle-notin@('Hidden','Normal')){throw'Invalid elevated uninstaller window style.'};$start=@{FilePath=$env:POWERSHELL_EXE;WorkingDirectory=$env:SystemRoot;ArgumentList=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-EncodedCommand',$bootstrapEncoded);WindowStyle=$windowStyle;PassThru=$true;ErrorAction='Stop'}
::        if($env:CP_ELEVATE_ALREADY_ADMIN_VALUE-ne'1'){$start.Verb='RunAs'}
::        $process=Start-Process @start
::        if(-not$process.WaitForExit(($childTimeout+60)*1000)){try{$process.Kill()}catch{};[void]$process.WaitForExit(5000);exit 124}
::        if(-not$process.WaitForExit(1000)){exit 124}
::        exit [int]$process.ExitCode
::    }catch{if($_.Exception.NativeErrorCode-eq1223-or$_.Exception.Message-match'canceled|cancelled|denied|1223'){exit 1223};[Console]::Error.WriteLine($_.Exception.Message);exit 1}
::}
::$launcherEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($launcher.ToString()));if($launcherEncoded.Length-ge30000){throw'Uninstall elevation launcher exceeds the safe Windows command-line budget.'}
::$environmentLength=1;foreach($entry in Get-ChildItem Env:){$environmentLength+=$entry.Name.Length+1+([string]$entry.Value).Length+1};if($environmentLength-ge30000){throw'Uninstall elevated environment exceeds the safe Windows environment budget.'}
::$helper=Start-Process -FilePath $env:POWERSHELL_EXE -ArgumentList @('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-EncodedCommand',$launcherEncoded) -WorkingDirectory $env:SystemRoot -WindowStyle Hidden -PassThru
::function Stop-HelperTree {
::    if(-not$helper-or$helper.HasExited){return};$members=[Collections.Generic.List[Diagnostics.Process]]::new();foreach($pidValue in [CpSetup.Native.ProcessTree]::Snapshot($helper.Id)){try{$members.Add([Diagnostics.Process]::GetProcessById($pidValue))}catch{}}
::    try{for($i=$members.Count-1;$i-ge0;$i--){try{if(-not$members[$i].HasExited){$members[$i].Kill()}}catch{}};$deadline=[DateTime]::UtcNow.AddSeconds(5);foreach($member in $members){try{if(-not$member.HasExited){$remaining=[Math]::Max(0,[int]($deadline-[DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt0){[void]$member.WaitForExit($remaining)}}}catch{}};if(@($members|Where-Object{try{-not$_.HasExited}catch{$false}}).Count){throw'Elevation-helper process-tree survivors.'}}finally{foreach($member in $members){$member.Dispose()}}
::}
::$esc=[char]27;$cr=[char]13;$clear=$esc+'[2K';$green=$esc+'[38;5;114m';$red=$esc+'[31m';$reset=$esc+'[0m'
::$requestLabel='Requesting administrator rights...';$uninstallLabel='Administrator rights granted, uninstalling...'
::$frames=@([char]92,'-','/','|');$index=0;$clock=[Diagnostics.Stopwatch]::StartNew();$timedOut=$false;$hadElevatedChild=$false
::try{
::    while(-not$helper.HasExited){
::        $started=Test-Path -LiteralPath $startedFile
::        $label=if($started){$uninstallLabel}else{$requestLabel}
::        if(-not$isCheck){Write-Host -NoNewline($cr+$clear+$frames[$index-band 3]+' '+$label);[Console]::Out.Flush()}
::        if((-not$started-and$clock.Elapsed.TotalSeconds-ge$uacTimeout)-or$clock.Elapsed.TotalSeconds-ge($uacTimeout+$childTimeout+120)){$timedOut=$true;try{$stream=[IO.FileStream]::new($cancelFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$bytes=[Text.Encoding]::ASCII.GetBytes($elevationNonce);$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}}catch{};$grace=[DateTime]::UtcNow.AddSeconds(10);while(-not$helper.HasExited-and[DateTime]::UtcNow-lt$grace){Start-Sleep -Milliseconds 100};if(-not$helper.HasExited){Stop-ElevatedTree;Stop-HelperTree};break}
::        Start-Sleep -Milliseconds 100;$index++
::    }
::    if(-not$timedOut-and-not$helper.WaitForExit(1000)){$timedOut=$true;Stop-ElevatedTree;Stop-HelperTree}
::}finally{
::    $hadElevatedChild=Test-Path -LiteralPath $startedFile
::    if($timedOut){Stop-ElevatedTree;Stop-HelperTree}
::    Remove-Item -LiteralPath $startedFile -Force -ErrorAction SilentlyContinue
::    Remove-Item -LiteralPath $cancelFile -Force -ErrorAction SilentlyContinue
::}
::$result=if($timedOut){[pscustomobject]@{Ok=$true;ExitCode=124;Details='Administrator request or elevated uninstaller timed out.'}}else{$code=[int]$helper.ExitCode;if($code-eq1223){[pscustomobject]@{Ok=$false;ExitCode=1;Details='UAC canceled or denied (1223).'}}elseif(-not$hadElevatedChild-and$code-ne0){[pscustomobject]@{Ok=$false;ExitCode=$code;Details='Elevation failed before child start.'}}else{[pscustomobject]@{Ok=$true;ExitCode=$code;Details=''}}}
::$helper.Dispose()
::$transportLease.Dispose();Remove-Item -LiteralPath $transport -Force -ErrorAction SilentlyContinue
::$details=if($result){[string]$result.Details}else{''};$childExit=if($timedOut){124}elseif($result){[int]$result.ExitCode}else{1};$finalExit=$childExit
::$event=if([IO.File]::Exists($transcript)){''}elseif($timedOut){'Elevation timed out.'}elseif($details-match'canceled|cancelled|denied|1223'){'UAC canceled or denied.'}elseif($hadElevatedChild){'Elevated uninstaller did not produce a transcript.'}else{'Elevation failed before child start.'}
::$copyError=$null;$cleanupError=$null;$protocolError=$null;$completionText=$null;$summary=@();$saved=$false
::if($childExit-eq10){try{$completionText=Read-DeferredCompletion (Join-Path $transcriptDir 'completion.txt')}catch{$protocolError=$_.Exception.Message;$finalExit=1}}
::try{Save-AuthoritativeTranscript $(if([IO.File]::Exists($transcript)){$transcript}else{$null}) $destination $childExit $event;$saved=$true}catch{$copyError=$_.Exception.Message;$finalExit=1}
::if([IO.File]::Exists((Join-Path $transcriptDir 'runtime.marker'))){$cleanupError='Protected runtime cleanup is pending; its recovery marker was preserved.';if($finalExit-ne124){$finalExit=1}}else{try{Remove-ProtectedTranscript $transcriptDir}catch{$cleanupError=$_.Exception.Message;if($finalExit-ne124){$finalExit=1}}}
::if($saved){try{Save-AuthoritativeTranscript $destination $destination $finalExit $(if($cleanupError){'Post-child cleanup failed: '+$cleanupError}elseif($protocolError){'Deferred completion failed: '+$protocolError}else{''})}catch{$copyError=$_.Exception.Message;$finalExit=1}}
::if(-not$saved){try{Save-AuthoritativeTranscript $null $destination $finalExit $(if($copyError){'Transcript publication failed: '+$copyError}else{$event});$saved=$true}catch{if(-not$copyError){$copyError=$_.Exception.Message}}}
::if($saved){try{$summary=@(Get-TranscriptSummary $destination)}catch{if(-not$copyError){$copyError=$_.Exception.Message};$finalExit=1;try{Save-AuthoritativeTranscript $destination $destination $finalExit ('Transcript summary failed: '+$_.Exception.Message)}catch{}}}
::if($finalExit-eq10-and-not$copyError-and-not$cleanupError-and-not$protocolError){try{Publish-DeferredCompletion $completionText}catch{$protocolError=$_.Exception.Message;$finalExit=1;try{Save-AuthoritativeTranscript $destination $destination $finalExit ('Deferred completion publication failed: '+$protocolError)}catch{if(-not$copyError){$copyError=$_.Exception.Message}}}}
::if($isCheck){$summary=@()}
::$linePrefix=$cr+$clear
::if($summary.Count){
::    Write-Host -NoNewline $linePrefix
::    $statusColors=@{FOUND=$green;REMOVED=$green;UNINSTALLED=$green;KEPT=($esc+'[38;5;244m');MISSING=($esc+'[33m')}
::    foreach($line in $summary){if($line-match'^\[([A-Z ]+)\](.*)$'){$color=$statusColors[$Matches[1]];if(-not$color){$color=$green};Write-Host('['+$color+$Matches[1]+$reset+']'+$Matches[2])}}
::    $linePrefix=''
::}
::if(-not$result-or-not$result.Ok){
::    $details=if($result){[string]$result.Details}else{''}
::    if($details-match'canceled|cancelled|denied|1223'){Write-Host($linePrefix+$red+'Uninstall canceled by user.'+$reset);exit 1}
::    Write-Host($linePrefix+$red+'Uninstall failed while requesting administrator rights.'+$reset);if($details){Write-Host $details};exit 1
::}
::if($isCheck){exit $finalExit}
::if(($copyError-or$cleanupError-or$protocolError)-and$finalExit-ne124){Write-Host($linePrefix+$red+'Uninstall failed while saving the uninstall transcript.'+$reset);Write-Host $(if($copyError){$copyError}elseif($cleanupError){$cleanupError}else{$protocolError});exit $finalExit}
::if($finalExit-eq10){exit 10}
::if($finalExit-eq0){Write-Host($linePrefix+$green+'Uninstall completed'+$reset);exit 0}
::if($finalExit-eq124){Write-Host($linePrefix+$red+'Uninstall failed: elevated uninstaller timed out.'+$reset);exit 124}
::Write-Host($linePrefix+$red+('Uninstall failed: elevated uninstaller exited with code '+$finalExit)+$reset);exit $finalExit
::__CP_UNINSTALL_ELEVATE_END__

::__CP_UNINSTALL_CHILD_BEGIN__
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Q([string]$value){[char]34+$value.Replace([char]34,[char]34+[char]34)+[char]34}
::function Read-Block([string]$begin,[string]$end){$lines=[IO.File]::ReadAllLines($env:CP_UNINSTALL_SCRIPT);$first=[Array]::IndexOf($lines,'::'+$begin);$last=[Array]::IndexOf($lines,'::'+$end);if($first-lt0-or$last-le$first){throw('Missing source block: '+$begin)};$content=[Collections.Generic.List[string]]::new();for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw'Malformed source block.'};$content.Add($lines[$i].Substring(2))};$content-join[Environment]::NewLine}
::function Stop-ChildTree([Diagnostics.Process]$root){$source=Read-Block '__CP_PROCESS_TREE_NATIVE_BEGIN__' '__CP_PROCESS_TREE_NATIVE_END__';if(-not('CpSetup.Native.ProcessTree'-as[type])){Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop};$members=[Collections.Generic.List[Diagnostics.Process]]::new();foreach($pidValue in [CpSetup.Native.ProcessTree]::Snapshot($root.Id)){try{$members.Add([Diagnostics.Process]::GetProcessById($pidValue))}catch{}};try{for($index=$members.Count-1;$index-ge0;$index--){try{if(-not$members[$index].HasExited){$members[$index].Kill()}}catch{}};$deadline=[DateTime]::UtcNow.AddSeconds(5);foreach($member in $members){try{if(-not$member.HasExited){$remaining=[Math]::Max(0,[int]($deadline-[DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt0){[void]$member.WaitForExit($remaining)}}}catch{}};$survivors=@($members|Where-Object{try{-not$_.HasExited}catch{$false}});if($survivors.Count){throw('Elevated child process-tree survivors: '+(($survivors.Id|Sort-Object)-join', '))}}finally{foreach($member in $members){$member.Dispose()}}}
::try{
::    $identity=[Security.Principal.WindowsIdentity]::GetCurrent();$principal=[Security.Principal.WindowsPrincipal]::new($identity)
::    if(-not$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw'Elevated runner has no administrator token.'}
::    [int]$timeoutSeconds=0;if(-not[int]::TryParse($env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS,[ref]$timeoutSeconds)-or$timeoutSeconds-lt 1){$timeoutSeconds=7200}
::    $system32=[Environment]::SystemDirectory;$cmd=[IO.Path]::GetFullPath($env:CMD_EXE)
::    if($cmd-ine[IO.Path]::Combine($system32,'cmd.exe')){throw'Untrusted cmd.exe path.'}
::    $transport=[IO.Path]::GetFullPath($env:CP_SOURCE_TRANSPORT_PATH);$transportParent=[IO.Path]::GetFullPath($env:CP_VISIBLE_TEMP).TrimEnd([char]92);if([IO.Path]::GetDirectoryName($transport)-ine$transportParent-or[IO.Path]::GetFileName($transport)-notmatch'^cp_setup_uninstall_source_[0-9]+_[0-9]+\.transport$'-or-not[IO.File]::Exists($transport)){throw'Protected source transport is missing.'}
::    if($env:CP_SOURCE_GUARD_B64-notmatch'^[A-Za-z0-9+/]+={0,2}$'){throw'Protected source-guard payload is missing.'};$sourceGuard=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:CP_SOURCE_GUARD_B64));if(-not('CpSetup.Native.SourceLease'-as[type])){Add-Type -TypeDefinition $sourceGuard -Language CSharp -ErrorAction Stop};$sourceLease=[CpSetup.Native.SourceLease]::Acquire($transport);if($env:CP_UNINSTALL_SOURCE_SHA256-notmatch'^[0-9a-f]{64}$'-or$sourceLease.Hash-cne$env:CP_UNINSTALL_SOURCE_SHA256){throw'Uninstaller source transport changed across elevation.'}
::    $tokens=@($env:CP_UNINSTALL_ARGS-split'\s+'|Where-Object{$_});$allowed=@('--all','--non-interactive','--no-pause','--check')
::    if(@($tokens|Where-Object{$allowed-notcontains$_}).Count){throw'Unsafe elevated uninstaller arguments.'}
::    $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)
::    $dir=[IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR).TrimEnd([char]92)
::    if(-not$dir.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($dir)-notmatch'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'-or[IO.Directory]::Exists($dir)){throw'Unsafe transcript directory.'}
::    $baseItem=Get-Item -LiteralPath $base -Force -ErrorAction Stop
::    if(-not$baseItem.PSIsContainer-or($baseItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw'Unsafe Windows Temp root.'}
::    $acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'));$acl.SetAccessRuleProtection($true,$false)
::    $inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit
::    foreach($sid in @('S-1-5-18','S-1-5-32-544')){$rule=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid),[Security.AccessControl.FileSystemRights]::Modify,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow);[void]$acl.AddAccessRule($rule)}
::    $target=[Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID);$targetRights=[Security.AccessControl.FileSystemRights]::ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete
::    [void]$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($target,$targetRights,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow))
::    $created=[IO.Directory]::CreateDirectory($dir,$acl);if($created.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Transcript directory is a reparse point.'}
::    $started=Join-Path $dir 'started.marker';$startedStream=[IO.FileStream]::new($started,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$bytes=[Text.Encoding]::ASCII.GetBytes($env:CP_ELEVATE_NONCE+'|'+$PID+'|'+([Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().Ticks));$startedStream.Write($bytes,0,$bytes.Length);$startedStream.Flush($true)}finally{$startedStream.Dispose()}
::    $env:CP_ELEVATED_WRAPPER_PID=[string]$PID;$env:CP_ELEVATED_WRAPPER_START_TICKS=[string][Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().Ticks
::    $script=Join-Path $dir 'uninstall.bat';$protectedLease=$sourceLease.CopyTo($script);if($protectedLease.Hash-cne$sourceLease.Hash){throw'Protected uninstaller copy verification failed.'};$env:CP_UNINSTALL_SCRIPT=$script
::    $treeSource=Read-Block '__CP_PROCESS_TREE_NATIVE_BEGIN__' '__CP_PROCESS_TREE_NATIVE_END__';if(-not('CpSetup.Native.ProcessTree'-as[type])){Add-Type -TypeDefinition $treeSource -Language CSharp -ErrorAction Stop}
::    function Remove-OrphanTree([string]$path,[string]$boundary){$full=[IO.Path]::GetFullPath($path).TrimEnd([char]92);if($full-ine$boundary-and-not$full.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe orphan cleanup path.'};if(-not(Test-Path -LiteralPath $full)){return};$item=Get-Item -LiteralPath $full -Force;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Orphan cleanup encountered a reparse point.'};if($item.PSIsContainer){foreach($child in @($item.GetFileSystemInfos())){Remove-OrphanTree $child.FullName $full}}else{$item.Attributes=[IO.FileAttributes]::Normal};$item.Delete()}
::    function Test-WrapperActive([int]$processId,[long]$ticks){try{$process=[Diagnostics.Process]::GetProcessById($processId);try{return ($process.StartTime.ToUniversalTime().Ticks -eq $ticks -and [IO.Path]::GetFullPath([CpSetup.Native.ProcessTree]::ImagePath($processId)) -ieq [IO.Path]::GetFullPath($env:POWERSHELL_EXE))}finally{$process.Dispose()}}catch{return $false}}
::    foreach($orphan in @([IO.Directory]::EnumerateDirectories($base,'cp-setup-uninstall-transcript-*',[IO.SearchOption]::TopDirectoryOnly))){$full=[IO.Path]::GetFullPath($orphan).TrimEnd([char]92);if($full-ieq$dir-or[IO.Path]::GetFileName($full)-notmatch'^cp-setup-uninstall-transcript-[0-9a-f]{32}$'){continue};$item=Get-Item -LiteralPath $full -Force;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Orphan transcript is a reparse point.'};$orphanAcl=$item.GetAccessControl();try{$owner=([Security.Principal.NTAccount]$orphanAcl.Owner).Translate([Security.Principal.SecurityIdentifier]).Value}catch{$owner=$orphanAcl.Owner};if($owner-notin@('S-1-5-18','S-1-5-32-544')-or-not$orphanAcl.AreAccessRulesProtected){continue};$startedPath=Join-Path $full 'started.marker';if(-not[IO.File]::Exists($startedPath)){continue};$startParts=([IO.File]::ReadAllText($startedPath,[Text.Encoding]::ASCII).Trim()).Split([char]'|');[int]$orphanPid=0;[long]$orphanTicks=0;if($startParts.Count-ne3-or$startParts[0]-notmatch'^[0-9a-f]{32}$'-or-not[int]::TryParse($startParts[1],[ref]$orphanPid)-or-not[long]::TryParse($startParts[2],[ref]$orphanTicks)){throw'Invalid orphan wrapper marker.'};if(Test-WrapperActive $orphanPid $orphanTicks){continue};$runtimeMarker=Join-Path $full 'runtime.marker';if([IO.File]::Exists($runtimeMarker)){$runtimeParts=([IO.File]::ReadAllText($runtimeMarker,[Text.Encoding]::Default).Trim()).Split([char]'|');[int]$runtimePid=0;[long]$runtimeTicks=0;if($runtimeParts.Count-ne4-or$runtimeParts[0]-cne$startParts[0]-or-not[int]::TryParse($runtimeParts[2],[ref]$runtimePid)-or$runtimePid-ne$orphanPid-or-not[long]::TryParse($runtimeParts[3],[ref]$runtimeTicks)-or$runtimeTicks-ne$orphanTicks){throw'Invalid orphan runtime marker.'};$runtimeBase=[IO.Path]::GetFullPath((Join-Path([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData))'my-cp-setup-runtime')).TrimEnd([char]92);$runtime=[IO.Path]::GetFullPath($runtimeParts[1]).TrimEnd([char]92);if(-not$runtime.StartsWith($runtimeBase+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($runtime)-notmatch'^[0-9a-f]{32}$'){throw'Unsafe orphan runtime path.'};Remove-OrphanTree $runtime $runtime};Remove-OrphanTree $full $full}
::    function Remove-ForcedRuntime{
::        $marker=Join-Path $dir 'runtime.marker';if(-not[IO.File]::Exists($marker)){return};$parts=([IO.File]::ReadAllText($marker,[Text.Encoding]::Default).Trim()).Split([char]'|');[int]$wrapperPid=0;[long]$wrapperTicks=0;if($parts.Count-ne4-or$parts[0]-cne$env:CP_RUNTIME_OPERATION_ID-or$parts[0]-notmatch'^[0-9a-f]{32}$'-or-not[int]::TryParse($parts[2],[ref]$wrapperPid)-or$wrapperPid-ne$PID-or-not[long]::TryParse($parts[3],[ref]$wrapperTicks)-or$wrapperTicks-ne[Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().Ticks){throw'Invalid protected-runtime marker.'};$base=[IO.Path]::GetFullPath((Join-Path([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData))'my-cp-setup-runtime')).TrimEnd([char]92);$runtime=[IO.Path]::GetFullPath($parts[1]).TrimEnd([char]92);if(-not$runtime.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($runtime)-notmatch'^[0-9a-f]{32}$'){throw'Unsafe forced runtime cleanup path.'};function Remove-NoFollow([string]$path,[string]$boundary){$full=[IO.Path]::GetFullPath($path).TrimEnd([char]92);if($full-ine$boundary-and-not$full.StartsWith($boundary+[char]92,[StringComparison]::OrdinalIgnoreCase)){throw'Unsafe forced runtime child.'};if(-not(Test-Path -LiteralPath $full)){return};$item=Get-Item -LiteralPath $full -Force;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw'Reparse point in forced runtime cleanup.'};if($item.PSIsContainer){foreach($child in @($item.GetFileSystemInfos())){Remove-NoFollow $child.FullName $full}}else{$item.Attributes=[IO.FileAttributes]::Normal};$item.Delete()};Remove-NoFollow $runtime $runtime;if(Test-Path -LiteralPath $runtime){throw'Forced runtime cleanup failed.'};Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
::    }
::    $transcript=Join-Path $dir 'uninstall.log';$wrapper=Join-Path $dir 'run.cmd'
::    ('[CP-SETUP] START timestamp='+[DateTimeOffset]::Now.ToString('o')+' runnerPid='+$PID+' targetSid='+$env:CP_SETUP_TARGET_SID+' elevatedSid='+$identity.User.Value+' token=administrator')|Set-Content -LiteralPath $transcript -Encoding Default
::    $runLine='call '+(Q $script);if($tokens.Count){$runLine+=' '+($tokens-join' ')};$runLine+=' 1^>^>'+(Q $transcript)+' 2^>^&1'
::    [IO.File]::WriteAllLines($wrapper,@('@echo off','setlocal DisableDelayedExpansion',$runLine,'exit /b %ERRORLEVEL%'),[Text.Encoding]::ASCII)
::    $arguments='/d /s /c ""'+$wrapper+'""';$process=Start-Process -FilePath $cmd -ArgumentList $arguments -WorkingDirectory $system32 -NoNewWindow -PassThru
::    ('[CP-SETUP] CHILD pid='+$process.Id)|Add-Content -LiteralPath $transcript -Encoding Default
::    $shown=0
::    function Flush-Transcript{try{$text=Get-Content -LiteralPath $transcript -Raw -Encoding Default -ErrorAction Stop;if($text.Length-gt$shown){[Console]::Write($text.Substring($shown));$script:shown=$text.Length}}catch{}}
::    $clock=[Diagnostics.Stopwatch]::StartNew();$timedOut=$false
::    while(-not$process.HasExited){Flush-Transcript;$cancel=$false;if($env:CP_ELEVATE_CANCEL_FILE-and[IO.File]::Exists($env:CP_ELEVATE_CANCEL_FILE)){try{$cancel=([IO.File]::ReadAllText($env:CP_ELEVATE_CANCEL_FILE,[Text.Encoding]::ASCII).Trim()-ceq$env:CP_ELEVATE_NONCE)}catch{}};if($cancel-or$clock.Elapsed.TotalSeconds-ge$timeoutSeconds){$timedOut=$true;Stop-ChildTree $process;break};Start-Sleep -Milliseconds 100}
::    if($timedOut){Remove-ForcedRuntime;$exitCode=124}elseif(-not$process.WaitForExit(1000)){$exitCode=124;Stop-ChildTree $process;Remove-ForcedRuntime}else{$exitCode=[int]$process.ExitCode}
::    ('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit='+$exitCode)|Add-Content -LiteralPath $transcript -Encoding Default
::    Flush-Transcript;exit $exitCode
::}catch{[Console]::Error.WriteLine('Elevated runner failed: '+$_.Exception.Message);exit 1}
::__CP_UNINSTALL_CHILD_END__
