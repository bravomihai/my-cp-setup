@echo off
if defined CP_SETUP_ENTRY_ACTIVE goto cp_setup_entry_active
set "CP_SETUP_ENTRY_ACTIVE=1"
call "%~f0" %*
set "CP_SETUP_ENTRY_EXIT=%ERRORLEVEL%"
set "CP_SETUP_ENTRY_ACTIVE="
exit /b %CP_SETUP_ENTRY_EXIT%

:cp_setup_entry_active
setlocal EnableExtensions DisableDelayedExpansion

set "__APPDIR__="
set "SYSTEM32_DIR=%__APPDIR__%"
for %%I in ("%SYSTEM32_DIR%.") do set "SYSTEM32_LEAF=%%~nxI"
if /i not "%SYSTEM32_LEAF%"=="System32" if /i not "%SYSTEM32_LEAF%"=="SysWOW64" exit /b 1
for %%I in ("%SYSTEM32_DIR%..") do set "WINDOWS_DIR=%%~fI"
for %%I in ("%WINDOWS_DIR%") do set "WINDOWS_LEAF=%%~nxI"
if /i not "%WINDOWS_LEAF%"=="Windows" exit /b 1
if /i "%SYSTEM32_LEAF%"=="SysWOW64" goto cp_setup_native_reexec
if /i not "%SYSTEM32_LEAF%"=="System32" exit /b 1
goto cp_setup_native_ready

:cp_setup_native_reexec
if "%CP_SETUP_NATIVE_REEXEC%"=="1" exit /b 1
for %%I in ("%WINDOWS_DIR%\Sysnative\cmd.exe") do set "NATIVE_CMD=%%~fI"
if not exist "%NATIVE_CMD%" exit /b 1
set "CP_SETUP_NATIVE_REEXEC=1"
"%NATIVE_CMD%" /d /s /c ""%~f0" %*"
exit /b %ERRORLEVEL%

:cp_setup_native_ready
set "SystemRoot=%WINDOWS_DIR%"
set "windir=%WINDOWS_DIR%"
set "POWERSHELL_EXE=%SYSTEM32_DIR%WindowsPowerShell\v1.0\powershell.exe"
set "CMD_EXE=%SYSTEM32_DIR%cmd.exe"
set "ComSpec=%CMD_EXE%"
set "WHERE_EXE=%SYSTEM32_DIR%where.exe"
set "TASKKILL_EXE=%SYSTEM32_DIR%taskkill.exe"
set "ICACLS_EXE=%SYSTEM32_DIR%icacls.exe"
set "REG_EXE=%SYSTEM32_DIR%reg.exe"
set "FINDSTR_EXE=%SYSTEM32_DIR%findstr.exe"
if not exist "%CMD_EXE%" exit /b 1
if not exist "%POWERSHELL_EXE%" exit /b 1
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%SYSTEM32_DIR%;%WINDOWS_DIR%;%SYSTEM32_DIR%Wbem;%SYSTEM32_DIR%WindowsPowerShell\v1.0"
set "PSModulePath=%SYSTEM32_DIR%WindowsPowerShell\v1.0\Modules"
set "__COMPAT_LAYER="
for %%V in (COR_ENABLE_PROFILING COR_PROFILER COR_PROFILER_PATH COR_PROFILER_PATH_32 COR_PROFILER_PATH_64 CORECLR_ENABLE_PROFILING CORECLR_PROFILER CORECLR_PROFILER_PATH CORECLR_PROFILER_PATH_32 CORECLR_PROFILER_PATH_64 DOTNET_STARTUP_HOOKS DOTNET_ADDITIONAL_DEPS DOTNET_SHARED_STORE DOTNET_ROOT COMPLUS_InstallRoot COMPLUS_Version BASH_ENV ENV SHELLOPTS BASHOPTS PYTHONHOME PYTHONPATH NODE_OPTIONS NODE_PATH JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS JDK_JAVAC_OPTIONS _JAVA_OPTIONS CLASSPATH GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT RUBYOPT PERL5OPT) do set "%%V="
set "DOTNET_ROOT(x86)="
set "ESC="
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
if "%CP_SETUP_ELEVATED_CHILD%"=="1" if defined CP_SETUP_ORIGINAL_ROOT for %%I in ("%CP_SETUP_ORIGINAL_ROOT%") do set "ROOT=%%~fI"
set "INSTALL_SCRIPT=%~f0"
set "ORIGINAL_ARGS=%*"
pushd "%SYSTEM32_DIR%" >nul 2>nul
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$o=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames; $lm=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default); $key=$lm.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion'); $registered=[IO.Path]::GetFullPath([string]$key.GetValue('SystemRoot',$null,$o)).TrimEnd([char]92); $actual=[IO.Path]::GetFullPath([Environment]::SystemDirectory).TrimEnd([char]92); $expected=[IO.Path]::GetFullPath($env:SYSTEM32_DIR).TrimEnd([char]92); $key.Dispose(); $lm.Dispose(); if($actual -ine $expected -or [IO.Directory]::GetParent($actual).FullName.TrimEnd([char]92) -ine $registered){exit 1}; exit 0" >nul 2>nul
if errorlevel 1 exit /b 1
call :enable_console_ansi

set "CHECK_ONLY=0"
set "VERBOSE=0"
set "NON_INTERACTIVE=0"
set "NO_PAUSE=0"
set "INSTALL_LOG_REQUESTED="
set "CP_ELEVATE_ALREADY_ADMIN="
set "ELEVATION_HANDLED="
set "ELEVATED_CHILD_EXIT="
set "ELEVATED_INSTALL_ARGS="
set "UAC_TIMEOUT_SECONDS=300"
set "INSTALL_CHILD_TIMEOUT_SECONDS=7200"
set "MISSING_COUNT=0"
set "TOOLCHAIN_INSTALLED=0"
set "STATE_SCHEMA=5"
set "ACL_COMMIT=864245a00b00dd008d1abfdc239618fdb7d139da"
set "ACL_TREE_HASH=354f77a3274dcf906fa5a79d8beaba6a9c497b5435180cd0e7d41b613b7fb9d3"
set "MASON_TOOLS=pyright jdtls google-java-format clangd"
set "MASON_CANDIDATE_CLOSURE=clangd google-java-format jdtls pyright tree-sitter-cli"
set "CP_PROCESS_TREE_NATIVE_BASE64=dXNpbmcgU3lzdGVtOwp1c2luZyBTeXN0ZW0uQ29sbGVjdGlvbnMuR2VuZXJpYzsKdXNpbmcgU3lzdGVtLkNvbXBvbmVudE1vZGVsOwp1c2luZyBTeXN0ZW0uUnVudGltZS5JbnRlcm9wU2VydmljZXM7CnB1YmxpYyBzdGF0aWMgY2xhc3MgQ3BTZXR1cFByb2Nlc3NUcmVlIHsKIGNvbnN0IHVpbnQgU25hcHNob3RQcm9jZXNzZXM9MjsKIHN0YXRpYyByZWFkb25seSBJbnRQdHIgSW52YWxpZEhhbmRsZT1uZXcgSW50UHRyKC0xKTsKIFtTdHJ1Y3RMYXlvdXQoTGF5b3V0S2luZC5TZXF1ZW50aWFsLENoYXJTZXQ9Q2hhclNldC5Vbmljb2RlKV0KIHN0cnVjdCBFbnRyeSB7CiAgcHVibGljIHVpbnQgU2l6ZSxVc2FnZSxQcm9jZXNzSWQ7CiAgcHVibGljIFVJbnRQdHIgRGVmYXVsdEhlYXBJZDsKICBwdWJsaWMgdWludCBNb2R1bGVJZCxUaHJlYWRzLFBhcmVudFByb2Nlc3NJZDsKICBwdWJsaWMgaW50IEJhc2VQcmlvcml0eTsKICBwdWJsaWMgdWludCBGbGFnczsKICBbTWFyc2hhbEFzKFVubWFuYWdlZFR5cGUuQnlWYWxUU3RyLFNpemVDb25zdD0yNjApXSBwdWJsaWMgc3RyaW5nIEV4ZUZpbGU7CiB9CiBbRGxsSW1wb3J0KCJrZXJuZWwzMi5kbGwiLFNldExhc3RFcnJvcj10cnVlKV0gc3RhdGljIGV4dGVybiBJbnRQdHIgQ3JlYXRlVG9vbGhlbHAzMlNuYXBzaG90KHVpbnQgZmxhZ3MsdWludCBwcm9jZXNzSWQpOwogW0RsbEltcG9ydCgia2VybmVsMzIuZGxsIixDaGFyU2V0PUNoYXJTZXQuVW5pY29kZSxTZXRMYXN0RXJyb3I9dHJ1ZSldIHN0YXRpYyBleHRlcm4gYm9vbCBQcm9jZXNzMzJGaXJzdFcoSW50UHRyIHNuYXBzaG90LHJlZiBFbnRyeSBlbnRyeSk7CiBbRGxsSW1wb3J0KCJrZXJuZWwzMi5kbGwiLENoYXJTZXQ9Q2hhclNldC5Vbmljb2RlLFNldExhc3RFcnJvcj10cnVlKV0gc3RhdGljIGV4dGVybiBib29sIFByb2Nlc3MzMk5leHRXKEludFB0ciBzbmFwc2hvdCxyZWYgRW50cnkgZW50cnkpOwogW0RsbEltcG9ydCgia2VybmVsMzIuZGxsIildIHN0YXRpYyBleHRlcm4gYm9vbCBDbG9zZUhhbmRsZShJbnRQdHIgaGFuZGxlKTsKIHB1YmxpYyBzdGF0aWMgaW50W10gU25hcHNob3QoaW50IHJvb3QpIHsKICBJbnRQdHIgc25hcHNob3Q9Q3JlYXRlVG9vbGhlbHAzMlNuYXBzaG90KFNuYXBzaG90UHJvY2Vzc2VzLDApOwogIGlmKHNuYXBzaG90PT1JbnZhbGlkSGFuZGxlKXRocm93IG5ldyBXaW4zMkV4Y2VwdGlvbihNYXJzaGFsLkdldExhc3RXaW4zMkVycm9yKCksIkNyZWF0ZVRvb2xoZWxwMzJTbmFwc2hvdCIpOwogIHRyeSB7CiAgIHZhciBjaGlsZHJlbj1uZXcgRGljdGlvbmFyeTxpbnQsTGlzdDxpbnQ+PigpOwogICBFbnRyeSBlbnRyeT1uZXcgRW50cnkoKTtlbnRyeS5TaXplPSh1aW50KU1hcnNoYWwuU2l6ZU9mKHR5cGVvZihFbnRyeSkpOwogICBpZihQcm9jZXNzMzJGaXJzdFcoc25hcHNob3QscmVmIGVudHJ5KSlkb3sKICAgIGludCBwYXJlbnQ9dW5jaGVja2VkKChpbnQpZW50cnkuUGFyZW50UHJvY2Vzc0lkKTsKICAgIExpc3Q8aW50PiBsaXN0O2lmKCFjaGlsZHJlbi5UcnlHZXRWYWx1ZShwYXJlbnQsb3V0IGxpc3QpKXtsaXN0PW5ldyBMaXN0PGludD4oKTtjaGlsZHJlbi5BZGQocGFyZW50LGxpc3QpO30KICAgIGxpc3QuQWRkKHVuY2hlY2tlZCgoaW50KWVudHJ5LlByb2Nlc3NJZCkpOwogICAgZW50cnkuU2l6ZT0odWludClNYXJzaGFsLlNpemVPZih0eXBlb2YoRW50cnkpKTsKICAgfXdoaWxlKFByb2Nlc3MzMk5leHRXKHNuYXBzaG90LHJlZiBlbnRyeSkpOwogICB2YXIgcmVzdWx0PW5ldyBMaXN0PGludD4oKTt2YXIgcXVldWU9bmV3IFF1ZXVlPGludD4oKTt2YXIgc2Vlbj1uZXcgSGFzaFNldDxpbnQ+KCk7cXVldWUuRW5xdWV1ZShyb290KTsKICAgd2hpbGUocXVldWUuQ291bnQhPTApe2ludCBjdXJyZW50PXF1ZXVlLkRlcXVldWUoKTtpZighc2Vlbi5BZGQoY3VycmVudCkpY29udGludWU7cmVzdWx0LkFkZChjdXJyZW50KTtMaXN0PGludD4gbGlzdDtpZihjaGlsZHJlbi5UcnlHZXRWYWx1ZShjdXJyZW50LG91dCBsaXN0KSlmb3JlYWNoKGludCBjaGlsZCBpbiBsaXN0KXF1ZXVlLkVucXVldWUoY2hpbGQpO30KICAgcmV0dXJuIHJlc3VsdC5Ub0FycmF5KCk7CiAgfSBmaW5hbGx5IHsgQ2xvc2VIYW5kbGUoc25hcHNob3QpOyB9CiB9Cn0="
set "PACMAN_PACKAGES_ALLOWED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python mingw-w64-x86_64-ruff"
set "WINGET_ARGS=--exact --source winget --scope machine --accept-package-agreements --accept-source-agreements --disable-interactivity"
set "WINGET_QUIET_ARGS=%WINGET_ARGS% --silent"
set "CP_MASON_BOOTSTRAP="
set "PACMAN_DEFER_SUCCESS="
set "PACMAN_LABEL="
set "PACMAN_HINT="
set "SPIN_DEFER_SUCCESS="
set "SPIN_PROGRESS_FILE="
set "SPIN_TIMEOUT_SECONDS="
set "SPIN_MEDIUM_WORKER="
set "MEDIUM_LAUNCHER_PS="
set "MEDIUM_NATIVE_CS="
set "MEDIUM_REGISTRY_PLAN_PS="
set "MEDIUM_WORKER_PS="
set "ARTIFACT_SNAPSHOT_FILE="
set "ARTIFACT_OPERATION_FILE="
set "ARTIFACT_OPERATION_TIME_FILE="
set "PROCESS_TREE_PS="
set "CP_SETUP_TIMEOUT_OCCURRED=0"
set "STATE_ROOT_CLAIMED=0"
set "CP_SETUP_PRIVILEGED="
set "CP_GPP="
set "CP_PYTHON="
set "CP_JAVAC="
set "CP_JAVA="
set "FOUND_GIT_PATH="
set "FOUND_NODE_PATH="
set "FOUND_NPM_PATH="
set "FOUND_NVIM_PATH="
set "FOUND_JAVAC_PATH="
set "FOUND_JAVA_PATH="
set "FOUND_RUFF_PATH="
set "VISIBLE_TEMP=%TEMP%"
set "EXEC_TEMP=%VISIBLE_TEMP%"
set "SECURE_TEMP_ACTIVE=0"
set "EARLY_ELEVATED=0"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); if (([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1" >nul 2>nul
if not errorlevel 1 set "EARLY_ELEVATED=1"
if "%EARLY_ELEVATED%"=="1" if "%CP_SETUP_ELEVATED_CHILD%"=="1" (
    set "CP_SETUP_PRIVILEGED=1"
    call :prepare_secure_temp
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Could not create a protected installer workspace.
        exit /b 1
    )
    call :sanitize_privileged_environment
    if errorlevel 1 (
        call :cleanup_secure_temp
        echo [%ESC%[31mFAILED%ESC%[0m] Could not create a protected installer environment.
        exit /b 1
    )
)
set "EARLY_ELEVATED="
if /i "%~1"=="--internal-ac-library-status" if /i not "%~2"=="manage" goto internal_ac_library_status
set "RESOLVE_TARGET_FULL=1"
call :initialize_target_user
set "RESOLVE_TARGET_FULL="
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not resolve the invoking user's Windows profile and registry hive.
    call :cleanup_secure_temp
    exit /b 1
)
set "TARGET_HIVE=HKU\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_REGISTRY=Registry::HKEY_USERS\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_ENV=%CP_SETUP_TARGET_REGISTRY%\Environment"
set "STATE_KEY=HKLM\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_TARGET_STATE=Registry::HKEY_LOCAL_MACHINE\Software\my-cp-setup\Users\%CP_SETUP_TARGET_SID%"
set "CP_SETUP_MACHINE_STATE=%CP_SETUP_TARGET_STATE%"
if /i "%~1"=="--internal-ac-library-status" goto internal_ac_library_status

call :validate_setup_root
if errorlevel 1 (
    call :cleanup_secure_temp
    exit /b 1
)
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
if /i "%~1"=="--non-interactive" (
    set "NON_INTERACTIVE=1"
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
        call :cleanup_secure_temp
        exit /b 1
    )
    set "INSTALL_LOG_REQUESTED=%~2"
    shift
    shift
    goto parse_args
)
echo [%ESC%[31mFAILED%ESC%[0m] Unknown argument: %~1
call :cleanup_secure_temp
exit /b 1

:parsed_args

set "ELEVATED_INSTALL_ARGS="
if "%VERBOSE%"=="1" set "ELEVATED_INSTALL_ARGS=--verbose"
if "%NON_INTERACTIVE%"=="1" set "ELEVATED_INSTALL_ARGS=%ELEVATED_INSTALL_ARGS% --non-interactive"
if "%NO_PAUSE%"=="1" set "ELEVATED_INSTALL_ARGS=%ELEVATED_INSTALL_ARGS% --no-pause"
for /F "tokens=*" %%A in ("%ELEVATED_INSTALL_ARGS%") do set "ELEVATED_INSTALL_ARGS=%%A"

if "%CHECK_ONLY%"=="1" if "%TARGET_USER_DEFERRED%"=="1" (
    set "RESOLVE_TARGET_FULL=1"
    call :initialize_target_user
    set "RESOLVE_TARGET_FULL="
    set "TARGET_USER_DEFERRED="
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Could not resolve the invoking user's Windows profile and registry hive.
        call :cleanup_secure_temp
        exit /b 1
    )
)

if "%CHECK_ONLY%"=="0" (
    call :ensure_admin
    set "ENSURE_ADMIN_EXIT=!ERRORLEVEL!"
    if defined ELEVATION_HANDLED (
        set "HANDLED_INSTALL_EXIT=!ELEVATED_CHILD_EXIT!"
        call :cleanup_secure_temp
        if errorlevel 1 if "!HANDLED_INSTALL_EXIT!"=="0" set "HANDLED_INSTALL_EXIT=1"
        exit /b !HANDLED_INSTALL_EXIT!
    )
    if not "!ENSURE_ADMIN_EXIT!"=="0" (
        call :cleanup_secure_temp
        exit /b !ENSURE_ADMIN_EXIT!
    )
    set "CP_SETUP_PRIVILEGED=1"
    call :prepare_secure_temp
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Could not create a protected installer workspace.
        exit /b 1
    )
    call :sanitize_privileged_environment
    if errorlevel 1 (
        call :cleanup_secure_temp
        echo [%ESC%[31mFAILED%ESC%[0m] Could not create a protected installer environment.
        exit /b 1
    )
    call :initialize_state
    if errorlevel 1 goto failed
    call :claim_state_root
    if errorlevel 1 goto failed
    call :recover_pending_operations
    if errorlevel 1 goto failed
    call :capture_target_profile_artifacts operation
    if errorlevel 1 goto failed
) else (
    call :check_state_root
    if errorlevel 1 (
        call :cleanup_secure_temp
        exit /b 1
    )
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

if "%CHECK_ONLY%"=="0" (
    call :validate_existing_msys2_tree
    if errorlevel 1 goto failed
)

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
    call :prepare_config_mutation
    if errorlevel 1 goto failed
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

if "%CHECK_ONLY%"=="1" (
    echo Checking Neovim...
    call :check_mason_tools
) else (
    echo Configuring Neovim...
)

if "%CHECK_ONLY%"=="1" if not "%MISSING_COUNT%"=="0" goto check_missing

if "%CHECK_ONLY%"=="0" (
    call :commit_pending_acl_archive_hash
    if errorlevel 1 goto failed
    call :write_target_environment
    if errorlevel 1 goto failed

    set "XDG_CONFIG_HOME=%ROOT%"
    set "CP_SETUP_ROOT=%ROOT%"
    call :install_cmd_macros
    if errorlevel 1 goto failed
    call :record_component "Config.Managed"
    if errorlevel 1 goto failed
    call :prepare_nvim_bootstrap
    if errorlevel 1 goto failed
    call :repair_target_profile_artifacts
    if errorlevel 1 goto failed
    call :capture_target_profile_artifacts operation
    if errorlevel 1 goto failed
    call :bootstrap_nvim_tools
    if errorlevel 1 goto failed
)

echo.
echo Verifying setup...
call :verify
if errorlevel 1 goto failed
if "%CHECK_ONLY%"=="0" (
    call :repair_target_profile_artifacts
    if errorlevel 1 goto failed
)

call :cleanup_secure_temp
if errorlevel 1 goto failed
echo.
echo [%ESC%[32mDONE%ESC%[0m] CP setup is ready.
echo Restart terminals so updated User PATH and XDG_CONFIG_HOME are visible everywhere.
exit /b 0

:check_missing
echo.
echo [%ESC%[33mMISSING%ESC%[0m] Some components are not available.
echo Run scripts\install.bat without --check to install missing components.
call :cleanup_secure_temp
exit /b 1

:prepare_secure_temp
if "%SECURE_TEMP_ACTIVE%"=="1" exit /b 0
set "SECURE_TEMP_PATH="
if defined CP_RUNTIME_OPERATION_ID if defined CP_ELEVATE_TRANSCRIPT_DIR goto prepare_recoverable_secure_temp
set "SECURE_TEMP_OUTPUT=%SystemRoot%\Temp\cp_setup_secure_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $id=[Security.Principal.WindowsIdentity]::GetCurrent(); if (-not ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }; $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92); $baseItem=Get-Item -LiteralPath $base -Force -ErrorAction Stop; if (-not $baseItem.PSIsContainer -or ($baseItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 1 }; $sids=@('S-1-5-18','S-1-5-32-544'); function New-Security { $acl=[Security.AccessControl.DirectorySecurity]::new(); $acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')); $acl.SetAccessRuleProtection($true,$false); $inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit; foreach($sid in $sids){$rule=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid),[Security.AccessControl.FileSystemRights]::Modify,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow);$null=$acl.AddAccessRule($rule)};$acl }; function Test-Security($item){$actual=$item.GetAccessControl();if(-not $actual.AreAccessRulesProtected -or $actual.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne 'S-1-5-32-544'){return $false};$rules=@($actual.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]));if($rules.Count -ne 2){return $false};$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit;foreach($rule in $rules){if($rule.IsInherited -or $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or $sids -notcontains $rule.IdentityReference.Value -or $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::Modify -or $rule.InheritanceFlags -ne $inherit -or $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None){return $false}};return $true}; for($attempt=0;$attempt -lt 10;$attempt++){ $path=Join-Path $base ('cp-setup-'+[guid]::NewGuid().ToString('N')); if(Test-Path -LiteralPath $path){continue}; $item=[IO.Directory]::CreateDirectory($path,(New-Security)); if([IO.Path]::GetFullPath($item.FullName) -ine [IO.Path]::GetFullPath($path) -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or @($item.EnumerateFileSystemInfos()).Count -ne 0 -or -not (Test-Security $item)){exit 1};[IO.File]::WriteAllText($env:SECURE_TEMP_OUTPUT,[IO.Path]::GetFullPath($item.FullName),[Text.Encoding]::ASCII);exit 0};exit 1" >nul 2>nul
if errorlevel 1 exit /b 1
goto secure_temp_created

:prepare_recoverable_secure_temp
set "SECURE_TEMP_OUTPUT=%CP_ELEVATE_TRANSCRIPT_DIR%\runtime.path"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$nonce=$env:CP_RUNTIME_OPERATION_ID;if($nonce-notmatch'^[0-9a-f]{32}$'){exit 1};$sid=([Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)).Value;$transcript=[IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR).TrimEnd([char]92);$base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92);if(-not$transcript.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($transcript)-notmatch'^cp-setup-transcript-[0-9a-f]{32}$'){exit 1};$item=Get-Item -LiteralPath $transcript -Force -ErrorAction Stop;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){exit 1};$path=Join-Path $base ('cp-setup-'+$nonce);$marker=Join-Path $transcript 'runtime.marker';$output=[IO.Path]::GetFullPath($env:SECURE_TEMP_OUTPUT);if($output-ine(Join-Path $transcript 'runtime.path')-or(Test-Path -LiteralPath $marker)-or(Test-Path -LiteralPath $output)-or(Test-Path -LiteralPath $path)){exit 1};$markerStream=[IO.FileStream]::new($marker,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$bytes=[Text.Encoding]::ASCII.GetBytes('v1|'+$nonce+'|prepared|'+$path);$markerStream.Write($bytes,0,$bytes.Length);$markerStream.Flush($true)}finally{$markerStream.Dispose()};$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'));$acl.SetAccessRuleProtection($true,$false);$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit;foreach($entry in @(@('S-1-5-18',[Security.AccessControl.FileSystemRights]::Modify),@('S-1-5-32-544',[Security.AccessControl.FileSystemRights]::Modify),@($sid,([Security.AccessControl.FileSystemRights]::ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete)))){[void]$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new([string]$entry[0]),[Security.AccessControl.FileSystemRights]$entry[1],$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow))};$created=[IO.Directory]::CreateDirectory($path,$acl);if([IO.Path]::GetFullPath($created.FullName)-ine[IO.Path]::GetFullPath($path)-or($created.Attributes-band[IO.FileAttributes]::ReparsePoint)-or@($created.EnumerateFileSystemInfos()).Count){exit 1};$outputStream=[IO.FileStream]::new($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$bytes=[Text.Encoding]::ASCII.GetBytes($path);$outputStream.Write($bytes,0,$bytes.Length);$outputStream.Flush($true)}finally{$outputStream.Dispose()}" >nul 2>nul
if errorlevel 1 exit /b 1

:secure_temp_created
for /F "usebackq delims=" %%P in ("%SECURE_TEMP_OUTPUT%") do if not defined SECURE_TEMP_PATH set "SECURE_TEMP_PATH=%%P"
del "%SECURE_TEMP_OUTPUT%" >nul 2>nul
set "SECURE_TEMP_OUTPUT="
if not defined SECURE_TEMP_PATH exit /b 1
set "EXEC_TEMP=%SECURE_TEMP_PATH%"
set "SECURE_TEMP_ACTIVE=1"
call :validate_secure_temp
if errorlevel 1 (
    call :cleanup_secure_temp
    exit /b 1
)
exit /b 0

:validate_secure_temp
if defined CP_RUNTIME_OPERATION_ID if defined CP_ELEVATE_TRANSCRIPT_DIR goto validate_recoverable_secure_temp
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$path=[IO.Path]::GetFullPath($env:SECURE_TEMP_PATH).TrimEnd([char]92);$base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92);if(-not $path.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $path) -notmatch '^cp-setup-[0-9a-f]{32}$'){exit 1};$item=Get-Item -LiteralPath $path -Force -ErrorAction Stop;if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or -not $item.PSIsContainer){exit 1};$acl=$item.GetAccessControl();if(-not $acl.AreAccessRulesProtected -or $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne 'S-1-5-32-544'){exit 1};$rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]));$sids=@('S-1-5-18','S-1-5-32-544');$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit;if($rules.Count -ne 2){exit 1};foreach($rule in $rules){if($rule.IsInherited -or $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or $sids -notcontains $rule.IdentityReference.Value -or $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::Modify -or $rule.InheritanceFlags -ne $inherit -or $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None){exit 1}};exit 0" >nul 2>nul
exit /b %ERRORLEVEL%

:validate_recoverable_secure_temp
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$nonce=$env:CP_RUNTIME_OPERATION_ID;$sid=([Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)).Value;$path=[IO.Path]::GetFullPath($env:SECURE_TEMP_PATH).TrimEnd([char]92);$expected=[IO.Path]::GetFullPath((Join-Path (Join-Path $env:SystemRoot 'Temp') ('cp-setup-'+$nonce))).TrimEnd([char]92);if($nonce-notmatch'^[0-9a-f]{32}$'-or$path-ine$expected){exit 1};$item=Get-Item -LiteralPath $path -Force -ErrorAction Stop;if(-not$item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-or@($item.EnumerateFileSystemInfos()).Count){exit 1};$acl=$item.GetAccessControl();if(-not$acl.AreAccessRulesProtected-or$acl.GetOwner([Security.Principal.SecurityIdentifier]).Value-ne'S-1-5-32-544'){exit 1};$rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]));$expectedRules=@{'S-1-5-18'=[Security.AccessControl.FileSystemRights]::Modify;'S-1-5-32-544'=[Security.AccessControl.FileSystemRights]::Modify;$sid=([Security.AccessControl.FileSystemRights]::ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete)};$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit;if($rules.Count-ne$expectedRules.Count){exit 1};foreach($rule in $rules){if($rule.IsInherited-or$rule.AccessControlType-ne[Security.AccessControl.AccessControlType]::Allow-or-not$expectedRules.ContainsKey($rule.IdentityReference.Value)-or$rule.FileSystemRights-ne$expectedRules[$rule.IdentityReference.Value]-or$rule.InheritanceFlags-ne$inherit-or$rule.PropagationFlags-ne[Security.AccessControl.PropagationFlags]::None){exit 1}};exit 0" >nul 2>nul
exit /b %ERRORLEVEL%

:cleanup_secure_temp
if defined PROCESS_TREE_PS del "%PROCESS_TREE_PS%" >nul 2>nul
set "PROCESS_TREE_PS="
if defined MEDIUM_LAUNCHER_PS del "%MEDIUM_LAUNCHER_PS%" >nul 2>nul
if defined MEDIUM_NATIVE_CS del "%MEDIUM_NATIVE_CS%" >nul 2>nul
if defined MEDIUM_REGISTRY_PLAN_PS del "%MEDIUM_REGISTRY_PLAN_PS%" >nul 2>nul
set "MEDIUM_LAUNCHER_PS="
set "MEDIUM_NATIVE_CS="
set "MEDIUM_REGISTRY_PLAN_PS="
if not "%SECURE_TEMP_ACTIVE%"=="1" exit /b 0
if defined CP_RUNTIME_OPERATION_ID if defined CP_ELEVATE_TRANSCRIPT_DIR goto cleanup_recoverable_secure_temp
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)+'\'; $path=[IO.Path]::GetFullPath($env:EXEC_TEMP).TrimEnd([char]92); if(-not $path.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $path) -notmatch '^cp-setup-[0-9a-f]{32}$'){exit 1}; $sids=@('S-1-5-18','S-1-5-32-544'); function Test-Security($item){$acl=$item.GetAccessControl();if(-not $acl.AreAccessRulesProtected -or $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne 'S-1-5-32-544'){return $false};$rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]));if($rules.Count -ne 2){return $false};$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit;foreach($rule in $rules){if($rule.IsInherited -or $rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or $sids -notcontains $rule.IdentityReference.Value -or $rule.FileSystemRights -ne [Security.AccessControl.FileSystemRights]::Modify -or $rule.InheritanceFlags -ne $inherit -or $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None){return $false}};return $true};$root=[IO.DirectoryInfo]::new($path);if(($root.Attributes -band [IO.FileAttributes]::ReparsePoint) -or -not (Test-Security $root)){exit 1};$stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root);while($stack.Count){$dir=$stack.Pop();foreach($item in $dir.EnumerateFileSystemInfos()){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){exit 1};if($item -is [IO.DirectoryInfo]){$stack.Push($item)}}};[IO.Directory]::Delete($path,$true)"
set "SECURE_TEMP_EXIT=%ERRORLEVEL%"
if "%SECURE_TEMP_EXIT%"=="0" (
    set "SECURE_TEMP_ACTIVE=0"
    set "EXEC_TEMP=%VISIBLE_TEMP%"
)
exit /b %SECURE_TEMP_EXIT%

:cleanup_recoverable_secure_temp
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$nonce=$env:CP_RUNTIME_OPERATION_ID;$path=[IO.Path]::GetFullPath($env:EXEC_TEMP).TrimEnd([char]92);$expected=[IO.Path]::GetFullPath((Join-Path (Join-Path $env:SystemRoot 'Temp') ('cp-setup-'+$nonce))).TrimEnd([char]92);if($nonce-notmatch'^[0-9a-f]{32}$'-or$path-ine$expected){exit 1};$root=Get-Item -LiteralPath $path -Force -ErrorAction Stop;if(-not$root.PSIsContainer-or($root.Attributes-band[IO.FileAttributes]::ReparsePoint)){exit 1};$stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root);while($stack.Count){foreach($item in $stack.Pop().EnumerateFileSystemInfos()){if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){exit 1};if($item-is[IO.DirectoryInfo]){$stack.Push($item)}}};[IO.Directory]::Delete($path,$true);if(Test-Path -LiteralPath $path){exit 1};$marker=Join-Path ([IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR)) 'runtime.marker';Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue;exit 0"
set "SECURE_TEMP_EXIT=%ERRORLEVEL%"
if "%SECURE_TEMP_EXIT%"=="0" (
    set "SECURE_TEMP_ACTIVE=0"
    set "EXEC_TEMP=%VISIBLE_TEMP%"
)
exit /b %SECURE_TEMP_EXIT%

:sanitize_privileged_environment
set "SECURE_PROGRAM_FILES="
set "SECURE_PROGRAM_FILES_X86="
set "SECURE_PROGRAM_FILES_DATA=%EXEC_TEMP%\cp_setup_program_files_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "[IO.File]::WriteAllLines($env:SECURE_PROGRAM_FILES_DATA,@('PF='+[Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles),'PFX86='+[Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)),[Text.Encoding]::UTF8)" >nul 2>nul
if errorlevel 1 exit /b 1
for /F "usebackq tokens=1,* delims==" %%A in ("%SECURE_PROGRAM_FILES_DATA%") do set "SECURE_PROGRAM_FILES_%%A=%%B"
del "%SECURE_PROGRAM_FILES_DATA%" >nul 2>nul
set "SECURE_PROGRAM_FILES_DATA="
if not defined SECURE_PROGRAM_FILES_PF exit /b 1
set "ComSpec=%CMD_EXE%"
set "PATHEXT=.COM;.EXE;.BAT;.CMD"
set "PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0"
set "TEMP=%EXEC_TEMP%"
set "TMP=%EXEC_TEMP%"
set "TMPDIR=%EXEC_TEMP%"
set "PSModulePath=%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules"
if defined SECURE_PROGRAM_FILES_PF set "PSModulePath=%PSModulePath%;%SECURE_PROGRAM_FILES_PF%\WindowsPowerShell\Modules"
if defined SECURE_PROGRAM_FILES_PFX86 set "PSModulePath=%PSModulePath%;%SECURE_PROGRAM_FILES_PFX86%\WindowsPowerShell\Modules"
for %%V in (PYTHONHOME PYTHONPATH NODE_OPTIONS NODE_PATH JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS JDK_JAVAC_OPTIONS _JAVA_OPTIONS CLASSPATH BASH_ENV ENV SHELLOPTS BASHOPTS MSYS2_PATH_TYPE MSYS2_SHELL NVIM_APPNAME VIMINIT EXINIT LUA_PATH LUA_CPATH GCC_EXEC_PREFIX COMPILER_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH OBJC_INCLUDE_PATH COR_ENABLE_PROFILING COR_PROFILER COR_PROFILER_PATH COR_PROFILER_PATH_32 COR_PROFILER_PATH_64 CORECLR_ENABLE_PROFILING CORECLR_PROFILER CORECLR_PROFILER_PATH CORECLR_PROFILER_PATH_32 CORECLR_PROFILER_PATH_64 DOTNET_STARTUP_HOOKS DOTNET_ADDITIONAL_DEPS DOTNET_SHARED_STORE DOTNET_ROOT COMPLUS_InstallRoot COMPLUS_Version GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT COLLECT_0 LTO_0 LD_PRELOAD RUBYOPT PERL5OPT __COMPAT_LAYER) do set "%%V="
set "DOTNET_ROOT(x86)="
set "PYTHONNOUSERSITE=1"
set "GIT_CONFIG_GLOBAL=NUL"
set "GIT_CONFIG_NOSYSTEM=1"
set "GIT_TERMINAL_PROMPT=0"
exit /b 0

:initialize_target_user
set "TARGET_PROCESS_ELEVATED=0"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1" >nul 2>nul
if not errorlevel 1 set "TARGET_PROCESS_ELEVATED=1"
if not "%TARGET_PROCESS_ELEVATED%"=="1" set "CP_SETUP_TARGET_SID="
if not "%CP_SETUP_ELEVATED_CHILD%"=="1" set "CP_SETUP_TARGET_SID="
set "TARGET_SID_DATA=%EXEC_TEMP%\cp_setup_sid_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value" > "%TARGET_SID_DATA%" 2>nul
if errorlevel 1 exit /b 1
for /F "usebackq delims=" %%S in ("%TARGET_SID_DATA%") do if not defined CP_SETUP_TARGET_SID set "CP_SETUP_TARGET_SID=%%S"
del "%TARGET_SID_DATA%" >nul 2>nul
set "TARGET_SID_DATA="
if not "%TARGET_PROCESS_ELEVATED%"=="1" if not "%RESOLVE_TARGET_FULL%"=="1" (
    set "TARGET_PROCESS_ELEVATED="
    if not defined CP_SETUP_TARGET_SID exit /b 1
    set "TARGET_USER_DEFERRED=1"
    exit /b 0
)
set "TARGET_PROCESS_ELEVATED="
if not defined CP_SETUP_TARGET_SID exit /b 1
set "TARGET_INFO=%EXEC_TEMP%\cp_setup_target_%RANDOM%_%RANDOM%.txt"
set "TARGET_PROFILE_FILE=%EXEC_TEMP%\cp_setup_profile_%RANDOM%_%RANDOM%.txt"
set "TARGET_LOCAL_FILE=%EXEC_TEMP%\cp_setup_local_%RANDOM%_%RANDOM%.txt"
set "TARGET_APP_FILE=%EXEC_TEMP%\cp_setup_app_%RANDOM%_%RANDOM%.txt"
set "TARGET_NVIM_FILE=%EXEC_TEMP%\cp_setup_nvim_%RANDOM%_%RANDOM%.txt"
set "TARGET_TEMP_FILE=%EXEC_TEMP%\cp_setup_temp_%RANDOM%_%RANDOM%.txt"
set "TARGET_ELEVATED_LOCAL_FILE=%EXEC_TEMP%\cp_setup_elevated_local_%RANDOM%_%RANDOM%.txt"
set "TARGET_PS=%EXEC_TEMP%\cp_setup_target_%RANDOM%_%RANDOM%.ps1"
> "%TARGET_PS%" echo $ErrorActionPreference = 'Stop'
>> "%TARGET_PS%" echo $sid = $env:CP_SETUP_TARGET_SID
>> "%TARGET_PS%" echo if ^($sid -notmatch '^S-1-^(?:[0-9]+-^)+[0-9]+$'^) { throw 'Invalid target SID.' }
>> "%TARGET_PS%" echo $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%TARGET_PS%" echo $elevatedLocal = [IO.Path]::GetFullPath^([Environment]::GetFolderPath^([Environment+SpecialFolder]::LocalApplicationData^)^).TrimEnd^([char]92^)
>> "%TARGET_PS%" echo $users = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Default^)
>> "%TARGET_PS%" echo $targetHive = $users.OpenSubKey^($sid^)
>> "%TARGET_PS%" echo if ^(-not $targetHive^) { throw 'The target user registry hive is not loaded.' }
>> "%TARGET_PS%" echo $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default^)
>> "%TARGET_PS%" echo $profileKey = $machine.OpenSubKey^('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $sid^)
>> "%TARGET_PS%" echo if ^(-not $profileKey^) { throw 'The target profile is not registered.' }
>> "%TARGET_PS%" echo $profileRaw = [string]$profileKey.GetValue^('ProfileImagePath', $null, $options^)
>> "%TARGET_PS%" echo if ^([string]::IsNullOrWhiteSpace^($profileRaw^)^) { throw 'The target profile path is missing.' }
>> "%TARGET_PS%" echo $profile = [IO.Path]::GetFullPath^([Environment]::ExpandEnvironmentVariables^($profileRaw^)^).TrimEnd^([char]92^)
>> "%TARGET_PS%" echo $qualifier = [IO.Path]::GetPathRoot^($profile^)
>> "%TARGET_PS%" echo if ^([string]::IsNullOrWhiteSpace^($qualifier^) -or $profile -notmatch '^[A-Za-z]:\\'^) { throw 'The target profile path is not local.' }
>> "%TARGET_PS%" echo $env:USERPROFILE = $profile
>> "%TARGET_PS%" echo $env:HOMEDRIVE = $qualifier.TrimEnd^([char]92^)
>> "%TARGET_PS%" echo $env:HOMEPATH = $profile.Substring^($qualifier.Length - 1^)
>> "%TARGET_PS%" echo function Resolve-TargetPath^([object]$value, [string]$fallback^) {
>> "%TARGET_PS%" echo     $text = [string]$value
>> "%TARGET_PS%" echo     if ^([string]::IsNullOrWhiteSpace^($text^)^) { $text = $fallback }
>> "%TARGET_PS%" echo     [IO.Path]::GetFullPath^([Environment]::ExpandEnvironmentVariables^($text^)^).TrimEnd^([char]92^)
>> "%TARGET_PS%" echo }
>> "%TARGET_PS%" echo function Assert-Descendant^([string]$child, [string]$parent^) {
>> "%TARGET_PS%" echo     $prefix = $parent.TrimEnd^([char]92^) + [char]92
>> "%TARGET_PS%" echo     if ^(-not $child.StartsWith^($prefix, [StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Unsafe target path outside profile: ' + $child^) }
>> "%TARGET_PS%" echo }
>> "%TARGET_PS%" echo function Assert-NoReparse^([string]$path^) {
>> "%TARGET_PS%" echo     $full = [IO.Path]::GetFullPath^($path^)
>> "%TARGET_PS%" echo     $root = [IO.Path]::GetPathRoot^($full^)
>> "%TARGET_PS%" echo     $current = $root.TrimEnd^([char]92^)
>> "%TARGET_PS%" echo     foreach ^($part in $full.Substring^($root.Length^).Split^([char]92, [StringSplitOptions]::RemoveEmptyEntries^)^) {
>> "%TARGET_PS%" echo         $current = Join-Path $current $part
>> "%TARGET_PS%" echo         if ^(Test-Path -LiteralPath $current^) { $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe target path component: ' + $current^) } }
>> "%TARGET_PS%" echo     }
>> "%TARGET_PS%" echo }
>> "%TARGET_PS%" echo $shell = $users.OpenSubKey^($sid + '\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'^)
>> "%TARGET_PS%" echo $localRaw = if ^($shell^) { $shell.GetValue^('Local AppData', $null, $options^) } else { $null }
>> "%TARGET_PS%" echo $roamingRaw = if ^($shell^) { $shell.GetValue^('AppData', $null, $options^) } else { $null }
>> "%TARGET_PS%" echo $derivedLocal = Resolve-TargetPath $localRaw ^(Join-Path $profile 'AppData\Local'^)
>> "%TARGET_PS%" echo $derivedRoaming = Resolve-TargetPath $roamingRaw ^(Join-Path $profile 'AppData\Roaming'^)
>> "%TARGET_PS%" echo $state = $machine.OpenSubKey^('Software\my-cp-setup\Users\' + $sid^)
>> "%TARGET_PS%" echo $protected = $state -and ^(@^($state.GetValueNames^(^) ^| Where-Object { $_ -like 'Target.*' }^).Count -gt 0^)
>> "%TARGET_PS%" echo if ^($protected^) {
>> "%TARGET_PS%" echo     if ^([string]$state.GetValue^('Target.Sid', $null, $options^) -ine $sid^) { throw 'Protected target SID does not match.' }
>> "%TARGET_PS%" echo     $storedProfile = Resolve-TargetPath $state.GetValue^('Target.Profile', $null, $options^) $profile
>> "%TARGET_PS%" echo     if ^($storedProfile -ine $profile^) { throw 'Protected target profile does not match Windows.' }
>> "%TARGET_PS%" echo     $local = Resolve-TargetPath $state.GetValue^('Target.LocalAppData', $null, $options^) $derivedLocal
>> "%TARGET_PS%" echo     $roaming = Resolve-TargetPath $state.GetValue^('Target.AppData', $null, $options^) $derivedRoaming
>> "%TARGET_PS%" echo     $nvimData = Resolve-TargetPath $state.GetValue^('NvimData.Root', $null, $options^) ^(Join-Path $local 'nvim-data'^)
>> "%TARGET_PS%" echo } else {
>> "%TARGET_PS%" echo     $local = $derivedLocal
>> "%TARGET_PS%" echo     $roaming = $derivedRoaming
>> "%TARGET_PS%" echo     $nvimData = [IO.Path]::GetFullPath^((Join-Path $local 'nvim-data'^)^).TrimEnd^([char]92^)
>> "%TARGET_PS%" echo }
>> "%TARGET_PS%" echo Assert-Descendant $local $profile
>> "%TARGET_PS%" echo Assert-Descendant $roaming $profile
>> "%TARGET_PS%" echo Assert-Descendant $nvimData $local
>> "%TARGET_PS%" echo $targetTemp = [IO.Path]::GetFullPath^((Join-Path $local 'Temp'^)^).TrimEnd^([char]92^)
>> "%TARGET_PS%" echo Assert-Descendant $targetTemp $local
>> "%TARGET_PS%" echo if ^($nvimData -ine [IO.Path]::GetFullPath^((Join-Path $local 'nvim-data'^)^).TrimEnd^([char]92^)^) { throw 'Protected Neovim data root is inconsistent.' }
>> "%TARGET_PS%" echo foreach ^($path in @^($profile,$local,$roaming,$nvimData,$targetTemp,$elevatedLocal^)^) { Assert-NoReparse $path }
>> "%TARGET_PS%" echo if ^(-not [IO.Directory]::Exists^($targetTemp^)^) { throw 'The target temporary directory is missing.' }
>> "%TARGET_PS%" echo [IO.File]::WriteAllText^($env:TARGET_PROFILE_FILE, $profile, [Text.Encoding]::UTF8^); [IO.File]::WriteAllText^($env:TARGET_LOCAL_FILE, $local, [Text.Encoding]::UTF8^); [IO.File]::WriteAllText^($env:TARGET_APP_FILE, $roaming, [Text.Encoding]::UTF8^); [IO.File]::WriteAllText^($env:TARGET_NVIM_FILE, $nvimData, [Text.Encoding]::UTF8^); [IO.File]::WriteAllText^($env:TARGET_TEMP_FILE, $targetTemp, [Text.Encoding]::UTF8^); [IO.File]::WriteAllText^($env:TARGET_ELEVATED_LOCAL_FILE, $elevatedLocal, [Text.Encoding]::UTF8^)
>> "%TARGET_PS%" echo foreach ^($key in @^($state,$shell,$profileKey,$targetHive,$users,$machine^)^) { if ^($key^) { $key.Dispose^(^) } }
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%TARGET_PS%"
set "TARGET_EXIT=%ERRORLEVEL%"
del "%TARGET_PS%" >nul 2>nul
if not "%TARGET_EXIT%"=="0" (
    del "%TARGET_INFO%" >nul 2>nul
    del "%TARGET_PROFILE_FILE%" "%TARGET_LOCAL_FILE%" "%TARGET_APP_FILE%" "%TARGET_NVIM_FILE%" "%TARGET_TEMP_FILE%" "%TARGET_ELEVATED_LOCAL_FILE%" >nul 2>nul
    exit /b 1
)
set /p "CP_SETUP_TARGET_PROFILE="<"%TARGET_PROFILE_FILE%"
set /p "CP_SETUP_TARGET_LOCALAPPDATA="<"%TARGET_LOCAL_FILE%"
set /p "CP_SETUP_TARGET_APPDATA="<"%TARGET_APP_FILE%"
set /p "CP_SETUP_TARGET_NVIMDATA_ROOT="<"%TARGET_NVIM_FILE%"
set /p "CP_SETUP_TARGET_TEMP="<"%TARGET_TEMP_FILE%"
set /p "CP_SETUP_ELEVATED_LOCALAPPDATA="<"%TARGET_ELEVATED_LOCAL_FILE%"
del "%TARGET_INFO%" >nul 2>nul
del "%TARGET_PROFILE_FILE%" "%TARGET_LOCAL_FILE%" "%TARGET_APP_FILE%" "%TARGET_NVIM_FILE%" "%TARGET_TEMP_FILE%" "%TARGET_ELEVATED_LOCAL_FILE%" >nul 2>nul
set "TARGET_INFO="
set "TARGET_PROFILE_FILE="
set "TARGET_LOCAL_FILE="
set "TARGET_APP_FILE="
set "TARGET_NVIM_FILE="
set "TARGET_TEMP_FILE="
set "TARGET_ELEVATED_LOCAL_FILE="
set "TARGET_PS="
set "TARGET_EXIT="
if not defined CP_SETUP_TARGET_PROFILE exit /b 1
if not defined CP_SETUP_TARGET_LOCALAPPDATA exit /b 1
if not defined CP_SETUP_TARGET_APPDATA exit /b 1
if not defined CP_SETUP_TARGET_NVIMDATA_ROOT exit /b 1
if not defined CP_SETUP_TARGET_TEMP exit /b 1
if not defined CP_SETUP_ELEVATED_LOCALAPPDATA exit /b 1
set "VISIBLE_TEMP=%CP_SETUP_TARGET_TEMP%"
exit /b 0

:validate_setup_root
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:ROOT; if ($root -notmatch '^[A-Za-z]:\\') { exit 1 }; foreach ($code in @(33,37,38,59,60,62,94,124)) { if ($root.IndexOf([char]$code) -ge 0) { exit 1 } }; foreach ($value in @($env:VISIBLE_TEMP,$env:CP_SETUP_TARGET_LOCALAPPDATA,$env:CP_SETUP_TARGET_APPDATA)) { if ($value -and $value.IndexOf([char]33) -ge 0) { exit 2 } }; exit 0"
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
set "STATE_ROOT_CHECK=%EXEC_TEMP%\cp_setup_state_root_%RANDOM%_%RANDOM%.ps1"
> "%STATE_ROOT_CHECK%" echo $ErrorActionPreference = 'Stop'
>> "%STATE_ROOT_CHECK%" echo $sid = $env:CP_SETUP_TARGET_SID
>> "%STATE_ROOT_CHECK%" echo $root = [IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^)
>> "%STATE_ROOT_CHECK%" echo $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%STATE_ROOT_CHECK%" echo $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default^)
>> "%STATE_ROOT_CHECK%" echo $users = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Default^)
>> "%STATE_ROOT_CHECK%" echo $state = $machine.OpenSubKey^('Software\my-cp-setup\Users\' + $sid^)
>> "%STATE_ROOT_CHECK%" echo $legacy = $users.OpenSubKey^($sid + '\Software\my-cp-setup'^)
>> "%STATE_ROOT_CHECK%" echo if ^(-not $state -and $legacy^) { Write-Host '[FAILED] Legacy per-user CP setup state was found.'; Write-Host 'Remove the old test installation before using this installer.'; exit 1 }
>> "%STATE_ROOT_CHECK%" echo if ^($state^) {
>> "%STATE_ROOT_CHECK%" echo     $names = @^($state.GetValueNames^(^)^)
>> "%STATE_ROOT_CHECK%" echo     $complete=$names -contains 'Snapshot.Complete' -and $state.GetValueKind^('Snapshot.Complete'^) -eq [Microsoft.Win32.RegistryValueKind]::DWord -and [int]$state.GetValue^('Snapshot.Complete',0,$options^) -eq 1
>> "%STATE_ROOT_CHECK%" echo     if ^(-not $complete^) { if ^($env:ALLOW_PARTIAL_STATE_RECOVERY -ne '1' -or $names -contains 'Snapshot.Complete' -or $state.SubKeyCount -ne 0^) { Write-Host '[FAILED] Protected CP setup state is incomplete or unsupported.'; Write-Host 'Uninstall the existing CP setup before running this installer again.'; exit 1 }; $exact=@^('SchemaVersion','Target.Sid','Target.Profile','Target.LocalAppData','Target.AppData','NvimData.Root','Path.HadValue','Path.Before','Path.Before.Kind','AutoRun.HadValue','AutoRun.Before','AutoRun.Before.Kind','Console.VirtualTerminal.HadValue','Console.VirtualTerminal.Before','Console.VirtualTerminal.Before.Kind','NvimData.Existed','Mason.Packages.Before','JdtlsWorkspace.Path','JdtlsWorkspace.Existed','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^); $unexpected=@^($names ^| Where-Object { $_ -notin $exact -and $_ -notmatch '^Env\.[^.]+\.^(' + 'HadValue^|Before^|Before\.Kind' + '^)$' }^); if ^($unexpected.Count^) { Write-Host '[FAILED] Protected CP setup state is incomplete or unsupported.'; exit 1 }; $expectedPartial=@{'Target.Sid'=$sid;'Target.Profile'=$env:CP_SETUP_TARGET_PROFILE;'Target.LocalAppData'=$env:CP_SETUP_TARGET_LOCALAPPDATA;'Target.AppData'=$env:CP_SETUP_TARGET_APPDATA;'NvimData.Root'=$env:CP_SETUP_TARGET_NVIMDATA_ROOT}; foreach ^($entry in $expectedPartial.GetEnumerator^(^)^) { if ^($names -contains $entry.Key -and ^($state.GetValueKind^($entry.Key^) -ne [Microsoft.Win32.RegistryValueKind]::String -or [string]$state.GetValue^($entry.Key,$null,$options^) -ine [string]$entry.Value^)^) { Write-Host '[FAILED] Protected CP setup target state is inconsistent.'; exit 1 } }; if ^($names -contains 'SchemaVersion' -and ^($state.GetValueKind^('SchemaVersion'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('SchemaVersion',0,$options^) -ne %STATE_SCHEMA%^)^) { Write-Host '[FAILED] Protected CP setup state is incomplete or unsupported.'; exit 1 }; foreach ^($name in @^($names ^| Where-Object { $_ -in @^('Mason.Packages.Before','Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^) }^)^) { if ^($state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { Write-Host '[FAILED] Protected CP setup state is incomplete or unsupported.'; exit 1 } }; $state.Dispose^(^); $state=$null; $machine.DeleteSubKey^('Software\my-cp-setup\Users\'+$sid,$false^); if ^($machine.OpenSubKey^('Software\my-cp-setup\Users\'+$sid^)^) { Write-Host '[FAILED] Incomplete protected CP setup state could not be recovered.'; exit 1 }; exit 0 }
>> "%STATE_ROOT_CHECK%" echo     if ^($names -notcontains 'SchemaVersion' -or [int]$state.GetValue^('SchemaVersion'^) -ne %STATE_SCHEMA%^) { Write-Host '[FAILED] Protected CP setup state is incomplete or unsupported.'; Write-Host 'Uninstall the existing CP setup before running this installer again.'; exit 1 }
>> "%STATE_ROOT_CHECK%" echo     $expected = @{'Target.Sid'=$sid; 'Target.Profile'=$env:CP_SETUP_TARGET_PROFILE; 'Target.LocalAppData'=$env:CP_SETUP_TARGET_LOCALAPPDATA; 'Target.AppData'=$env:CP_SETUP_TARGET_APPDATA; 'NvimData.Root'=$env:CP_SETUP_TARGET_NVIMDATA_ROOT}
>> "%STATE_ROOT_CHECK%" echo     foreach ^($entry in $expected.GetEnumerator^(^)^) { if ^($names -notcontains $entry.Key -or [string]$state.GetValue^($entry.Key, $null, $options^) -ine [string]$entry.Value^) { Write-Host '[FAILED] Protected CP setup target state is inconsistent.'; Write-Host 'Uninstall the existing CP setup before running this installer again.'; exit 1 } }
>> "%STATE_ROOT_CHECK%" echo     $stored = [string]$state.GetValue^('Install.Root', $null, $options^)
>> "%STATE_ROOT_CHECK%" echo     if ^($stored -and [IO.Path]::GetFullPath^($stored^).TrimEnd^([char]92^) -ine $root^) { Write-Host ^('[FAILED] This setup is already managed from: ' + $stored^); Write-Host 'Uninstall it from that folder before using a different root.'; exit 1 }
>> "%STATE_ROOT_CHECK%" echo }
>> "%STATE_ROOT_CHECK%" echo foreach ^($key in @^($legacy,$state,$users,$machine^)^) { if ^($key^) { $key.Dispose^(^) } }
>> "%STATE_ROOT_CHECK%" echo exit 0
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%STATE_ROOT_CHECK%"
set "STATE_ROOT_EXIT=%ERRORLEVEL%"
del "%STATE_ROOT_CHECK%" >nul 2>nul
exit /b %STATE_ROOT_EXIT%

:initialize_state
set "ALLOW_PARTIAL_STATE_RECOVERY=1"
call :check_state_root
set "ALLOW_PARTIAL_STATE_RECOVERY="
if errorlevel 1 exit /b 1
call :capture_target_profile_artifacts snapshot
if errorlevel 1 exit /b 1
set "STATE_INIT_PS=%EXEC_TEMP%\cp_setup_state_init_%RANDOM%_%RANDOM%.ps1"
> "%STATE_INIT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%STATE_INIT_PS%" echo $sid = $env:CP_SETUP_TARGET_SID
>> "%STATE_INIT_PS%" echo $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%STATE_INIT_PS%" echo $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default^)
>> "%STATE_INIT_PS%" echo $users = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Default^)
>> "%STATE_INIT_PS%" echo $state = $machine.CreateSubKey^('Software\my-cp-setup\Users\' + $sid, $true^)
>> "%STATE_INIT_PS%" echo $userHive = $users.OpenSubKey^($sid, $true^)
>> "%STATE_INIT_PS%" echo if ^(-not $userHive^) { throw 'The target user registry hive is not writable.' }
>> "%STATE_INIT_PS%" echo $envKey = $userHive.OpenSubKey^('Environment'^)
>> "%STATE_INIT_PS%" echo $cmdKey = $userHive.OpenSubKey^('Software\Microsoft\Command Processor'^)
>> "%STATE_INIT_PS%" echo $consoleKey = $userHive.OpenSubKey^('Console'^)
>> "%STATE_INIT_PS%" echo $artifactFile = [IO.Path]::GetFullPath^($env:ARTIFACT_SNAPSHOT_FILE^)
>> "%STATE_INIT_PS%" echo $execRoot = [IO.Path]::GetFullPath^($env:EXEC_TEMP^).TrimEnd^([char]92^) + [char]92
>> "%STATE_INIT_PS%" echo if ^(-not $artifactFile.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^) -or -not [IO.File]::Exists^($artifactFile^) -or ^([IO.File]::GetAttributes^($artifactFile^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw 'Protected artifact snapshot is missing.' }
>> "%STATE_INIT_PS%" echo $artifactBefore = [string[]][IO.File]::ReadAllLines^($artifactFile^)
>> "%STATE_INIT_PS%" echo $stateNames = @^($state.GetValueNames^(^)^)
>> "%STATE_INIT_PS%" echo if ^($stateNames -contains 'SchemaVersion' -and [int]$state.GetValue^('SchemaVersion'^) -ne %STATE_SCHEMA%^) { throw 'Unsupported protected state schema.' }
>> "%STATE_INIT_PS%" echo $state.SetValue^('SchemaVersion', %STATE_SCHEMA%, [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo $state.SetValue^('Target.Sid', $sid, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo $state.SetValue^('Target.Profile', $env:CP_SETUP_TARGET_PROFILE, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo $state.SetValue^('Target.LocalAppData', $env:CP_SETUP_TARGET_LOCALAPPDATA, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo $state.SetValue^('Target.AppData', $env:CP_SETUP_TARGET_APPDATA, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo $state.SetValue^('NvimData.Root', $env:CP_SETUP_TARGET_NVIMDATA_ROOT, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo function Snapshot-StringValue^($source, [string]$sourceName, [string]$prefix^) {
>> "%STATE_INIT_PS%" echo     $had = $source -and ^(@^($source.GetValueNames^(^)^) -contains $sourceName^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^($prefix + '.HadValue', [int]$had, [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo     if ^(-not $had^) { return }
>> "%STATE_INIT_PS%" echo     $kind = $source.GetValueKind^($sourceName^)
>> "%STATE_INIT_PS%" echo     if ^($kind -ne [Microsoft.Win32.RegistryValueKind]::String -and $kind -ne [Microsoft.Win32.RegistryValueKind]::ExpandString^) { throw ^('Unsupported registry kind for ' + $sourceName^) }
>> "%STATE_INIT_PS%" echo     $raw = [string]$source.GetValue^($sourceName, $null, $options^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^($prefix + '.Before', $raw, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^($prefix + '.Before.Kind', [int]$kind, [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo }
>> "%STATE_INIT_PS%" echo if ^(@^($state.GetValueNames^(^)^) -notcontains 'Snapshot.Complete'^) {
>> "%STATE_INIT_PS%" echo     foreach ^($name in @^('XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA'^)^) { Snapshot-StringValue $envKey $name ^('Env.' + $name^) }
>> "%STATE_INIT_PS%" echo     Snapshot-StringValue $envKey 'Path' 'Path'
>> "%STATE_INIT_PS%" echo     Snapshot-StringValue $cmdKey 'AutoRun' 'AutoRun'
>> "%STATE_INIT_PS%" echo     $consoleHad = $consoleKey -and ^(@^($consoleKey.GetValueNames^(^)^) -contains 'VirtualTerminalLevel'^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('Console.VirtualTerminal.HadValue', [int]$consoleHad, [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo     if ^($consoleHad^) { $consoleKind = $consoleKey.GetValueKind^('VirtualTerminalLevel'^); $state.SetValue^('Console.VirtualTerminal.Before', [int]$consoleKey.GetValue^('VirtualTerminalLevel', 0, $options^), [Microsoft.Win32.RegistryValueKind]::DWord^); $state.SetValue^('Console.VirtualTerminal.Before.Kind', [int]$consoleKind, [Microsoft.Win32.RegistryValueKind]::DWord^) }
>> "%STATE_INIT_PS%" echo     $nvimData = $env:CP_SETUP_TARGET_NVIMDATA_ROOT
>> "%STATE_INIT_PS%" echo     $state.SetValue^('NvimData.Existed', [int][IO.Directory]::Exists^($nvimData^), [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo     $masonPackages = Join-Path $nvimData 'mason\packages'
>> "%STATE_INIT_PS%" echo     foreach ^($path in @^($nvimData, ^(Join-Path $nvimData 'mason'^), $masonPackages^)^) { if ^(Test-Path -LiteralPath $path^) { $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe Mason inventory path: '+$path^) } } }
>> "%STATE_INIT_PS%" echo     $masonBefore = @^(if ^(Test-Path -LiteralPath $masonPackages -PathType Container^) { foreach ^($item in Get-ChildItem -LiteralPath $masonPackages -Directory -Force -ErrorAction Stop^) { if ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Unsafe Mason package reparse point: '+$item.FullName^) }; if ^($item.Name -notmatch '^^[A-Za-z0-9._-]+$' -or $item.Name -in @^('.','..'^)^) { throw ^('Unsafe Mason package name: '+$item.Name^) }; $item.Name } }^)
>> "%STATE_INIT_PS%" echo     $masonBefore = @^($masonBefore ^| Sort-Object -Unique^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('Mason.Packages.Before', [string[]]$masonBefore, [Microsoft.Win32.RegistryValueKind]::MultiString^)
>> "%STATE_INIT_PS%" echo     $setupRoot = [IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^)
>> "%STATE_INIT_PS%" echo     $sha = [Security.Cryptography.SHA256]::Create^(^); try { $rootHash = ^([BitConverter]::ToString^($sha.ComputeHash^([Text.UTF8Encoding]::new^($false^).GetBytes^($setupRoot^)^)^)^).Replace^('-',''^).ToLowerInvariant^(^) } finally { $sha.Dispose^(^) }
>> "%STATE_INIT_PS%" echo     $jdtls = [IO.Path]::GetFullPath^((Join-Path $nvimData ^('jdtls-workspaces\cp-' + $rootHash.Substring^(0,16^)^)^)^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('JdtlsWorkspace.Path', $jdtls, [Microsoft.Win32.RegistryValueKind]::String^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('JdtlsWorkspace.Existed', [int][IO.Directory]::Exists^($jdtls^), [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('Artifacts.Before.Paths', $artifactBefore, [Microsoft.Win32.RegistryValueKind]::MultiString^)
>> "%STATE_INIT_PS%" echo     $artifactRoots=[string[]]@^(@^($env:CP_SETUP_TARGET_LOCALAPPDATA,$env:CP_SETUP_ELEVATED_LOCALAPPDATA^) ^| ForEach-Object { [IO.Path]::GetFullPath^([string]$_^).TrimEnd^([char]92^) } ^| Sort-Object -Unique^); $state.SetValue^('Artifacts.LocalAppData.Roots',$artifactRoots,[Microsoft.Win32.RegistryValueKind]::MultiString^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('Artifacts.Created.Paths', [string[]]@^(^), [Microsoft.Win32.RegistryValueKind]::MultiString^)
>> "%STATE_INIT_PS%" echo     $state.SetValue^('Snapshot.Complete', 1, [Microsoft.Win32.RegistryValueKind]::DWord^)
>> "%STATE_INIT_PS%" echo }
>> "%STATE_INIT_PS%" echo foreach ^($key in @^($consoleKey,$cmdKey,$envKey,$userHive,$state,$users,$machine^)^) { if ^($key^) { $key.Dispose^(^) } }
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%STATE_INIT_PS%"
set "STATE_INIT_EXIT=%ERRORLEVEL%"
del "%STATE_INIT_PS%" >nul 2>nul
if defined ARTIFACT_SNAPSHOT_FILE del "%ARTIFACT_SNAPSHOT_FILE%" >nul 2>nul
set "ARTIFACT_SNAPSHOT_FILE="
if "%STATE_INIT_EXIT%"=="0" "%REG_EXE%" query "%STATE_KEY%" /v "Install.Root" >nul 2>nul
if "%STATE_INIT_EXIT%"=="0" if not errorlevel 1 set "STATE_ROOT_CLAIMED=1"
exit /b %STATE_INIT_EXIT%

:capture_target_profile_artifacts
set "ARTIFACT_CAPTURE_MODE=%~1"
if /i "%ARTIFACT_CAPTURE_MODE%"=="operation" (
    if defined ARTIFACT_OPERATION_FILE del "%ARTIFACT_OPERATION_FILE%" >nul 2>nul
    if defined ARTIFACT_OPERATION_TIME_FILE del "%ARTIFACT_OPERATION_TIME_FILE%" >nul 2>nul
    set "ARTIFACT_OPERATION_FILE=%EXEC_TEMP%\cp_setup_artifacts_operation_%RANDOM%_%RANDOM%.txt"
    set "ARTIFACT_OPERATION_TIME_FILE=%EXEC_TEMP%\cp_setup_artifacts_operation_%RANDOM%_%RANDOM%.time"
    set "ARTIFACT_CAPTURE_DEST=%ARTIFACT_OPERATION_FILE%"
    set "ARTIFACT_CAPTURE_TIME_DEST=%ARTIFACT_OPERATION_TIME_FILE%"
) else (
    set "ARTIFACT_CAPTURE_MODE=snapshot"
    if defined ARTIFACT_SNAPSHOT_FILE del "%ARTIFACT_SNAPSHOT_FILE%" >nul 2>nul
    set "ARTIFACT_SNAPSHOT_FILE=%EXEC_TEMP%\cp_setup_artifacts_snapshot_%RANDOM%_%RANDOM%.txt"
    set "ARTIFACT_CAPTURE_DEST=%ARTIFACT_SNAPSHOT_FILE%"
    set "ARTIFACT_CAPTURE_TIME_DEST="
)
set "ARTIFACT_CAPTURE_PS=%EXEC_TEMP%\cp_setup_artifacts_capture_%RANDOM%_%RANDOM%.ps1"
> "%ARTIFACT_CAPTURE_PS%" echo param^([ValidateSet^('snapshot','operation'^)][string]$Mode,[string]$Destination,[string]$TimestampDestination^)
>> "%ARTIFACT_CAPTURE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ARTIFACT_CAPTURE_PS%" echo function Hash^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^) } finally { $sha.Dispose^(^) } }
>> "%ARTIFACT_CAPTURE_PS%" echo $option = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%ARTIFACT_CAPTURE_PS%" echo $targetLocal = [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_LOCALAPPDATA^).TrimEnd^([char]92^)
>> "%ARTIFACT_CAPTURE_PS%" echo $execRoot = [IO.Path]::GetFullPath^($env:EXEC_TEMP^).TrimEnd^([char]92^) + [char]92
>> "%ARTIFACT_CAPTURE_PS%" echo $destination = [IO.Path]::GetFullPath^($Destination^); if ^(-not $destination.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Artifact snapshot escaped protected temporary storage.' }
>> "%ARTIFACT_CAPTURE_PS%" echo function Set-Roots^($values^) { $list=[Collections.Generic.List[string]]::new^(^); foreach ^($raw in @^($values^)^) { if ^([string]::IsNullOrWhiteSpace^([string]$raw^)^) { throw 'Empty artifact LocalAppData root.' }; $text=^([string]$raw^).TrimEnd^([char]92^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^([char]92^); if ^($full -ine $text -or $full -notmatch '^[A-Za-z]:\\'^) { throw ^('Artifact LocalAppData root is not canonical and local: '+$text^) }; if ^($list -inotcontains $full^) { $list.Add^($full^) } }; if ^(-not $list.Count -or $list -inotcontains $targetLocal^) { throw 'Target LocalAppData is absent from artifact roots.' }; $script:locals=[string[]]@^($list ^| Sort-Object -Unique^); $built=[Collections.Generic.List[object]]::new^(^); foreach ^($local in $script:locals^) { $built.Add^([pscustomobject]@{Local=$local;Kind='nvim';Parent=[IO.Path]::GetFullPath^((Join-Path $local 'Temp'^)^).TrimEnd^([char]92^);Target=[IO.Path]::GetFullPath^((Join-Path $local 'Temp\nvim'^)^).TrimEnd^([char]92^)^}^); $built.Add^([pscustomobject]@{Local=$local;Kind='qt';Parent=[IO.Path]::GetFullPath^((Join-Path $local 'cache'^)^).TrimEnd^([char]92^);Target=[IO.Path]::GetFullPath^((Join-Path $local 'cache\qt-installer-framework'^)^).TrimEnd^([char]92^)^}^) }; $script:roots=@^($built^) }
>> "%ARTIFACT_CAPTURE_PS%" echo function Assert-NoReparse^([string]$path^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^([char]92^); $match=@^($locals ^| Where-Object { $full -ieq $_ -or $full.StartsWith^($_+[char]92,[StringComparison]::OrdinalIgnoreCase^) } ^| Sort-Object Length -Descending ^| Select-Object -First 1^); if ^($match.Count -ne 1^) { throw ^('Artifact path escaped LocalAppData roots: '+$full^) }; $local=[string]$match[0]; $current=$local; if ^(Test-Path -LiteralPath $current^) { $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe artifact path component: '+$current^) } }; if ^($full.Length -gt $local.Length^) { foreach ^($part in $full.Substring^($local.Length+1^).Split^([char]92,[StringSplitOptions]::RemoveEmptyEntries^)^) { $current=Join-Path $current $part; if ^(Test-Path -LiteralPath $current^) { $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Unsafe artifact reparse point: '+$current^) } } } } }
>> "%ARTIFACT_CAPTURE_PS%" echo function Assert-InventoryPath^([string]$raw^) { if ^([string]::IsNullOrWhiteSpace^($raw^)^) { throw 'Empty artifact snapshot path.' }; $text=$raw.TrimEnd^([char]92^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^([char]92^); if ^($full -ine $text^) { throw ^('Artifact snapshot path is not canonical: '+$text^) }; $match=@^($roots ^| Where-Object { $full -ieq $_.Target -or $full.StartsWith^($_.Target+[char]92,[StringComparison]::OrdinalIgnoreCase^) }^); if ^($match.Count -ne 1^) { throw ^('Artifact snapshot path escaped the allowlist: '+$full^) }; Assert-NoReparse $full; $full }
>> "%ARTIFACT_CAPTURE_PS%" echo function Get-Inventory { $found=[Collections.Generic.List[string]]::new^(^); foreach ^($entry in $roots^) { Assert-NoReparse $entry.Parent; if ^(-not ^(Test-Path -LiteralPath $entry.Target^)^) { continue }; $rootItem=Get-Item -LiteralPath $entry.Target -Force -ErrorAction Stop; if ^(-not $rootItem.PSIsContainer -or ^($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe artifact root: '+$entry.Target^) }; $stack=[Collections.Generic.Stack[IO.FileSystemInfo]]::new^(^); $stack.Push^($rootItem^); while ^($stack.Count^) { $item=$stack.Pop^(^); $full=Assert-InventoryPath $item.FullName; $found.Add^($full^); if ^($item -is [IO.DirectoryInfo]^) { foreach ^($child in $item.EnumerateFileSystemInfos^(^)^) { if ^($child.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Unsafe artifact reparse point: '+$child.FullName^) }; $stack.Push^($child^) } } } }; @^($found ^| Sort-Object -Unique^) }
>> "%ARTIFACT_CAPTURE_PS%" echo $started = [DateTime]::UtcNow
>> "%ARTIFACT_CAPTURE_PS%" echo if ^($Mode -eq 'snapshot'^) { $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^); $state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID^); try { if ^($state -and @^($state.GetValueNames^(^)^) -contains 'Snapshot.Complete'^) { $names=@^($state.GetValueNames^(^)^); if ^([string]$state.GetValue^('Target.LocalAppData',$null,$option^) -ine $targetLocal^) { throw 'Protected Target.LocalAppData changed.' }; foreach ^($name in @^('Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^)^) { if ^($names -notcontains $name -or $state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Protected artifact inventory is incomplete.' } }; Set-Roots @^($state.GetValue^('Artifacts.LocalAppData.Roots',$null,$option^)^); $paths=@^($state.GetValue^('Artifacts.Before.Paths',$null,$option^) ^| ForEach-Object { Assert-InventoryPath ^([string]$_^) }^) } else { Set-Roots @^($targetLocal,$env:CP_SETUP_ELEVATED_LOCALAPPDATA^); $paths=@^(Get-Inventory^) } } finally { if ^($state^) { $state.Dispose^(^) }; $machine.Dispose^(^) } } else { Set-Roots @^($targetLocal,$env:CP_SETUP_ELEVATED_LOCALAPPDATA^); $paths=@^(Get-Inventory^) }
>> "%ARTIFACT_CAPTURE_PS%" echo $unique=[Collections.Generic.HashSet[string]]::new^([StringComparer]::OrdinalIgnoreCase^); foreach ^($path in $paths^) { if ^(-not $unique.Add^([string]$path^)^) { throw ^('Duplicate artifact snapshot path: '+$path^) } }
>> "%ARTIFACT_CAPTURE_PS%" echo [IO.File]::WriteAllLines^($destination,[string[]]@^($paths^),[Text.UTF8Encoding]::new^($false^)^)
>> "%ARTIFACT_CAPTURE_PS%" echo if ^($Mode -eq 'operation'^) { $time=[IO.Path]::GetFullPath^($TimestampDestination^); if ^(-not $time.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^)^) { throw 'Artifact timestamp escaped protected temporary storage.' }; [IO.File]::WriteAllText^($time,[string]$started.Ticks,[Text.Encoding]::ASCII^); $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^); $state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^); if ^(-not $state^) { throw 'Protected artifact-operation state is missing.' }; try { if ^(@^($state.GetValueNames^(^)^) -contains 'Pending.Artifacts.Intent'^) { throw 'Another artifact operation is pending.' }; $nonce=[guid]::NewGuid^(^).ToString^('N'^); $operator=^([Security.Principal.WindowsIdentity]::GetCurrent^(^)^).User.Value; $plan=[ordered]@{Version=1;OperationId=$nonce;Sid=$env:CP_SETUP_TARGET_SID;OperatorSid=$operator;LocalAppDataRoots=[string[]]@^($locals^);StartedTicks=[string]$started.Ticks;BeforePaths=[string[]]@^($paths^)}; $json=$plan^|ConvertTo-Json -Compress; $bytes=[Text.Encoding]::UTF8.GetBytes^($json^); $intent='v1^|'+$nonce+'^|prepared^|'+^(Hash $bytes^)+'^|'+[Convert]::ToBase64String^($bytes^); $state.SetValue^('Pending.Artifacts.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String^); if ^([string]$state.GetValue^('Pending.Artifacts.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^) -cne $intent^) { throw 'Pending artifact intent did not verify.' } } finally { $state.Dispose^(^); $machine.Dispose^(^) } }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ARTIFACT_CAPTURE_PS%" -Mode "%ARTIFACT_CAPTURE_MODE%" -Destination "%ARTIFACT_CAPTURE_DEST%" -TimestampDestination "%ARTIFACT_CAPTURE_TIME_DEST%"
set "ARTIFACT_CAPTURE_EXIT=%ERRORLEVEL%"
del "%ARTIFACT_CAPTURE_PS%" >nul 2>nul
set "ARTIFACT_CAPTURE_PS="
set "ARTIFACT_CAPTURE_MODE="
set "ARTIFACT_CAPTURE_DEST="
set "ARTIFACT_CAPTURE_TIME_DEST="
if not "%ARTIFACT_CAPTURE_EXIT%"=="0" exit /b %ARTIFACT_CAPTURE_EXIT%
exit /b 0

:repair_target_profile_artifacts
set "ARTIFACT_REPAIR_PS=%EXEC_TEMP%\cp_setup_artifacts_repair_%RANDOM%_%RANDOM%.ps1"
> "%ARTIFACT_REPAIR_PS%" echo $ErrorActionPreference = 'Stop'
>> "%ARTIFACT_REPAIR_PS%" echo function Hash^([byte[]]$bytes^) { $sha=[Security.Cryptography.SHA256]::Create^(^); try { ^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^) } finally { $sha.Dispose^(^) } }
>> "%ARTIFACT_REPAIR_PS%" echo $option = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%ARTIFACT_REPAIR_PS%" echo $targetLocal = [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_LOCALAPPDATA^).TrimEnd^([char]92^)
>> "%ARTIFACT_REPAIR_PS%" echo $execRoot = [IO.Path]::GetFullPath^($env:EXEC_TEMP^).TrimEnd^([char]92^) + [char]92
>> "%ARTIFACT_REPAIR_PS%" echo function Set-Roots^($values^) { $list=[Collections.Generic.List[string]]::new^(^); foreach ^($raw in @^($values^)^) { if ^([string]::IsNullOrWhiteSpace^([string]$raw^)^) { throw 'Empty artifact LocalAppData root.' }; $text=^([string]$raw^).TrimEnd^([char]92^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^([char]92^); if ^($full -ine $text -or $full -notmatch '^[A-Za-z]:\\'^) { throw ^('Artifact LocalAppData root is not canonical and local: '+$text^) }; if ^($list -inotcontains $full^) { $list.Add^($full^) } }; if ^(-not $list.Count -or $list -inotcontains $targetLocal^) { throw 'Target LocalAppData is absent from artifact roots.' }; $script:locals=[string[]]@^($list ^| Sort-Object -Unique^); $built=[Collections.Generic.List[object]]::new^(^); foreach ^($local in $script:locals^) { $built.Add^([pscustomobject]@{Local=$local;Kind='nvim';Parent=[IO.Path]::GetFullPath^((Join-Path $local 'Temp'^)^).TrimEnd^([char]92^);Target=[IO.Path]::GetFullPath^((Join-Path $local 'Temp\nvim'^)^).TrimEnd^([char]92^)^}^); $built.Add^([pscustomobject]@{Local=$local;Kind='qt';Parent=[IO.Path]::GetFullPath^((Join-Path $local 'cache'^)^).TrimEnd^([char]92^);Target=[IO.Path]::GetFullPath^((Join-Path $local 'cache\qt-installer-framework'^)^).TrimEnd^([char]92^)^}^) }; $script:roots=@^($built^) }
>> "%ARTIFACT_REPAIR_PS%" echo function Assert-NoReparse^([string]$path^) { $full=[IO.Path]::GetFullPath^($path^).TrimEnd^([char]92^); $match=@^($locals ^| Where-Object { $full -ieq $_ -or $full.StartsWith^($_+[char]92,[StringComparison]::OrdinalIgnoreCase^) } ^| Sort-Object Length -Descending ^| Select-Object -First 1^); if ^($match.Count -ne 1^) { throw ^('Artifact path escaped LocalAppData roots: '+$full^) }; $local=[string]$match[0]; $current=$local; if ^(Test-Path -LiteralPath $current^) { $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe artifact path component: '+$current^) } }; if ^($full.Length -gt $local.Length^) { foreach ^($part in $full.Substring^($local.Length+1^).Split^([char]92,[StringSplitOptions]::RemoveEmptyEntries^)^) { $current=Join-Path $current $part; if ^(Test-Path -LiteralPath $current^) { $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Unsafe artifact reparse point: '+$current^) } } } } }
>> "%ARTIFACT_REPAIR_PS%" echo function Assert-InventoryPath^([string]$raw^) { if ^([string]::IsNullOrWhiteSpace^($raw^)^) { throw 'Empty artifact inventory path.' }; $text=$raw.TrimEnd^([char]92^); $full=[IO.Path]::GetFullPath^($text^).TrimEnd^([char]92^); if ^($full -ine $text^) { throw ^('Artifact inventory path is not canonical: '+$text^) }; $match=@^($roots ^| Where-Object { $full -ieq $_.Target -or $full.StartsWith^($_.Target+[char]92,[StringComparison]::OrdinalIgnoreCase^) }^); if ^($match.Count -ne 1^) { throw ^('Artifact inventory path escaped the allowlist: '+$full^) }; Assert-NoReparse $full; $full }
>> "%ARTIFACT_REPAIR_PS%" echo function Get-Inventory { $found=[Collections.Generic.List[string]]::new^(^); foreach ^($entry in $roots^) { Assert-NoReparse $entry.Parent; if ^(-not ^(Test-Path -LiteralPath $entry.Target^)^) { continue }; $rootItem=Get-Item -LiteralPath $entry.Target -Force -ErrorAction Stop; if ^(-not $rootItem.PSIsContainer -or ^($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Unsafe artifact root: '+$entry.Target^) }; $stack=[Collections.Generic.Stack[IO.FileSystemInfo]]::new^(^); $stack.Push^($rootItem^); while ^($stack.Count^) { $item=$stack.Pop^(^); $full=Assert-InventoryPath $item.FullName; $found.Add^($full^); if ^($item -is [IO.DirectoryInfo]^) { foreach ^($child in $item.EnumerateFileSystemInfos^(^)^) { if ^($child.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Unsafe artifact reparse point: '+$child.FullName^) }; $stack.Push^($child^) } } } }; @^($found ^| Sort-Object -Unique^) }
>> "%ARTIFACT_REPAIR_PS%" echo function New-PathSet { return ,^([Collections.Generic.HashSet[string]]::new^([StringComparer]::OrdinalIgnoreCase^)^) }
>> "%ARTIFACT_REPAIR_PS%" echo function Add-Validated^($set,$values^) { foreach ^($raw in @^($values^)^) { $full=Assert-InventoryPath ^([string]$raw^); if ^(-not $set.Add^($full^)^) { throw ^('Duplicate artifact inventory path: '+$full^) } } }
>> "%ARTIFACT_REPAIR_PS%" echo function Read-Intent^($state^) { $names=@^($state.GetValueNames^(^)^); if ^($names -notcontains 'Pending.Artifacts.Intent'^) { return $null }; if ^($state.GetValueKind^('Pending.Artifacts.Intent'^) -ne [Microsoft.Win32.RegistryValueKind]::String^) { throw 'Pending artifact intent has an invalid kind.' }; $raw=[string]$state.GetValue^('Pending.Artifacts.Intent',$null,$option^); $parts=$raw.Split^(@^('^|'^),5^); if ^($parts.Count -ne 5 -or $parts[0] -cne 'v1' -or $parts[1] -notmatch '^[0-9a-f]{32}$' -or $parts[2] -notin @^('prepared','committed'^) -or $parts[3] -notmatch '^[0-9a-f]{64}$'^) { throw 'Invalid pending artifact intent.' }; $bytes=[Convert]::FromBase64String^($parts[4]^); if ^((Hash $bytes^) -cne $parts[3]^) { throw 'Invalid pending artifact intent hash.' }; $json=[Text.Encoding]::UTF8.GetString^($bytes^); $plan=$json^|ConvertFrom-Json; if ^(^($plan^|ConvertTo-Json -Compress^) -cne $json -or [int]$plan.Version -ne 1 -or [string]$plan.OperationId -cne $parts[1] -or [string]$plan.Sid -cne $env:CP_SETUP_TARGET_SID -or [string]$plan.OperatorSid -notmatch '^S-1-^(?:[0-9]+-^)+[0-9]+$'^) { throw 'Invalid pending artifact plan.' }; [long]$ticks=0; if ^(-not [long]::TryParse^([string]$plan.StartedTicks,[ref]$ticks^) -or $ticks -lt [DateTime]::MinValue.Ticks -or $ticks -gt [DateTime]::UtcNow.AddMinutes^(1^).Ticks^) { throw 'Invalid pending artifact timestamp.' }; [pscustomobject]@{Raw=$raw;Nonce=$parts[1];Stage=$parts[2];Hash=$parts[3];Json=$json;Plan=$plan;Ticks=$ticks} }
>> "%ARTIFACT_REPAIR_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^); $state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^); if ^(-not $state^) { throw 'Protected artifact ownership state is missing.' }
>> "%ARTIFACT_REPAIR_PS%" echo try {
>> "%ARTIFACT_REPAIR_PS%" echo     $names=@^($state.GetValueNames^(^)^); if ^($names -notcontains 'Snapshot.Complete' -or [int]$state.GetValue^('Snapshot.Complete',0,$option^) -ne 1 -or [string]$state.GetValue^('Target.LocalAppData',$null,$option^) -ine $targetLocal^) { throw 'Protected artifact snapshot is invalid.' }
>> "%ARTIFACT_REPAIR_PS%" echo     foreach ^($name in @^('Artifacts.LocalAppData.Roots','Artifacts.Before.Paths','Artifacts.Created.Paths'^)^) { if ^($names -notcontains $name -or $state.GetValueKind^($name^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Artifact ownership metadata is incomplete.' } }
>> "%ARTIFACT_REPAIR_PS%" echo     $intent=Read-Intent $state; $metadataRoots=[string[]]@^($state.GetValue^('Artifacts.LocalAppData.Roots',$null,$option^)^); $intentRoots=if ^($intent^) { [string[]]@^($intent.Plan.LocalAppDataRoots^) } else { [string[]]@^(^) }; Set-Roots @^($metadataRoots+$intentRoots^)
>> "%ARTIFACT_REPAIR_PS%" echo     $before=New-PathSet; Add-Validated $before @^($state.GetValue^('Artifacts.Before.Paths',$null,$option^)^)
>> "%ARTIFACT_REPAIR_PS%" echo     $owned=New-PathSet; Add-Validated $owned @^($state.GetValue^('Artifacts.Created.Paths',$null,$option^)^); foreach ^($path in $owned^) { if ^($before.Contains^($path^)^) { throw ^('Artifact path is both preexisting and setup-owned: '+$path^) } }
>> "%ARTIFACT_REPAIR_PS%" echo     $current=@^(Get-Inventory^); $operation=New-PathSet; $started=[DateTime]::UtcNow; $hasFile=^(-not [string]::IsNullOrWhiteSpace^($env:ARTIFACT_OPERATION_FILE^)^); $hasTime=^(-not [string]::IsNullOrWhiteSpace^($env:ARTIFACT_OPERATION_TIME_FILE^)^); if ^($hasFile -ne $hasTime^) { throw 'Incomplete local artifact operation snapshot.' }
>> "%ARTIFACT_REPAIR_PS%" echo     if ^($hasFile^) { if ^(-not $intent^) { throw 'Local artifact snapshot has no protected intent.' }; $operationFile=[IO.Path]::GetFullPath^($env:ARTIFACT_OPERATION_FILE^); $timeFile=[IO.Path]::GetFullPath^($env:ARTIFACT_OPERATION_TIME_FILE^); if ^(-not $operationFile.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^) -or -not $timeFile.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^) -or -not [IO.File]::Exists^($operationFile^) -or -not [IO.File]::Exists^($timeFile^)^) { throw 'Protected artifact operation snapshot is missing.' }; Add-Validated $operation ^([IO.File]::ReadAllLines^($operationFile^)^); [long]$ticks=0; if ^(-not [long]::TryParse^([IO.File]::ReadAllText^($timeFile^),[ref]$ticks^) -or $ticks -ne $intent.Ticks^) { throw 'Artifact operation snapshot does not match its protected intent.' }; $planned=New-PathSet; Add-Validated $planned @^($intent.Plan.BeforePaths^); if ^($planned.Count -ne $operation.Count -or @^($planned ^| Where-Object { -not $operation.Contains^($_^) }^).Count^) { throw 'Artifact operation snapshot does not match its protected intent.' }; $started=[DateTime]::new^($ticks,[DateTimeKind]::Utc^) } elseif ^($intent^) { Add-Validated $operation @^($intent.Plan.BeforePaths^); $started=[DateTime]::new^($intent.Ticks,[DateTimeKind]::Utc^) } else { foreach ^($path in $current^) { [void]$operation.Add^($path^) } }
>> "%ARTIFACT_REPAIR_PS%" echo     foreach ^($path in $operation^) { if ^(-not $owned.Contains^($path^)^) { [void]$before.Add^($path^) } }; $candidates=New-PathSet; foreach ^($path in $current^) { if ^(-not $before.Contains^($path^) -and -not $owned.Contains^($path^) -and -not $operation.Contains^($path^) -and ^(Split-Path -Leaf $path^) -notlike 'cp_setup_*.log'^) { [void]$candidates.Add^($path^) } }
>> "%ARTIFACT_REPAIR_PS%" echo     $candidateRoots=[Collections.Generic.List[string]]::new^(^); foreach ^($path in $candidates^) { $parent=Split-Path -Parent $path; if ^(-not $candidates.Contains^($parent^)^) { $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop; if ^($item.CreationTimeUtc -lt $started.AddSeconds^(-5^)^) { continue }; $candidateRoots.Add^($path^) } }
>> "%ARTIFACT_REPAIR_PS%" echo     $targetSid=^([Security.Principal.SecurityIdentifier]::new^($env:CP_SETUP_TARGET_SID^)^).Value; $operatorSid=if ^($intent^) { [string]$intent.Plan.OperatorSid } else { '' }; $allowedQt=@^($targetSid,$operatorSid,'S-1-5-18','S-1-5-32-544'^); foreach ^($path in $candidates^) { $candidateRoot=@^($candidateRoots ^| Where-Object { $path -ieq $_ -or $path.StartsWith^($_+[char]92,[StringComparison]::OrdinalIgnoreCase^) } ^| Select-Object -First 1^); if ^($candidateRoot.Count -ne 1^) { continue }; $entry=@^($roots ^| Where-Object { $path -ieq $_.Target -or $path.StartsWith^($_.Target+[char]92,[StringComparison]::OrdinalIgnoreCase^) }^); if ^($entry.Count -ne 1 -or ^($entry[0].Kind -eq 'nvim' -and $entry[0].Local -ine $targetLocal^)^) { continue }; $owner=^(Get-Acl -LiteralPath $path -ErrorAction Stop^).GetOwner^([Security.Principal.SecurityIdentifier]^).Value; if ^(^($entry[0].Kind -eq 'nvim' -and $owner -ine $targetSid^) -or ^($entry[0].Kind -eq 'qt' -and $allowedQt -inotcontains $owner^)^) { continue }; [void]$owned.Add^($path^) }
>> "%ARTIFACT_REPAIR_PS%" echo     $rootResult=[string[]]@^($locals ^| Sort-Object -Unique^); $beforeResult=[string[]]@^($before ^| Sort-Object -Unique^); $ownedResult=[string[]]@^($owned ^| Sort-Object -Unique^); $state.SetValue^('Artifacts.LocalAppData.Roots',$rootResult,[Microsoft.Win32.RegistryValueKind]::MultiString^); $state.SetValue^('Artifacts.Before.Paths',$beforeResult,[Microsoft.Win32.RegistryValueKind]::MultiString^); $state.SetValue^('Artifacts.Created.Paths',$ownedResult,[Microsoft.Win32.RegistryValueKind]::MultiString^); foreach ^($entry in @^(@^('Artifacts.LocalAppData.Roots',$rootResult^),@^('Artifacts.Before.Paths',$beforeResult^),@^('Artifacts.Created.Paths',$ownedResult^)^)^) { if ^($state.GetValueKind^([string]$entry[0]^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Artifact ownership write did not verify.' }; $verify=@^($state.GetValue^([string]$entry[0],$null,$option^)^); if ^($verify.Count -ne $entry[1].Count -or @^($entry[1] ^| Where-Object { $verify -inotcontains $_ }^).Count^) { throw 'Artifact ownership write did not verify.' } }
>> "%ARTIFACT_REPAIR_PS%" echo     if ^($intent^) { $committed='v1^|'+$intent.Nonce+'^|committed^|'+$intent.Hash+'^|'+[Convert]::ToBase64String^([Text.Encoding]::UTF8.GetBytes^($intent.Json^)^); $state.SetValue^('Pending.Artifacts.Intent',$committed,[Microsoft.Win32.RegistryValueKind]::String^); if ^([string]$state.GetValue^('Pending.Artifacts.Intent',$null,$option^) -cne $committed^) { throw 'Committed artifact intent did not verify.' }; $state.DeleteValue^('Pending.Artifacts.Intent',$false^); if ^(@^($state.GetValueNames^(^)^) -contains 'Pending.Artifacts.Intent'^) { throw 'Pending artifact intent cleanup failed.' } }
>> "%ARTIFACT_REPAIR_PS%" echo } finally { $state.Dispose^(^); $machine.Dispose^(^) }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ARTIFACT_REPAIR_PS%"
set "ARTIFACT_REPAIR_EXIT=%ERRORLEVEL%"
del "%ARTIFACT_REPAIR_PS%" >nul 2>nul
if defined ARTIFACT_OPERATION_FILE del "%ARTIFACT_OPERATION_FILE%" >nul 2>nul
if defined ARTIFACT_OPERATION_TIME_FILE del "%ARTIFACT_OPERATION_TIME_FILE%" >nul 2>nul
set "ARTIFACT_REPAIR_PS="
set "ARTIFACT_OPERATION_FILE="
set "ARTIFACT_OPERATION_TIME_FILE="
exit /b %ARTIFACT_REPAIR_EXIT%

:claim_state_root
if "%STATE_ROOT_CLAIMED%"=="1" exit /b 0
call :check_state_root
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default); $state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true); if (-not $state) { exit 1 }; $names=@($state.GetValueNames()); if ($names -notcontains 'Snapshot.Complete' -or [int]$state.GetValue('Snapshot.Complete') -ne 1 -or [int]$state.GetValue('SchemaVersion') -ne %STATE_SCHEMA%) { exit 1 }; $root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd([char]92); $stored=[string]$state.GetValue('Install.Root',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); if ($stored -and [IO.Path]::GetFullPath($stored).TrimEnd([char]92) -ine $root) { exit 1 }; $state.SetValue('Install.Root',$root,[Microsoft.Win32.RegistryValueKind]::String); $state.Dispose(); $machine.Dispose(); exit 0"
if errorlevel 1 exit /b 1
set "STATE_ROOT_CLAIMED=1"
exit /b 0

:enable_ansi
if not "%~1"=="1" (
    call :write_target_virtual_terminal
    if errorlevel 1 exit /b 1
)
call :enable_console_ansi
exit /b %ERRORLEVEL%

:enable_console_ansi
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Namespace Native -Name Console -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern System.IntPtr GetStdHandle(int nStdHandle); [DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out int lpMode); [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, int dwMode);'; $h=[Native.Console]::GetStdHandle(-11); $mode=0; if ([Native.Console]::GetConsoleMode($h,[ref]$mode)) { [Native.Console]::SetConsoleMode($h,$mode -bor 4) | Out-Null }" >nul 2>nul
for /F "delims=#" %%E in ('"prompt #$E# & for %%B in (1) do rem"') do set "ESC=%%E"
exit /b 0

:write_target_virtual_terminal
call :run_target_registry_transaction "VTL"
exit /b %ERRORLEVEL%

:ensure_admin
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $principal=[Security.Principal.WindowsPrincipal]::new($id); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1"
if not errorlevel 1 (
    if "%CP_SETUP_ELEVATED_CHILD%"=="1" exit /b 0
    set "CP_ELEVATE_ALREADY_ADMIN=1"
)

if not defined CP_ELEVATE_ALREADY_ADMIN if "%NON_INTERACTIVE%"=="1" (
    echo [%ESC%[31mFAILED%ESC%[0m] Administrator rights are required in non-interactive mode.
    echo Start an elevated cmd.exe and run this installer again.
    exit /b 1
)

set "ELEVATE_STARTED_FILE=%TEMP%\cp_setup_elevate_started_%RANDOM%_%RANDOM%.txt"
set "CP_INSTALL_SCRIPT=%~f0"
set "CP_INSTALL_ARGS=%ELEVATED_INSTALL_ARGS%"
set "CP_INSTALL_CWD=%ROOT%"
set "CP_ELEVATE_UAC_TIMEOUT_SECONDS=%UAC_TIMEOUT_SECONDS%"
set "CP_ELEVATE_CHILD_TIMEOUT_SECONDS=%INSTALL_CHILD_TIMEOUT_SECONDS%"
setlocal DisableDelayedExpansion
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$stream=[IO.File]::Open($env:CP_INSTALL_SCRIPT,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read);try{$reader=[IO.StreamReader]::new($stream,[Text.Encoding]::UTF8,$true,4096,$true);try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()};$lines=[regex]::Split($text,'\r?\n');$first=[Array]::IndexOf($lines,'::__CP_ELEVATE_ORCHESTRATOR_BEGIN__');$last=[Array]::IndexOf($lines,'::__CP_ELEVATE_ORCHESTRATOR_END__');if($first-lt 0-or$last-le$first){throw 'Missing elevation orchestrator.'};$source=for($i=$first+1;$i-lt$last;$i++){if(-not$lines[$i].StartsWith('::',[StringComparison]::Ordinal)){throw 'Malformed elevation orchestrator.'};$lines[$i].Substring(2)};&([scriptblock]::Create($source-join[Environment]::NewLine))}finally{$stream.Dispose()}"
set "ELEVATE_EXIT=%ERRORLEVEL%"
del "%ELEVATE_STARTED_FILE%" >nul 2>nul
endlocal & set "ELEVATION_HANDLED=1" & set "ELEVATED_CHILD_EXIT=%ELEVATE_EXIT%" & exit /b 0

:write_tool_finder
> "%~1" echo param^([Parameter^(Mandatory=$true^)][string]$Kind^)
>> "%~1" echo $ErrorActionPreference = 'SilentlyContinue'
>> "%~1" echo $privileged = $env:CP_SETUP_PRIVILEGED -eq '1'
>> "%~1" echo $options = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%~1" echo $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default^)
>> "%~1" echo $users = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Default^)
>> "%~1" echo $state = $machine.OpenSubKey^('Software\my-cp-setup\Users\' + $env:CP_SETUP_TARGET_SID^)
>> "%~1" echo $userEnv = if ^(-not $privileged^) { $users.OpenSubKey^($env:CP_SETUP_TARGET_SID + '\Environment'^) } else { $null }
>> "%~1" echo function Raw-Value^($key, [string]$name^) { if ^($key -and @^($key.GetValueNames^(^)^) -contains $name^) { $key.GetValue^($name, $null, $options^) } else { $null } }
>> "%~1" echo $candidates = New-Object 'System.Collections.Generic.List[string]'
>> "%~1" echo function Add-Candidate^($value^) { foreach ^($item in @^($value^)^) { if ^($item -and -not [string]::IsNullOrWhiteSpace^([string]$item^)^) { $candidates.Add^([string]$item^) } } }
>> "%~1" echo function Add-Where^([string]$name^) { if ^($privileged^) { return }; $found = ^& $env:WHERE_EXE $name 2^>$null; if ^($LASTEXITCODE -eq 0^) { Add-Candidate $found } }
>> "%~1" echo $trusted = @^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^)
>> "%~1" echo $dangerous = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Modify -bor [Security.AccessControl.FileSystemRights]::FullControl -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%~1" echo function Get-Sid^($identity^) { try { $text = [string]$identity; if ^($text -match '^S-1-'^) { return $text }; if ^($identity -is [Security.Principal.IdentityReference]^) { return $identity.Translate^([Security.Principal.SecurityIdentifier]^).Value }; return ^([Security.Principal.NTAccount]::new^($text^)^).Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { return $null } }
>> "%~1" echo function Test-ProtectedAcl^([string]$path^) {
>> "%~1" echo     try { $acl = Get-Acl -LiteralPath $path -ErrorAction Stop; if ^($trusted -notcontains ^(Get-Sid $acl.Owner^)^) { return $false }; foreach ^($ace in $acl.Access^) { if ^($ace.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and $ace.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::InheritOnly -and ^($ace.FileSystemRights -band $dangerous^) -ne 0 -and $trusted -notcontains ^(Get-Sid $ace.IdentityReference^)^) { return $false } }; return $true } catch { return $false }
>> "%~1" echo }
>> "%~1" echo $programFiles = [Environment]::GetFolderPath^([Environment+SpecialFolder]::ProgramFiles^)
>> "%~1" echo $programFilesX86 = [Environment]::GetFolderPath^([Environment+SpecialFolder]::ProgramFilesX86^)
>> "%~1" echo $msysRoot = Join-Path ^([IO.Path]::GetPathRoot^($env:SystemRoot^)^) 'msys64'
>> "%~1" echo $protectedRoots = @^($programFiles,$programFilesX86,$msysRoot^) ^| Where-Object { $_ } ^| Select-Object -Unique
>> "%~1" echo function Test-ProtectedCandidate^([string]$candidate^) {
>> "%~1" echo     if ^(-not $privileged^) { return $true }
>> "%~1" echo     try { $full = [IO.Path]::GetFullPath^($candidate^); $root = $protectedRoots ^| Where-Object { $full -ieq $_ -or $full.StartsWith^([IO.Path]::GetFullPath^($_^).TrimEnd^([char]92^) + [char]92, [StringComparison]::OrdinalIgnoreCase^) } ^| Sort-Object Length -Descending ^| Select-Object -First 1; if ^(-not $root^) { return $false }; $root = [IO.Path]::GetFullPath^($root^).TrimEnd^([char]92^); $current = $root; if ^(-not ^(Test-Path -LiteralPath $current^) -or ^(^(Get-Item -LiteralPath $current -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^) -or -not ^(Test-ProtectedAcl $current^)^) { return $false }; if ^($full.Length -gt $root.Length^) { foreach ^($part in $full.Substring^($root.Length + 1^).Split^([char]92, [StringSplitOptions]::RemoveEmptyEntries^)^) { $current = Join-Path $current $part; if ^(-not ^(Test-Path -LiteralPath $current^) -or ^(^(Get-Item -LiteralPath $current -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^) -or -not ^(Test-ProtectedAcl $current^)^) { return $false } } }; return $true } catch { return $false }
>> "%~1" echo }
>> "%~1" echo function Add-MsysCandidates {
>> "%~1" echo     Add-Candidate ^(Raw-Value $state 'Pacman.Shell.Path'^); Add-Candidate ^(Raw-Value $state 'Winget.MSYS2.Path'^); Add-Candidate $env:MSYS2_SHELL; Add-Candidate ^(Join-Path $msysRoot 'msys2_shell.cmd'^)
>> "%~1" echo     if ^(-not $privileged^) { foreach ^($name in @^('CP_GPP','CP_PYTHON'^)^) { $exe = Raw-Value $userEnv $name; if ^($exe^) { Add-Candidate ^(Join-Path ^(Split-Path -Parent ^(Split-Path -Parent ^(Split-Path -Parent $exe^)^)^) 'msys2_shell.cmd'^) } }; Add-Where 'msys2_shell.cmd' }
>> "%~1" echo }
>> "%~1" echo $pf = $programFiles
>> "%~1" echo switch ^($Kind.ToLowerInvariant^(^)^) {
>> "%~1" echo     'git' { Add-Candidate ^(Raw-Value $state 'Winget.Git.Path'^); Add-Candidate ^(Join-Path $pf 'Git\cmd\git.exe'^); Add-Where 'git.exe' }
>> "%~1" echo     'node' { Add-Candidate ^(Raw-Value $state 'Winget.Node.Path'^); Add-Candidate ^(Join-Path $pf 'nodejs\node.exe'^); Add-Where 'node.exe' }
>> "%~1" echo     'npm' { Add-Candidate ^(Join-Path $pf 'nodejs\npm.cmd'^); foreach ^($node in @^($env:FOUND_NODE_PATH, ^(Raw-Value $state 'Winget.Node.Path'^)^)^) { if ^($node^) { Add-Candidate ^(Join-Path ^(Split-Path -Parent $node^) 'npm.cmd'^) } }; Add-Where 'npm.cmd' }
>> "%~1" echo     'nvim' { Add-Candidate ^(Raw-Value $state 'Winget.Neovim.Path'^); Add-Candidate ^(Join-Path $pf 'Neovim\bin\nvim.exe'^); Add-Where 'nvim.exe' }
>> "%~1" echo     'javac' { Add-Candidate ^(Raw-Value $state 'Winget.JDK.Path'^); $jdkRoot = Join-Path $pf 'Eclipse Adoptium'; if ^(Test-Path -LiteralPath $jdkRoot -PathType Container^) { Get-ChildItem -LiteralPath $jdkRoot -Directory -Force -ErrorAction SilentlyContinue ^| ForEach-Object { Add-Candidate ^(Join-Path $_.FullName 'bin\javac.exe'^) } }; Add-Where 'javac.exe' }
>> "%~1" echo     'msys2' { Add-MsysCandidates }
>> "%~1" echo     'python' { Add-Candidate $env:CP_PYTHON; Add-MsysCandidates; foreach ^($shell in @^($candidates.ToArray^(^)^)^) { if ^($shell -and ^(Split-Path -Leaf $shell^) -ieq 'msys2_shell.cmd'^) { Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'mingw64\bin\python.exe'^); Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'ucrt64\bin\python.exe'^) } }; if ^(-not $privileged^) { Add-Candidate ^(Raw-Value $userEnv 'CP_PYTHON'^); Add-Where 'python.exe'; $launchers = ^& $env:WHERE_EXE py.exe 2^>$null; foreach ^($launcher in @^($launchers^)^) { $resolved = ^& $launcher -3 -c 'import sys; print(sys.executable)' 2^>$null; if ^($LASTEXITCODE -eq 0^) { Add-Candidate $resolved } } } }
>> "%~1" echo     'gpp' { Add-Candidate $env:CP_GPP; Add-MsysCandidates; foreach ^($shell in @^($candidates.ToArray^(^)^)^) { if ^($shell -and ^(Split-Path -Leaf $shell^) -ieq 'msys2_shell.cmd'^) { Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'mingw64\bin\g++.exe'^); Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'ucrt64\bin\g++.exe'^) } }; if ^(-not $privileged^) { Add-Candidate ^(Raw-Value $userEnv 'CP_GPP'^); Add-Where 'g++.exe' } }
>> "%~1" echo     'ruff' { Add-MsysCandidates; foreach ^($shell in @^($candidates.ToArray^(^)^)^) { if ^($shell -and ^(Split-Path -Leaf $shell^) -ieq 'msys2_shell.cmd'^) { Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'mingw64\bin\ruff.exe'^); Add-Candidate ^(Join-Path ^(Split-Path -Parent $shell^) 'ucrt64\bin\ruff.exe'^) } }; Add-Where 'ruff.exe' }
>> "%~1" echo     default { exit 1 }
>> "%~1" echo }
>> "%~1" echo foreach ^($candidate in @^($candidates ^| Select-Object -Unique^)^) {
>> "%~1" echo     try {
>> "%~1" echo         $path = [IO.Path]::GetFullPath^($candidate^)
>> "%~1" echo         if ^(-not ^(Test-Path -LiteralPath $path -PathType Leaf^) -or -not ^(Test-ProtectedCandidate $path^)^) { continue }
>> "%~1" echo         Push-Location -LiteralPath ^(Split-Path -Parent $path^)
>> "%~1" echo         try {
>> "%~1" echo         $ok = switch ^($Kind.ToLowerInvariant^(^)^) {
>> "%~1" echo             'git' { ^& $path --version ^>$null 2^>^&1; $LASTEXITCODE -eq 0 }
>> "%~1" echo             'node' { $value = ^& $path -p 'Boolean(process.release.lts)' 2^>$null ^| Select-Object -First 1; $LASTEXITCODE -eq 0 -and $value -eq 'true' }
>> "%~1" echo             'npm' { ^& $path --version ^>$null 2^>^&1; $LASTEXITCODE -eq 0 }
>> "%~1" echo             'nvim' { $line = ^& $path --version 2^>^&1 ^| Select-Object -First 1; $line -match 'v?^(\d+^)\.^(\d+^)' -and ^([int]$Matches[1] -gt 0 -or [int]$Matches[2] -ge 11^) }
>> "%~1" echo             'javac' { $java = Join-Path ^(Split-Path -Parent $path^) 'java.exe'; if ^(-not ^(Test-Path -LiteralPath $java -PathType Leaf^) -or -not ^(Test-ProtectedCandidate $java^)^) { $false } else { $javacLine = ^& $path -version 2^>^&1 ^| Select-Object -First 1; $javaLine = ^& $java -version 2^>^&1 ^| Select-Object -First 1; if ^($javacLine -match 'javac\s+^(\d+^)'^) { $javacMajor = [int]$Matches[1] } else { $javacMajor = 0 }; if ^($javaLine -match 'version\s+[^0-9]*^(\d+^)'^) { $javaMajor = [int]$Matches[1] } else { $javaMajor = 0 }; $javacMajor -ge 21 -and $javaMajor -ge 21 } }
>> "%~1" echo             'msys2' { $bash = Join-Path ^(Split-Path -Parent $path^) 'usr\bin\bash.exe'; ^(Split-Path -Leaf $path^) -ieq 'msys2_shell.cmd' -and ^(Test-Path -LiteralPath $bash -PathType Leaf^) -and ^(Test-ProtectedCandidate $bash^) }
>> "%~1" echo             'python' { if ^($path -like '*\Microsoft\WindowsApps\*'^) { $false } else { ^& $path -I -c 'import sys; raise SystemExit(1 if sys.version_info[:2] < (3, 10) else 0)' 2^>$null; $LASTEXITCODE -eq 0 } }
>> "%~1" echo             'gpp' { ^& $path --version ^> $null 2^>^&1; $LASTEXITCODE -eq 0 }
>> "%~1" echo             'ruff' { ^& $path --version ^> $null 2^>^&1; $LASTEXITCODE -eq 0 }
>> "%~1" echo         }
>> "%~1" echo         } finally { Pop-Location }
>> "%~1" echo         if ^($ok^) { Write-Output $path; foreach ^($key in @^($userEnv,$state,$users,$machine^)^) { if ^($key^) { $key.Dispose^(^) } }; exit 0 }
>> "%~1" echo     } catch {}
>> "%~1" echo }
>> "%~1" echo foreach ^($key in @^($userEnv,$state,$users,$machine^)^) { if ^($key^) { $key.Dispose^(^) } }
>> "%~1" echo exit 1
exit /b %ERRORLEVEL%

:run_tool_finder
set "TOOL_FINDER_PS=%EXEC_TEMP%\cp_setup_find_tool_%RANDOM%_%RANDOM%.ps1"
call :write_tool_finder "%TOOL_FINDER_PS%"
if errorlevel 1 (
    del "%TOOL_FINDER_PS%" >nul 2>nul
    exit /b 1
)
set "SEARCH_COMMAND_INPUT="%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%TOOL_FINDER_PS%" "%~1""
call :search_command "%~2" "@env" "%~3" "%~4"
set "TOOL_FIND_EXIT=%ERRORLEVEL%"
del "%TOOL_FINDER_PS%" >nul 2>nul
exit /b %TOOL_FIND_EXIT%

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
if "!PACKAGE_PREEXISTED!"=="0" (
    call :begin_pending_winget "Git.Git" "Winget.Git"
    if errorlevel 1 exit /b 1
)
set "INSTALL_CMD=!WINGET! install --id Git.Git %WINGET_QUIET_ARGS%"
call :run_install_spinner "Git via winget: Git.Git" "" "%VISIBLE_TEMP%\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" (
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
call :capture_winget_install_result "Git.Git" "Winget.Git"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_git quiet
if not errorlevel 1 (
    if "!PACKAGE_PREEXISTED!"=="0" (
        call :record_component_path "Winget.Git" "!FOUND_GIT_PATH!"
        if errorlevel 1 exit /b 1
        call :finish_pending_winget "Git.Git" "Winget.Git"
        if errorlevel 1 exit /b 1
    )
    call :print_installed "Git via winget: Git.Git" "!FOUND_GIT_PATH!"
    goto git_ready
)
echo [%ESC%[31mFAILED%ESC%[0m] Git was not found after winget install.
echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
exit /b 1

:git_ready
for %%I in ("%FOUND_GIT_PATH%") do set "PATH=%%~dpI;%PATH%"
exit /b 0

:find_git
call :run_tool_finder "git" "Git" "FOUND_GIT_PATH" "%~1"
exit /b %ERRORLEVEL%

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
if "!PACKAGE_PREEXISTED!"=="0" (
    call :begin_pending_winget "OpenJS.NodeJS.LTS" "Winget.Node"
    if errorlevel 1 exit /b 1
)
set "INSTALL_CMD=!WINGET! install --id OpenJS.NodeJS.LTS %WINGET_QUIET_ARGS%"
call :run_install_spinner "Node.js LTS and npm via winget: OpenJS.NodeJS.LTS" "" "%VISIBLE_TEMP%\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" (
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
call :capture_winget_install_result "OpenJS.NodeJS.LTS" "Winget.Node"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_node quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Node.js LTS was not found after winget install.
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
call :find_npm quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] npm was not found after installing Node.js LTS.
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
if "!PACKAGE_PREEXISTED!"=="0" (
    call :record_component_path "Winget.Node" "!FOUND_NODE_PATH!"
    if errorlevel 1 exit /b 1
    call :finish_pending_winget "OpenJS.NodeJS.LTS" "Winget.Node"
    if errorlevel 1 exit /b 1
)
call :print_installed "Node.js LTS and npm via winget: OpenJS.NodeJS.LTS" "!FOUND_NODE_PATH!"
goto node_and_npm_ready

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
if "!PACKAGE_PREEXISTED!"=="0" (
    call :begin_pending_winget "OpenJS.NodeJS.LTS" "Winget.Node"
    if errorlevel 1 exit /b 1
)
set "INSTALL_CMD=!WINGET! install --id OpenJS.NodeJS.LTS %WINGET_QUIET_ARGS% --force"
call :run_install_spinner "npm via winget: OpenJS.NodeJS.LTS" "" "%VISIBLE_TEMP%\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" (
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
call :capture_winget_install_result "OpenJS.NodeJS.LTS" "Winget.Node"
if errorlevel 1 exit /b 1
call :refresh_path
call :find_node quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Node.js LTS was not found after reinstalling its winget package.
    exit /b 1
)
call :find_npm quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] npm was not found after installing Node.js LTS.
    exit /b 1
)
if "!PACKAGE_PREEXISTED!"=="0" (
    call :record_component_path "Winget.Node" "!FOUND_NODE_PATH!"
    if errorlevel 1 exit /b 1
    call :finish_pending_winget "OpenJS.NodeJS.LTS" "Winget.Node"
    if errorlevel 1 exit /b 1
)
call :print_installed "npm via winget: OpenJS.NodeJS.LTS" "!FOUND_NPM_PATH!"
:node_and_npm_ready
exit /b 0

:find_node
call :run_tool_finder "node" "Node.js LTS" "FOUND_NODE_PATH" "%~1"
exit /b %ERRORLEVEL%

:find_npm
call :run_tool_finder "npm" "npm" "FOUND_NPM_PATH" "%~1"
exit /b %ERRORLEVEL%

:need_nvim
call :find_nvim_011
if not errorlevel 1 exit /b 0
if "%CHECK_ONLY%"=="1" (
    call :print_missing "Neovim 0.11 or newer"
    exit /b 0
)
call :install_or_upgrade_winget "Neovim.Neovim" "Neovim" "Winget.Neovim"
if errorlevel 1 exit /b 1
call :find_nvim_011 quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Neovim 0.11 or newer was not found after winget install.
    exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="0" (
    call :record_component_path "Winget.Neovim" "%FOUND_NVIM_PATH%"
    if errorlevel 1 exit /b 1
    call :finish_pending_winget "Neovim.Neovim" "Winget.Neovim"
    if errorlevel 1 exit /b 1
)
call :print_installed "Neovim via winget: Neovim.Neovim" "%FOUND_NVIM_PATH%"
exit /b 0

:find_nvim_011
call :run_tool_finder "nvim" "Neovim 0.11 or newer" "FOUND_NVIM_PATH" "%~1"
exit /b %ERRORLEVEL%

:need_jdk
set "JDK_JUST_INSTALLED=0"
call :find_javac_21
if not errorlevel 1 goto jdk_ready
if "%CHECK_ONLY%"=="1" (
    call :print_missing "JDK 21 or newer"
    exit /b 0
)
call :install_or_upgrade_winget "EclipseAdoptium.Temurin.21.JDK" "JDK" "Winget.JDK"
if errorlevel 1 exit /b 1
call :find_javac_21 quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] JDK 21 or newer was not found after winget install.
    exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="0" (
    call :record_component_path "Winget.JDK" "%FOUND_JAVAC_PATH%"
    if errorlevel 1 exit /b 1
    call :finish_pending_winget "EclipseAdoptium.Temurin.21.JDK" "Winget.JDK"
    if errorlevel 1 exit /b 1
)
set "JDK_JUST_INSTALLED=1"
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
if "%JDK_JUST_INSTALLED%"=="1" call :print_installed "JDK via winget: EclipseAdoptium.Temurin.21.JDK" "%FOUND_JAVAC_PATH%"
exit /b 0

:find_javac_21
call :run_tool_finder "javac" "JDK 21 or newer" "FOUND_JAVAC_PATH" "%~1"
exit /b %ERRORLEVEL%

:install_or_upgrade_winget
call :require_winget
if errorlevel 1 exit /b 1
set "PACKAGE_PREEXISTED=0"
call :winget_has_package "%~1"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
if "%PACKAGE_PREEXISTED%"=="0" (
    call :begin_pending_winget "%~1" "%~3"
    if errorlevel 1 exit /b 1
)
if "%PACKAGE_PREEXISTED%"=="1" (
    set "INSTALL_CMD=!WINGET! upgrade --id %~1 %WINGET_QUIET_ARGS%"
) else (
    set "INSTALL_CMD=!WINGET! install --id %~1 %WINGET_QUIET_ARGS%"
)
call :run_install_spinner "%~2 via winget: %~1" "" "%VISIBLE_TEMP%\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" (
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
    exit /b 1
)
call :capture_winget_install_result "%~1" "%~3"
if errorlevel 1 exit /b 1
call :refresh_path
exit /b 0

:print_found
echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1
exit /b 0

:print_installed
if "%VERBOSE%"=="1" if not "%~2"=="" (
    echo [%ESC%[38;5;114mINSTALLED%ESC%[0m] %~1: %~2
    exit /b 0
)
echo [%ESC%[38;5;114mINSTALLED%ESC%[0m] %~1
exit /b 0

:print_success_status
echo [%ESC%[38;5;114m%~1%ESC%[0m] %~2
exit /b 0

:print_found_path
if "%VERBOSE%"=="1" (
    echo [%ESC%[38;5;114mFOUND%ESC%[0m] %~1: %~2
) else (
    call :print_found "%~1"
)
exit /b 0

:print_found_where
call :print_found "%~1"
exit /b 0

:find_command
set "%~2="
exit /b 1

:print_missing
set /A MISSING_COUNT+=1
echo [%ESC%[33mMISSING%ESC%[0m] %~1
exit /b 0

:search_command
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
setlocal EnableExtensions EnableDelayedExpansion
set "SEARCH_LABEL=%~1"
set "SEARCH_QUIET=%~4"
set "SEARCH_SUCCESS=%~5"
if not defined SEARCH_SUCCESS set "SEARCH_SUCCESS=FOUND"
set "SEARCH_EXPECTED=%~6"
set "SEARCH_SHOW_ERRORS=%~7"
if /i "%~2"=="@env" (
    set "SEARCH_COMMAND=!SEARCH_COMMAND_INPUT!"
) else (
    set "SEARCH_COMMAND=%~2"
)
set "SEARCH_RESULT_FILE=%EXEC_TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.txt"
set "SEARCH_PS=%EXEC_TEMP%\cp_setup_search_%RANDOM%_%RANDOM%.ps1"
> "%SEARCH_PS%" echo $label = $env:SEARCH_LABEL
>> "%SEARCH_PS%" echo . $env:PROCESS_TREE_PS
>> "%SEARCH_PS%" echo $command = $env:SEARCH_COMMAND
>> "%SEARCH_PS%" echo $output = $env:SEARCH_RESULT_FILE
>> "%SEARCH_PS%" echo $quiet = $env:SEARCH_QUIET -ieq 'quiet'
>> "%SEARCH_PS%" echo $successText = $env:SEARCH_SUCCESS
>> "%SEARCH_PS%" echo $expected = $env:SEARCH_EXPECTED
>> "%SEARCH_PS%" echo $showErrors = $env:SEARCH_SHOW_ERRORS -ieq 'show-errors'
>> "%SEARCH_PS%" echo $esc = [char]27
>> "%SEARCH_PS%" echo $cr = [char]13
>> "%SEARCH_PS%" echo $clear = $esc + '[2K'
>> "%SEARCH_PS%" echo $searching = '[' + $esc + '[38;5;183mSEARCHING' + $esc + '[0m]'
>> "%SEARCH_PS%" echo $success = '[' + $esc + '[38;5;114m' + $successText + $esc + '[0m]'
>> "%SEARCH_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SEARCH_PS%" echo $wrapper = Join-Path $env:EXEC_TEMP ^('cp_setup_search_' + [guid]::NewGuid^(^).ToString^('N'^) + '.cmd'^)
>> "%SEARCH_PS%" echo $q = [char]34
>> "%SEARCH_PS%" echo $runLine = [string]^('call ' + $command + ' 1^>' + $q + $output + $q + ' 2^>nul'^)
>> "%SEARCH_PS%" echo [IO.File]::WriteAllLines^($wrapper, @^('@echo off',$runLine,'exit /b %%ERRORLEVEL%%'^)^)
>> "%SEARCH_PS%" echo $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SEARCH_PS%" echo $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru
>> "%SEARCH_PS%" echo $i = 0
>> "%SEARCH_PS%" echo $started = [Diagnostics.Stopwatch]::StartNew^(^)
>> "%SEARCH_PS%" echo $timedOut = $false
>> "%SEARCH_PS%" echo while ^(-not $process.HasExited^) { if ^(-not $quiet^) { Write-Host -NoNewline ^($cr + $clear + $searching + ' ' + $frames[$i %% $frames.Count] + ' ' + $label^); [Console]::Out.Flush^(^) }; if ^($started.Elapsed.TotalSeconds -ge 120^) { $timedOut = $true; Stop-CpProcessTree $process $env:TASKKILL_EXE; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SEARCH_PS%" echo if ^($timedOut^) { $exitCode = 124 } elseif ^(-not $process.WaitForExit^(1000^)^) { Stop-CpProcessTree $process $env:TASKKILL_EXE; $exitCode=124 } else { $exitCode = $process.ExitCode }
>> "%SEARCH_PS%" echo $items = @^(if ^(Test-Path -LiteralPath $output^) { Get-Content -LiteralPath $output -ErrorAction SilentlyContinue }^)
>> "%SEARCH_PS%" echo Remove-Item -LiteralPath $wrapper -Force -ErrorAction SilentlyContinue
>> "%SEARCH_PS%" echo if ^(-not ^(Test-Path -LiteralPath $output^)^) { [IO.File]::WriteAllText^($output,''^) }
>> "%SEARCH_PS%" echo if (-not $quiet) {
>> "%SEARCH_PS%" echo     $matchesExpected = [string]::IsNullOrEmpty($expected) -or ($items.Count -and $items[0] -ieq $expected)
>> "%SEARCH_PS%" echo     if ($exitCode -eq 0 -and $matchesExpected) { $suffix = ''; if ($env:VERBOSE -eq '1' -and $items.Count -and [string]::IsNullOrEmpty($expected)) { $suffix = ': ' + $items[0] }; Write-Host ($cr + $clear + $success + ' ' + $label + $suffix) } else { Write-Host -NoNewline ($cr + $clear); if ($exitCode -ne 0 -and $showErrors -and $items.Count) { Write-Host ($items -join [Environment]::NewLine) } }
>> "%SEARCH_PS%" echo }
>> "%SEARCH_PS%" echo exit $exitCode
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SEARCH_PS%"
set "SEARCH_EXIT=%ERRORLEVEL%"
set "SEARCH_VALUE="
for /F "usebackq delims=" %%P in ("%SEARCH_RESULT_FILE%") do if not defined SEARCH_VALUE set "SEARCH_VALUE=%%P"
del "%SEARCH_PS%" >nul 2>nul
del "%SEARCH_RESULT_FILE%" >nul 2>nul
if "%SEARCH_EXIT%"=="124" (
    endlocal & set "%~3=%SEARCH_VALUE%" & set "CP_SETUP_TIMEOUT_OCCURRED=1" & exit /b 124
)
endlocal & set "%~3=%SEARCH_VALUE%" & exit /b %SEARCH_EXIT%

:internal_ac_library_status
setlocal EnableExtensions EnableDelayedExpansion
if exist "%ROOT%\.git" (
    if not defined FOUND_GIT_PATH call :find_git quiet
    if defined FOUND_GIT_PATH call :git_ready
)
call :ac_library_needs_update
set "AC_LIBRARY_CHECK_EXIT=!ERRORLEVEL!"
if not "!AC_LIBRARY_CHECK_EXIT!"=="0" (
    if defined AC_LIBRARY_ERROR echo [%ESC%[31mFAILED%ESC%[0m] !AC_LIBRARY_ERROR!
    call :cleanup_secure_temp
    exit /b !AC_LIBRARY_CHECK_EXIT!
)
:internal_ac_library_manage
if /i not "%~2"=="manage" goto internal_ac_library_output
if /i "!AC_LIBRARY_STATE!"=="MISSING" call :check_empty_acl_target
if errorlevel 1 (
    if defined AC_LIBRARY_ERROR echo [%ESC%[31mFAILED%ESC%[0m] !AC_LIBRARY_ERROR!
    call :cleanup_secure_temp
    exit /b 1
)
if exist "%ROOT%\.git" goto internal_ac_library_output
if /i "!AC_LIBRARY_STATE!"=="OUTDATED" call :check_managed_acl_archive
if errorlevel 1 (
    if defined AC_LIBRARY_ERROR echo [%ESC%[31mFAILED%ESC%[0m] !AC_LIBRARY_ERROR!
    call :cleanup_secure_temp
    exit /b 1
)
:internal_ac_library_output
echo !AC_LIBRARY_STATE!
call :cleanup_secure_temp
exit /b 0

:probe_ac_library
set "SEARCH_COMMAND_INPUT=call "%INSTALL_SCRIPT%" --internal-ac-library-status %~1"
call :search_command "ac-library" "@env" "AC_LIBRARY_STATE" "" "UP TO DATE" "CURRENT" "show-errors"
set "AC_LIBRARY_CHECK_EXIT=%ERRORLEVEL%"
if not "%AC_LIBRARY_CHECK_EXIT%"=="0" exit /b 1
if /i "%AC_LIBRARY_STATE%"=="CURRENT" exit /b 0
if /i "%AC_LIBRARY_STATE%"=="OUTDATED" exit /b 0
if /i "%AC_LIBRARY_STATE%"=="MISSING" exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] ac-library inspection returned an invalid state.
exit /b 1

:check_ac_library
call :probe_ac_library
if errorlevel 1 exit /b 1
if /i "%AC_LIBRARY_STATE%"=="CURRENT" exit /b 0
call :print_missing "ac-library at pinned commit %ACL_COMMIT%"
exit /b 0

:ensure_ac_library
call :probe_ac_library manage
if errorlevel 1 exit /b 1
if /i "%AC_LIBRARY_STATE%"=="CURRENT" (
    if not exist "%ROOT%\.git" (
        call :handoff_ac_library_ownership "1"
        if errorlevel 1 exit /b 1
        call :compute_ac_library_tree_hash "%ROOT%\libraries\ac-library"
        if errorlevel 1 exit /b 1
        call :record_acl_archive_hash
        if errorlevel 1 exit /b 1
    ) else (
        call :handoff_ac_library_ownership "0"
        if errorlevel 1 exit /b 1
    )
    call :verify_ac_library_target_owner
    if errorlevel 1 exit /b 1
    exit /b 0
)
if /i "%AC_LIBRARY_STATE%"=="OUTDATED" (
    set "AC_LIBRARY_ACTION=UPDATING"
    set "AC_LIBRARY_SUCCESS=UPDATED"
) else (
    set "AC_LIBRARY_ACTION=INSTALLING"
    set "AC_LIBRARY_SUCCESS=INSTALLED"
)
if exist "%ROOT%\.git" (
    call :update_ac_library "!AC_LIBRARY_ACTION!" "!AC_LIBRARY_SUCCESS!"
) else (
    call :bootstrap_ac_library_archive "!AC_LIBRARY_ACTION!" "!AC_LIBRARY_SUCCESS!"
)
exit /b !ERRORLEVEL!

:ac_library_needs_update
set "AC_LIBRARY_ERROR="
set "AC_LIBRARY_STATE=MISSING"
set "AC_LIBRARY_PATH=%ROOT%\libraries\ac-library"
if not exist "%ROOT%\.git" (
    if not exist "%AC_LIBRARY_PATH%\expander.py" exit /b 0
    set "AC_LIBRARY_STATE=OUTDATED"
    call :compute_ac_library_tree_hash "%AC_LIBRARY_PATH%"
    if errorlevel 1 (
        set "AC_LIBRARY_ERROR=Could not calculate the ac-library integrity hash."
        exit /b 1
    )
    if /i not "!AC_LIBRARY_TREE_ACTUAL!"=="!ACL_TREE_HASH!" exit /b 0
    set "AC_LIBRARY_STATE=CURRENT"
    exit /b 0
)
if not defined FOUND_GIT_PATH (
    set "AC_LIBRARY_ERROR=Git is unavailable while checking ac-library."
    exit /b 1
)
if not exist "%ROOT%\.gitmodules" (
    set "AC_LIBRARY_ERROR=.gitmodules is missing while checking ac-library."
    exit /b 1
)
set "AC_LIBRARY_EXPECTED="
set "AC_LIBRARY_ENTRY_MODE="
set "AC_LIBRARY_ENTRY_TYPE="
set "AC_LIBRARY_ENTRY_PATH="
set "AC_GIT_OUTPUT=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.txt"
set "AC_GIT_ERROR=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "core.hooksPath=NUL" -C "%ROOT%" ls-tree HEAD -- libraries/ac-library"
set "SILENT_STDOUT=%AC_GIT_OUTPUT%"
set "SILENT_STDERR=%AC_GIT_ERROR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "AC_GIT_EXIT=!ERRORLEVEL!"
del "%AC_GIT_ERROR%" >nul 2>nul
if not "!AC_GIT_EXIT!"=="0" (
    del "%AC_GIT_OUTPUT%" >nul 2>nul
    set "AC_LIBRARY_ERROR=Git could not inspect the repository ac-library entry."
    exit /b 1
)
for /F "usebackq tokens=1,2,3,*" %%A in ("%AC_GIT_OUTPUT%") do if not defined AC_LIBRARY_EXPECTED (
    set "AC_LIBRARY_ENTRY_MODE=%%A"
    set "AC_LIBRARY_ENTRY_TYPE=%%B"
    set "AC_LIBRARY_EXPECTED=%%C"
    set "AC_LIBRARY_ENTRY_PATH=%%D"
)
del "%AC_GIT_OUTPUT%" >nul 2>nul
if not defined AC_LIBRARY_EXPECTED (
    set "AC_LIBRARY_ERROR=The repository does not record an ac-library gitlink."
    exit /b 1
)
if not "!AC_LIBRARY_ENTRY_MODE!"=="160000" (
    set "AC_LIBRARY_ERROR=The repository does not record an ac-library gitlink."
    exit /b 1
)
if /i not "!AC_LIBRARY_ENTRY_TYPE!"=="commit" (
    set "AC_LIBRARY_ERROR=The repository does not record an ac-library gitlink."
    exit /b 1
)
if /i not "!AC_LIBRARY_ENTRY_PATH!"=="libraries/ac-library" (
    set "AC_LIBRARY_ERROR=The repository does not record an ac-library gitlink."
    exit /b 1
)
if /i not "%AC_LIBRARY_EXPECTED%"=="%ACL_COMMIT%" (
    set "AC_LIBRARY_ERROR=install.bat ACL_COMMIT does not match the repository gitlink."
    exit /b 1
)
if not exist "%AC_LIBRARY_PATH%\.git" exit /b 0
if exist "%AC_LIBRARY_PATH%\.git\" exit /b 0
set "AC_LIBRARY_TOPLEVEL="
set "AC_GIT_OUTPUT=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.txt"
set "AC_GIT_ERROR=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "safe.directory=%AC_LIBRARY_PATH%" -c "core.hooksPath=NUL" -C "%AC_LIBRARY_PATH%" rev-parse --show-toplevel"
set "SILENT_STDOUT=%AC_GIT_OUTPUT%"
set "SILENT_STDERR=%AC_GIT_ERROR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "AC_GIT_EXIT=!ERRORLEVEL!"
del "%AC_GIT_ERROR%" >nul 2>nul
if not "!AC_GIT_EXIT!"=="0" (
    del "%AC_GIT_OUTPUT%" >nul 2>nul
    exit /b 0
)
for /F "usebackq delims=" %%P in ("%AC_GIT_OUTPUT%") do if not defined AC_LIBRARY_TOPLEVEL set "AC_LIBRARY_TOPLEVEL=%%P"
del "%AC_GIT_OUTPUT%" >nul 2>nul
if not defined AC_LIBRARY_TOPLEVEL exit /b 0
for %%I in ("%AC_LIBRARY_TOPLEVEL%") do set "AC_LIBRARY_TOPLEVEL=%%~fI"
if /i not "%AC_LIBRARY_TOPLEVEL%"=="%AC_LIBRARY_PATH%" exit /b 0
set "AC_LIBRARY_SUPERPROJECT="
set "AC_GIT_OUTPUT=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.txt"
set "AC_GIT_ERROR=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "safe.directory=%AC_LIBRARY_PATH%" -c "core.hooksPath=NUL" -C "%AC_LIBRARY_PATH%" rev-parse --show-superproject-working-tree"
set "SILENT_STDOUT=%AC_GIT_OUTPUT%"
set "SILENT_STDERR=%AC_GIT_ERROR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "AC_GIT_EXIT=!ERRORLEVEL!"
del "%AC_GIT_ERROR%" >nul 2>nul
if not "!AC_GIT_EXIT!"=="0" (
    del "%AC_GIT_OUTPUT%" >nul 2>nul
    exit /b 0
)
for /F "usebackq delims=" %%P in ("%AC_GIT_OUTPUT%") do if not defined AC_LIBRARY_SUPERPROJECT set "AC_LIBRARY_SUPERPROJECT=%%P"
del "%AC_GIT_OUTPUT%" >nul 2>nul
if not defined AC_LIBRARY_SUPERPROJECT exit /b 0
for %%I in ("%AC_LIBRARY_SUPERPROJECT%") do set "AC_LIBRARY_SUPERPROJECT=%%~fI"
if /i not "%AC_LIBRARY_SUPERPROJECT%"=="%ROOT%" exit /b 0
set "AC_LIBRARY_LOCAL="
set "AC_GIT_OUTPUT=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.txt"
set "AC_GIT_ERROR=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "safe.directory=%AC_LIBRARY_PATH%" -c "core.hooksPath=NUL" -C "%AC_LIBRARY_PATH%" rev-parse HEAD"
set "SILENT_STDOUT=%AC_GIT_OUTPUT%"
set "SILENT_STDERR=%AC_GIT_ERROR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "AC_GIT_EXIT=!ERRORLEVEL!"
del "%AC_GIT_ERROR%" >nul 2>nul
if not "!AC_GIT_EXIT!"=="0" (
    del "%AC_GIT_OUTPUT%" >nul 2>nul
    exit /b 0
)
for /F "usebackq delims=" %%P in ("%AC_GIT_OUTPUT%") do if not defined AC_LIBRARY_LOCAL set "AC_LIBRARY_LOCAL=%%P"
del "%AC_GIT_OUTPUT%" >nul 2>nul
if not defined AC_LIBRARY_LOCAL exit /b 0
set "AC_LIBRARY_STATE=OUTDATED"
set "AC_LIBRARY_STATUS_FILE=%EXEC_TEMP%\cp_setup_acl_status_%RANDOM%_%RANDOM%.txt"
set "AC_GIT_ERROR=%EXEC_TEMP%\cp_setup_acl_git_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "safe.directory=%AC_LIBRARY_PATH%" -c "core.hooksPath=NUL" -C "%AC_LIBRARY_PATH%" status --porcelain --untracked-files=all"
set "SILENT_STDOUT=%AC_LIBRARY_STATUS_FILE%"
set "SILENT_STDERR=%AC_GIT_ERROR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "AC_LIBRARY_STATUS_EXIT=!ERRORLEVEL!"
del "%AC_GIT_ERROR%" >nul 2>nul
if not "!AC_LIBRARY_STATUS_EXIT!"=="0" (
    del "%AC_LIBRARY_STATUS_FILE%" >nul 2>nul
    set "AC_LIBRARY_ERROR=Git could not inspect the ac-library working tree."
    exit /b 1
)
set "AC_LIBRARY_DIRTY="
for /F "usebackq delims=" %%P in ("%AC_LIBRARY_STATUS_FILE%") do if not defined AC_LIBRARY_DIRTY set "AC_LIBRARY_DIRTY=%%P"
del "%AC_LIBRARY_STATUS_FILE%" >nul 2>nul
if defined AC_LIBRARY_DIRTY (
    set "AC_LIBRARY_ERROR=ac-library has local changes; restore the pinned submodule before continuing."
    exit /b 1
)
if /i not "%AC_LIBRARY_LOCAL%"=="%AC_LIBRARY_EXPECTED%" exit /b 0
if not exist "%AC_LIBRARY_PATH%\expander.py" (
    set "AC_LIBRARY_ERROR=The pinned ac-library checkout is incomplete."
    exit /b 1
)
set "AC_LIBRARY_STATE=CURRENT"
exit /b 0

:record_acl_archive_hash
if not defined AC_LIBRARY_TREE_ACTUAL (
    set "AC_LIBRARY_ERROR=Could not record ac-library source-archive ownership without an integrity hash."
    exit /b 1
)
set "ACL_PENDING_HASH=%AC_LIBRARY_TREE_ACTUAL%"
exit /b 0

:commit_pending_acl_archive_hash
if not defined ACL_PENDING_HASH exit /b 0
reg add "%STATE_KEY%" /v "Acl.SourceArchive.Hash" /t REG_SZ /d "%ACL_PENDING_HASH%" /f >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

:check_managed_acl_archive
set "AC_LIBRARY_MANAGED_HASH="
set "AC_STATE_OUTPUT=%EXEC_TEMP%\cp_setup_acl_state_%RANDOM%_%RANDOM%.txt"
"%REG_EXE%" query "%STATE_KEY%" /v "Acl.SourceArchive.Hash" > "%AC_STATE_OUTPUT%" 2>nul
for /F "tokens=2,*" %%A in ("%AC_STATE_OUTPUT%") do if /i "%%A"=="REG_SZ" set "AC_LIBRARY_MANAGED_HASH=%%B"
del "%AC_STATE_OUTPUT%" >nul 2>nul
if not defined AC_LIBRARY_MANAGED_HASH (
    set "AC_LIBRARY_ERROR=ac-library is outdated but is not recorded as setup-managed; preserve or remove it manually before continuing."
    exit /b 1
)
if /i not "%AC_LIBRARY_TREE_ACTUAL%"=="%AC_LIBRARY_MANAGED_HASH%" (
    set "AC_LIBRARY_ERROR=ac-library differs from the setup-managed source archive; restore local changes before updating it."
    exit /b 1
)
exit /b 0

:check_empty_acl_target
if not exist "%AC_LIBRARY_PATH%" exit /b 0
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$path=$env:AC_LIBRARY_PATH; if (-not (Test-Path -LiteralPath $path -PathType Container)) { exit 1 }; if (@(Get-ChildItem -LiteralPath $path -Force -ErrorAction Stop).Count -ne 0) { exit 1 }; exit 0" >nul 2>nul
if errorlevel 1 (
    set "AC_LIBRARY_ERROR=libraries\ac-library exists but is not an empty install target; preserve or remove its contents manually before continuing."
    exit /b 1
)
exit /b 0

:print_ac_library_check_error
if defined AC_LIBRARY_ERROR (
    echo [%ESC%[31mFAILED%ESC%[0m] %AC_LIBRARY_ERROR%
) else (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not verify ac-library.
)
exit /b 0

:update_ac_library
if not defined FOUND_GIT_PATH exit /b 1
if not exist "%ROOT%\.gitmodules" exit /b 1
set "AC_LIBRARY_CREATED=0"
call :ac_library_needs_update
if errorlevel 1 (
    call :print_ac_library_check_error
    exit /b 1
)
if /i "%AC_LIBRARY_STATE%"=="MISSING" (
    set "AC_LIBRARY_CREATED=1"
    call :check_empty_acl_target
)
if errorlevel 1 (
    call :print_ac_library_check_error
    exit /b 1
)
if /i "%AC_LIBRARY_STATE%"=="CURRENT" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library changed before its Git update started; run the installer again.
    exit /b 1
)
call :create_ac_library_medium_worker "git"
if errorlevel 1 exit /b 1
set "INSTALL_CMD="%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%AC_LIBRARY_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 900"
set "SPIN_TIMEOUT_SECONDS=910"
call :run_install_spinner "ac-library" "" "%VISIBLE_TEMP%\cp_setup_git.log" "%~1" "%~2" "1"
set "AC_LIBRARY_EXIT=!ERRORLEVEL!"
set "SPIN_TIMEOUT_SECONDS="
del "%AC_LIBRARY_WORKER_PS%" >nul 2>nul
set "AC_LIBRARY_WORKER_PS="
if not "!AC_LIBRARY_EXIT!"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library update via Git submodule failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_git.log
    exit /b 1
)
call :ac_library_needs_update
if errorlevel 1 (
    call :print_ac_library_check_error
    echo Log: %VISIBLE_TEMP%\cp_setup_git.log
    exit /b 1
)
if /i not "%AC_LIBRARY_STATE%"=="CURRENT" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library did not reach the pinned commit after checkout.
    exit /b 1
)
call :handoff_ac_library_ownership "%AC_LIBRARY_CREATED%"
if errorlevel 1 (
    >> "%EXEC_TEMP%\cp_setup_git.log" echo Could not hand off ac-library ownership to the invoking user.
    call :publish_component_log "cp_setup_git.log"
    exit /b 1
)
call :verify_ac_library_target_owner
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library files are not owned by the invoking user.
    exit /b 1
)
call :print_success_status "%~2" "ac-library"
exit /b 0

:handoff_ac_library_ownership
rem The repository is already a trusted user-owned boundary; no ACL handoff is performed.
exit /b 0

:check_env_paths
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
set "ENV_CHECK_WORKER=%EXEC_TEMP%\cp_setup_env_check_%RANDOM%_%RANDOM%.ps1"
set "ENV_CHECK_RUNNER=%EXEC_TEMP%\cp_setup_env_check_%RANDOM%_%RANDOM%.runner.ps1"
> "%ENV_CHECK_WORKER%" echo $ErrorActionPreference = 'Stop'
>> "%ENV_CHECK_WORKER%" echo function Normalize^([object]$value^) { if ^($null -eq $value^) { return '' }; ^([string]$value^).Trim^(^).TrimEnd^([char]92^) }
>> "%ENV_CHECK_WORKER%" echo $desired = @^((Join-Path $env:ROOT 'scripts'^).TrimEnd^([char]92^)^)
>> "%ENV_CHECK_WORKER%" echo foreach ^($exe in @^($env:FOUND_GIT_PATH,$env:FOUND_NVIM_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH^)^) { if ^($exe -and ^(Test-Path -LiteralPath $exe -PathType Leaf^)^) { $desired += Normalize ^(Split-Path -Parent $exe^) } }
>> "%ENV_CHECK_WORKER%" echo $desired = @^($desired ^| Where-Object { $_ } ^| Sort-Object -Unique^)
>> "%ENV_CHECK_WORKER%" echo $path = ^(Get-ItemProperty -LiteralPath $env:CP_SETUP_TARGET_ENV -Name Path -ErrorAction SilentlyContinue^).Path; if ^($null -eq $path^) { $path = '' }
>> "%ENV_CHECK_WORKER%" echo $parts = @^($path -split ';' ^| ForEach-Object { Normalize $_ } ^| Where-Object { $_ }^)
>> "%ENV_CHECK_WORKER%" echo $owned = @^(^(Get-ItemProperty -Path $env:CP_SETUP_TARGET_STATE -Name 'Path.Entries' -ErrorAction SilentlyContinue^).'Path.Entries' ^| ForEach-Object { Normalize $_ } ^| Where-Object { $_ }^)
>> "%ENV_CHECK_WORKER%" echo foreach ^($entry in $desired^) { if ^($parts -inotcontains $entry^) { exit 1 } }
>> "%ENV_CHECK_WORKER%" echo foreach ^($entry in $owned^) { if ^($desired -inotcontains $entry -or $parts -inotcontains $entry^) { exit 1 } }
>> "%ENV_CHECK_WORKER%" echo exit 0
> "%ENV_CHECK_RUNNER%" echo $ErrorActionPreference = 'Stop'
>> "%ENV_CHECK_RUNNER%" echo . $env:PROCESS_TREE_PS
>> "%ENV_CHECK_RUNNER%" echo $esc=[char]27; $cr=[char]13; $clear=$esc+'[2K'; $checking='['+$esc+'[38;5;183mCHECKING'+$esc+'[0m]'; $found='['+$esc+'[38;5;114mFOUND'+$esc+'[0m]'; $failed='['+$esc+'[31mFAILED'+$esc+'[0m]'
>> "%ENV_CHECK_RUNNER%" echo $process=Start-Process -FilePath $env:POWERSHELL_EXE -ArgumentList @^('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$env:ENV_CHECK_WORKER^) -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru
>> "%ENV_CHECK_RUNNER%" echo $frames=@^([char]92,'-','/','^|'^); $i=0; $clock=[Diagnostics.Stopwatch]::StartNew^(^); $timedOut=$false
>> "%ENV_CHECK_RUNNER%" echo while ^(-not $process.HasExited^) { Write-Host -NoNewline ^($cr+$clear+$checking+' '+$frames[$i %% $frames.Count]+' Environment paths'^); [Console]::Out.Flush^(^); if ^($clock.Elapsed.TotalSeconds -ge 30^) { $timedOut=$true; Stop-CpProcessTree $process $env:TASKKILL_EXE; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%ENV_CHECK_RUNNER%" echo if ^($timedOut^) { $exitCode=124 } elseif ^(-not $process.WaitForExit^(1000^)^) { Stop-CpProcessTree $process $env:TASKKILL_EXE; $exitCode=124 } else { $exitCode=$process.ExitCode }
>> "%ENV_CHECK_RUNNER%" echo if ^($exitCode -eq 0^) { Write-Host ^($cr+$clear+$found+' Environment paths'^) } else { Write-Host ^($cr+$clear+$failed+' Environment paths'^) }; exit $exitCode
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ENV_CHECK_RUNNER%"
set "ENV_CHECK_EXIT=%ERRORLEVEL%"
if "%ENV_CHECK_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%ENV_CHECK_WORKER%" "%ENV_CHECK_RUNNER%" >nul 2>nul
set "ENV_CHECK_WORKER="
set "ENV_CHECK_RUNNER="
exit /b %ENV_CHECK_EXIT%

:check_config_integrity
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$root=[IO.Path]::GetFullPath($env:ROOT).TrimEnd('\'); function SamePath($left,$right) { if (-not $left -or -not $right) { return $false }; return [IO.Path]::GetFullPath($left).TrimEnd('\') -ieq [IO.Path]::GetFullPath($right).TrimEnd('\') }; $key=$env:CP_SETUP_TARGET_STATE; $state=Get-ItemProperty -Path $key -ErrorAction SilentlyContinue; if ($null -eq $state -or -not (SamePath $state.'Install.Root' $root) -or $state.'Snapshot.Complete' -ne 1 -or $state.SchemaVersion -ne %STATE_SCHEMA% -or $state.'Config.Managed' -ne 1 -or $state.'Config.MutationStarted' -ne 1 -or $state.'Nvim.BootstrapStarted' -ne 1) { exit 1 }; $userEnv=Get-ItemProperty -LiteralPath $env:CP_SETUP_TARGET_ENV -ErrorAction SilentlyContinue; $xdg=$userEnv.XDG_CONFIG_HOME; $configuredRoot=$userEnv.CP_SETUP_ROOT; $python=$userEnv.CP_PYTHON; $gpp=$userEnv.CP_GPP; $javac=$userEnv.CP_JAVAC; $java=$userEnv.CP_JAVA; if (-not (SamePath $xdg $root) -or -not (SamePath $configuredRoot $root) -or -not (SamePath $python $env:CP_PYTHON) -or -not (SamePath $gpp $env:CP_GPP) -or -not (SamePath $javac $env:CP_JAVAC) -or -not (SamePath $java $env:CP_JAVA)) { exit 1 }; $macros=Join-Path $root 'scripts\cp_macros'; $command='doskey /macrofile=\"'+$macros+'\"'; $autoKey=Join-Path $env:CP_SETUP_TARGET_REGISTRY 'Software\Microsoft\Command Processor'; $autorun=(Get-ItemProperty -Path $autoKey -Name AutoRun -ErrorAction SilentlyContinue).AutoRun; if (-not $autorun -or $autorun.IndexOf($command,[StringComparison]::OrdinalIgnoreCase) -lt 0) { exit 1 }; exit 0"
exit /b %ERRORLEVEL%

:require_winget
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
set "WINGET="
set "WINGET_FINDER=%EXEC_TEMP%\cp_setup_find_winget_%RANDOM%_%RANDOM%.ps1"
set "WINGET_FINDER_OUT=%EXEC_TEMP%\cp_setup_find_winget_%RANDOM%_%RANDOM%.out"
set "WINGET_FINDER_ERR=%EXEC_TEMP%\cp_setup_find_winget_%RANDOM%_%RANDOM%.err"
> "%WINGET_FINDER%" echo $ErrorActionPreference = 'Stop'
>> "%WINGET_FINDER%" echo . $env:PROCESS_TREE_PS
>> "%WINGET_FINDER%" echo Import-Module ^(Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules\Appx\Appx.psd1'^) -Force -ErrorAction Stop
>> "%WINGET_FINDER%" echo $trusted = @^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^)
>> "%WINGET_FINDER%" echo $dangerous = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Modify -bor [Security.AccessControl.FileSystemRights]::FullControl -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%WINGET_FINDER%" echo function Get-Sid^($identity^) { try { $identity.Translate^([Security.Principal.SecurityIdentifier]^).Value } catch { $null } }
>> "%WINGET_FINDER%" echo function Test-ProtectedAcl^([string]$path^) {
>> "%WINGET_FINDER%" echo     try { $acl = Get-Acl -LiteralPath $path -ErrorAction Stop; $owner = Get-Sid $acl.Owner; if ^($trusted -notcontains $owner^) { return $false }; foreach ^($ace in $acl.Access^) { if ^($ace.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and $ace.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::InheritOnly -and ^($ace.FileSystemRights -band $dangerous^) -ne 0^) { $sid = Get-Sid $ace.IdentityReference; if ^($trusted -notcontains $sid^) { return $false } } }; return $true } catch { return $false }
>> "%WINGET_FINDER%" echo }
>> "%WINGET_FINDER%" echo function Test-ProtectedCandidate^([string]$candidate, [string]$windowsApps^) {
>> "%WINGET_FINDER%" echo     try { $full = [IO.Path]::GetFullPath^($candidate^); $root = [IO.Path]::GetFullPath^($windowsApps^).TrimEnd^([char]92^); if ^(-not $full.StartsWith^($root + [char]92, [StringComparison]::OrdinalIgnoreCase^)^) { return $false }; $current = $root; if ^(-not ^(Test-Path -LiteralPath $current -PathType Container^) -or ^(^(Get-Item -LiteralPath $current -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^) -or -not ^(Test-ProtectedAcl $current^)^) { return $false }; foreach ^($part in $full.Substring^($root.Length + 1^).Split^([char]92, [StringSplitOptions]::RemoveEmptyEntries^)^) { $current = Join-Path $current $part; if ^(-not ^(Test-Path -LiteralPath $current^) -or ^(^(Get-Item -LiteralPath $current -Force^).Attributes -band [IO.FileAttributes]::ReparsePoint^) -or -not ^(Test-ProtectedAcl $current^)^) { return $false } }; return ^(Test-Path -LiteralPath $full -PathType Leaf^) } catch { return $false }
>> "%WINGET_FINDER%" echo }
>> "%WINGET_FINDER%" echo $programFiles = [Environment]::GetFolderPath^([Environment+SpecialFolder]::ProgramFiles^)
>> "%WINGET_FINDER%" echo $windowsApps = Join-Path $programFiles 'WindowsApps'
>> "%WINGET_FINDER%" echo if ^($env:CP_SETUP_PRIVILEGED -eq '1'^) { $packages = @^(Appx\Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction Stop^) } else { $packages = @^(Appx\Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction Stop^) }
>> "%WINGET_FINDER%" echo $packages = @^($packages ^| Where-Object { $_.Name -eq 'Microsoft.DesktopAppInstaller' -and $_.PublisherId -eq '8wekyb3d8bbwe' -and $_.PackageFamilyName -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -and ^([string]$_.SignatureKind -eq 'Store' -or [string]$_.SignatureKind -eq 'System'^) } ^| Sort-Object Version -Descending^)
>> "%WINGET_FINDER%" echo foreach ^($package in $packages^) {
>> "%WINGET_FINDER%" echo     $candidate = Join-Path $package.InstallLocation 'winget.exe'
>> "%WINGET_FINDER%" echo     if ^(-not ^(Test-ProtectedCandidate $candidate $windowsApps^)^) { continue }
>> "%WINGET_FINDER%" echo     $stdout = Join-Path $env:EXEC_TEMP ^('cp_setup_winget_version_' + [guid]::NewGuid^(^).ToString^('N'^) + '.out'^)
>> "%WINGET_FINDER%" echo     $stderr = $stdout + '.err'
>> "%WINGET_FINDER%" echo     try { $process = Start-Process -FilePath $candidate -ArgumentList '--version' -WorkingDirectory ^(Split-Path -Parent $candidate^) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -ErrorAction Stop; if ^(-not $process.WaitForExit^(15000^)^) { Stop-CpProcessTree $process $env:TASKKILL_EXE; exit 124 }; if ^($process.ExitCode -eq 0^) { Write-Output ^([IO.Path]::GetFullPath^($candidate^)^); exit 0 } } finally { Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue }
>> "%WINGET_FINDER%" echo }
>> "%WINGET_FINDER%" echo exit 1
set "SILENT_COMMAND="%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%WINGET_FINDER%""
set "SILENT_STDOUT=%WINGET_FINDER_OUT%"
set "SILENT_STDERR=%WINGET_FINDER_ERR%"
set "SILENT_TIMEOUT_SECONDS=45"
call :run_silent_timeout
set "WINGET_FIND_EXIT=%ERRORLEVEL%"
if "%WINGET_FIND_EXIT%"=="0" for /F "usebackq delims=" %%P in ("%WINGET_FINDER_OUT%") do if not defined WINGET set "WINGET=%%P"
del "%WINGET_FINDER%" >nul 2>nul
del "%WINGET_FINDER_OUT%" >nul 2>nul
del "%WINGET_FINDER_ERR%" >nul 2>nul
if defined WINGET (
    for %%I in ("%WINGET%") do set "PATH=%%~dpI;%PATH%"
    exit /b 0
)
echo [%ESC%[31mFAILED%ESC%[0m] winget was not found.
echo Install or update App Installer from Microsoft Store, open a new cmd.exe, then rerun this installer.
echo Store shortcut: start ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1
exit /b 1

:prepare_process_tree_helper
if defined PROCESS_TREE_PS if exist "%PROCESS_TREE_PS%" exit /b 0
set "PROCESS_TREE_PS=%EXEC_TEMP%\cp_setup_process_tree_%RANDOM%_%RANDOM%.ps1"
> "%PROCESS_TREE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%PROCESS_TREE_PS%" echo $native=[Text.Encoding]::UTF8.GetString^([Convert]::FromBase64String^($env:CP_PROCESS_TREE_NATIVE_BASE64^)^)
>> "%PROCESS_TREE_PS%" echo Add-Type -TypeDefinition $native -Language CSharp -ErrorAction Stop ^| Out-Null
>> "%PROCESS_TREE_PS%" echo function Get-CpProcessTree^([Diagnostics.Process]$root^) { $result=[Collections.Generic.List[Diagnostics.Process]]::new^(^); foreach ^($pidValue in [CpSetupProcessTree]::Snapshot^($root.Id^)^) { try { $candidate=[Diagnostics.Process]::GetProcessById^($pidValue^); [void]$candidate.StartTime; $result.Add^($candidate^) } catch {} }; @^($result^) }
>> "%PROCESS_TREE_PS%" echo function Stop-CpProcessTree^([Diagnostics.Process]$root,[string]$taskkill^) { $members=@^(Get-CpProcessTree $root^); $killer=Start-Process -FilePath $taskkill -ArgumentList @^('/PID',[string]$root.Id,'/T','/F'^) -WindowStyle Hidden -PassThru -ErrorAction Stop; if ^(-not $killer.WaitForExit^(10000^)^) { try { $killer.Kill^(^) } catch {}; [void]$killer.WaitForExit^(1000^) }; $killer.Dispose^(^); $deadline=[DateTime]::UtcNow.AddSeconds^(5^); foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $remaining=[Math]::Max^(0,[int]^($deadline.Subtract^([DateTime]::UtcNow^).TotalMilliseconds^)^); if ^($remaining -gt 0^) { [void]$member.WaitForExit^($remaining^) } } } catch {} }; foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $member.Kill^(^) } } catch {} }; $verifyDeadline=[DateTime]::UtcNow.AddSeconds^(2^); foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $remaining=[Math]::Max^(0,[int]^($verifyDeadline.Subtract^([DateTime]::UtcNow^).TotalMilliseconds^)^); if ^($remaining -gt 0^) { [void]$member.WaitForExit^($remaining^) } }; if ^(-not $member.HasExited^) { throw ^('Process-tree survivor: '+$member.Id^) } } finally { $member.Dispose^(^) } } }
if not exist "%PROCESS_TREE_PS%" exit /b 1
exit /b 0

:winget_has_package
call :require_winget
if errorlevel 1 exit /b 2
set "WINGET_LIST=%EXEC_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.txt"
set "WINGET_LIST_ERR=%EXEC_TEMP%\cp_setup_winget_list_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%WINGET%" list --id %~1 --exact --source winget --scope machine --disable-interactivity"
set "SILENT_STDOUT=%WINGET_LIST%"
set "SILENT_STDERR=%WINGET_LIST_ERR%"
set "SILENT_TIMEOUT_SECONDS=120"
call :run_silent_timeout
set "WINGET_QUERY_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST_ERR%" >nul 2>nul
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
set "WINGET_LIST_EXIT=%ERRORLEVEL%"
del "%WINGET_LIST%" >nul 2>nul
exit /b %WINGET_LIST_EXIT%

:run_silent_timeout
set "SILENT_PS=%EXEC_TEMP%\cp_setup_silent_%RANDOM%_%RANDOM%.ps1"
> "%SILENT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SILENT_PS%" echo $command = [string]$env:SILENT_COMMAND
>> "%SILENT_PS%" echo $stdout = [string]$env:SILENT_STDOUT
>> "%SILENT_PS%" echo $stderr = [string]$env:SILENT_STDERR
>> "%SILENT_PS%" echo [int]$timeoutSeconds = 0
>> "%SILENT_PS%" echo if ^(-not [int]::TryParse^($env:SILENT_TIMEOUT_SECONDS, [ref]$timeoutSeconds^) -or $timeoutSeconds -lt 1^) { $timeoutSeconds = 120 }
>> "%SILENT_PS%" echo $wrapper = Join-Path $env:EXEC_TEMP ^('cp_setup_silent_' + [guid]::NewGuid^(^).ToString^('N'^) + '.cmd'^)
>> "%SILENT_PS%" echo $q = [char]34
>> "%SILENT_PS%" echo $runLine = [string]^('call ' + $command + ' 1^>' + $q + $stdout + $q + ' 2^>' + $q + $stderr + $q^)
>> "%SILENT_PS%" echo [IO.File]::WriteAllLines^($wrapper, @^('@echo off',$runLine,'exit /b %%ERRORLEVEL%%'^)^)
>> "%SILENT_PS%" echo $native=[Text.Encoding]::UTF8.GetString^([Convert]::FromBase64String^('dXNpbmcgU3lzdGVtOwp1c2luZyBTeXN0ZW0uQ29sbGVjdGlvbnMuR2VuZXJpYzsKdXNpbmcgU3lzdGVtLkNvbXBvbmVudE1vZGVsOwp1c2luZyBTeXN0ZW0uUnVudGltZS5JbnRlcm9wU2VydmljZXM7CnB1YmxpYyBzdGF0aWMgY2xhc3MgQ3BTZXR1cFByb2Nlc3NUcmVlIHsKIGNvbnN0IHVpbnQgU25hcHNob3RQcm9jZXNzZXM9MjsKIHN0YXRpYyByZWFkb25seSBJbnRQdHIgSW52YWxpZEhhbmRsZT1uZXcgSW50UHRyKC0xKTsKIFtTdHJ1Y3RMYXlvdXQoTGF5b3V0S2luZC5TZXF1ZW50aWFsLENoYXJTZXQ9Q2hhclNldC5Vbmljb2RlKV0KIHN0cnVjdCBFbnRyeSB7CiAgcHVibGljIHVpbnQgU2l6ZSxVc2FnZSxQcm9jZXNzSWQ7CiAgcHVibGljIFVJbnRQdHIgRGVmYXVsdEhlYXBJZDsKICBwdWJsaWMgdWludCBNb2R1bGVJZCxUaHJlYWRzLFBhcmVudFByb2Nlc3NJZDsKICBwdWJsaWMgaW50IEJhc2VQcmlvcml0eTsKICBwdWJsaWMgdWludCBGbGFnczsKICBbTWFyc2hhbEFzKFVubWFuYWdlZFR5cGUuQnlWYWxUU3RyLFNpemVDb25zdD0yNjApXSBwdWJsaWMgc3RyaW5nIEV4ZUZpbGU7CiB9CiBbRGxsSW1wb3J0KCJrZXJuZWwzMi5kbGwiLFNldExhc3RFcnJvcj10cnVlKV0gc3RhdGljIGV4dGVybiBJbnRQdHIgQ3JlYXRlVG9vbGhlbHAzMlNuYXBzaG90KHVpbnQgZmxhZ3MsdWludCBwcm9jZXNzSWQpOwogW0RsbEltcG9ydCgia2VybmVsMzIuZGxsIixDaGFyU2V0PUNoYXJTZXQuVW5pY29kZSxTZXRMYXN0RXJyb3I9dHJ1ZSldIHN0YXRpYyBleHRlcm4gYm9vbCBQcm9jZXNzMzJGaXJzdFcoSW50UHRyIHNuYXBzaG90LHJlZiBFbnRyeSBlbnRyeSk7CiBbRGxsSW1wb3J0KCJrZXJuZWwzMi5kbGwiLENoYXJTZXQ9Q2hhclNldC5Vbmljb2RlLFNldExhc3RFcnJvcj10cnVlKV0gc3RhdGljIGV4dGVybiBib29sIFByb2Nlc3MzMk5leHRXKEludFB0ciBzbmFwc2hvdCxyZWYgRW50cnkgZW50cnkpOwogW0RsbEltcG9ydCgia2VybmVsMzIuZGxsIildIHN0YXRpYyBleHRlcm4gYm9vbCBDbG9zZUhhbmRsZShJbnRQdHIgaGFuZGxlKTsKIHB1YmxpYyBzdGF0aWMgaW50W10gU25hcHNob3QoaW50IHJvb3QpIHsKICBJbnRQdHIgc25hcHNob3Q9Q3JlYXRlVG9vbGhlbHAzMlNuYXBzaG90KFNuYXBzaG90UHJvY2Vzc2VzLDApOwogIGlmKHNuYXBzaG90PT1JbnZhbGlkSGFuZGxlKXRocm93IG5ldyBXaW4zMkV4Y2VwdGlvbihNYXJzaGFsLkdldExhc3RXaW4zMkVycm9yKCksIkNyZWF0ZVRvb2xoZWxwMzJTbmFwc2hvdCIpOwogIHRyeSB7CiAgIHZhciBjaGlsZHJlbj1uZXcgRGljdGlvbmFyeTxpbnQsTGlzdDxpbnQ+PigpOwogICBFbnRyeSBlbnRyeT1uZXcgRW50cnkoKTtlbnRyeS5TaXplPSh1aW50KU1hcnNoYWwuU2l6ZU9mKHR5cGVvZihFbnRyeSkpOwogICBpZihQcm9jZXNzMzJGaXJzdFcoc25hcHNob3QscmVmIGVudHJ5KSlkb3sKICAgIGludCBwYXJlbnQ9dW5jaGVja2VkKChpbnQpZW50cnkuUGFyZW50UHJvY2Vzc0lkKTsKICAgIExpc3Q8aW50PiBsaXN0O2lmKCFjaGlsZHJlbi5UcnlHZXRWYWx1ZShwYXJlbnQsb3V0IGxpc3QpKXtsaXN0PW5ldyBMaXN0PGludD4oKTtjaGlsZHJlbi5BZGQocGFyZW50LGxpc3QpO30KICAgIGxpc3QuQWRkKHVuY2hlY2tlZCgoaW50KWVudHJ5LlByb2Nlc3NJZCkpOwogICAgZW50cnkuU2l6ZT0odWludClNYXJzaGFsLlNpemVPZih0eXBlb2YoRW50cnkpKTsKICAgfXdoaWxlKFByb2Nlc3MzMk5leHRXKHNuYXBzaG90LHJlZiBlbnRyeSkpOwogICB2YXIgcmVzdWx0PW5ldyBMaXN0PGludD4oKTt2YXIgcXVldWU9bmV3IFF1ZXVlPGludD4oKTt2YXIgc2Vlbj1uZXcgSGFzaFNldDxpbnQ+KCk7cXVldWUuRW5xdWV1ZShyb290KTsKICAgd2hpbGUocXVldWUuQ291bnQhPTApe2ludCBjdXJyZW50PXF1ZXVlLkRlcXVldWUoKTtpZighc2Vlbi5BZGQoY3VycmVudCkpY29udGludWU7cmVzdWx0LkFkZChjdXJyZW50KTtMaXN0PGludD4gbGlzdDtpZihjaGlsZHJlbi5UcnlHZXRWYWx1ZShjdXJyZW50LG91dCBsaXN0KSlmb3JlYWNoKGludCBjaGlsZCBpbiBsaXN0KXF1ZXVlLkVucXVldWUoY2hpbGQpO30KICAgcmV0dXJuIHJlc3VsdC5Ub0FycmF5KCk7CiAgfSBmaW5hbGx5IHsgQ2xvc2VIYW5kbGUoc25hcHNob3QpOyB9CiB9Cn0='^)^)
>> "%SILENT_PS%" echo Add-Type -TypeDefinition $native -Language CSharp -ErrorAction Stop ^| Out-Null
>> "%SILENT_PS%" echo function Get-ProcessTree^([int]$rootPid^) {
>> "%SILENT_PS%" echo     $result=[Collections.Generic.List[Diagnostics.Process]]::new^(^); foreach ^($pidValue in [CpSetupProcessTree]::Snapshot^($rootPid^)^) { try { $candidate=[Diagnostics.Process]::GetProcessById^($pidValue^); [void]$candidate.StartTime; $result.Add^($candidate^) } catch {} }
>> "%SILENT_PS%" echo     @^($result^)
>> "%SILENT_PS%" echo }
>> "%SILENT_PS%" echo function Stop-ProcessTree^([Diagnostics.Process]$root^) {
>> "%SILENT_PS%" echo     $members=@^(Get-ProcessTree $root.Id^); $killer=Start-Process -FilePath $env:TASKKILL_EXE -ArgumentList @^('/PID',[string]$root.Id,'/T','/F'^) -WindowStyle Hidden -PassThru -ErrorAction Stop
>> "%SILENT_PS%" echo     if ^(-not $killer.WaitForExit^(10000^)^) { try { $killer.Kill^(^) } catch {}; [void]$killer.WaitForExit^(1000^) }; $killer.Dispose^(^)
>> "%SILENT_PS%" echo     $deadline=[DateTime]::UtcNow.AddSeconds^(5^); foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $remaining=[Math]::Max^(0,[int]^($deadline.Subtract^([DateTime]::UtcNow^).TotalMilliseconds^)^); if ^($remaining -gt 0^) { [void]$member.WaitForExit^($remaining^) } } } catch {} }
>> "%SILENT_PS%" echo     foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $member.Kill^(^) } } catch {} }; $verifyDeadline=[DateTime]::UtcNow.AddSeconds^(2^); foreach ^($member in $members^) { try { if ^(-not $member.HasExited^) { $remaining=[Math]::Max^(0,[int]^($verifyDeadline.Subtract^([DateTime]::UtcNow^).TotalMilliseconds^)^); if ^($remaining -gt 0^) { [void]$member.WaitForExit^($remaining^) } }; if ^(-not $member.HasExited^) { throw ^('Process-tree survivor: '+$member.Id^) } } finally { $member.Dispose^(^) } }
>> "%SILENT_PS%" echo }
>> "%SILENT_PS%" echo try {
>> "%SILENT_PS%" echo     $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SILENT_PS%" echo     $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru
>> "%SILENT_PS%" echo     if ^(-not $process.WaitForExit^($timeoutSeconds * 1000^)^) { Stop-ProcessTree $process; exit 124 }
>> "%SILENT_PS%" echo     exit $process.ExitCode
>> "%SILENT_PS%" echo } finally { Remove-Item -LiteralPath $wrapper -Force -ErrorAction SilentlyContinue }
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SILENT_PS%"
set "SILENT_EXIT=%ERRORLEVEL%"
if "%SILENT_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%SILENT_PS%" >nul 2>nul
set "SILENT_COMMAND="
set "SILENT_STDOUT="
set "SILENT_STDERR="
set "SILENT_TIMEOUT_SECONDS="
exit /b %SILENT_EXIT%

:capture_winget_install_result
set "PACKAGE_NOW_PRESENT=0"
call :winget_has_package "%~1"
if errorlevel 2 exit /b 1
if not errorlevel 1 set "PACKAGE_NOW_PRESENT=1"
if "%PACKAGE_NOW_PRESENT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] winget did not register package %~1.
    echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
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

:begin_pending_winget
set "PENDING_WINGET_PACKAGE=%~1"
set "PENDING_WINGET_COMPONENT=%~2"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$map=@{'Git.Git'='Winget.Git';'Neovim.Neovim'='Winget.Neovim';'OpenJS.NodeJS.LTS'='Winget.Node';'EclipseAdoptium.Temurin.21.JDK'='Winget.JDK';'MSYS2.MSYS2'='Winget.MSYS2'};$package=$env:PENDING_WINGET_PACKAGE;$component=$env:PENDING_WINGET_COMPONENT;if(-not$map.ContainsKey($package)-or$map[$package]-ine$component){throw 'Invalid pending winget operation.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$names=@($state.GetValueNames());if($names-notcontains'Snapshot.Complete'-or[int]$state.GetValue('Snapshot.Complete',0)-ne 1-or$names-contains'Pending.Winget.Intent'){throw 'Protected setup state cannot start a winget operation.'};$nonce=[guid]::NewGuid().ToString('N');$payload=[ordered]@{Version=2;OperationId=$nonce;Package=$package;Component=$component;BaselinePresent=$false};$json=$payload|ConvertTo-Json -Compress;$bytes=[Text.Encoding]::UTF8.GetBytes($json);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$intent='v2|'+$nonce+'|prepared|'+$hash+'|'+[Convert]::ToBase64String($bytes);$state.SetValue('Pending.Winget.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue('Pending.Winget.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$intent){throw 'Pending winget intent did not verify.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
if errorlevel 1 exit /b 1
call :winget_has_package "%PENDING_WINGET_PACKAGE%"
set "PENDING_WINGET_REQUERY_EXIT=!ERRORLEVEL!"
if "!PENDING_WINGET_REQUERY_EXIT!"=="1" exit /b 0
call :clear_pending_winget "%PENDING_WINGET_PACKAGE%" "%PENDING_WINGET_COMPONENT%"
if errorlevel 1 exit /b 1
if "!PENDING_WINGET_REQUERY_EXIT!"=="0" (
    set "PACKAGE_PREEXISTED=1"
    exit /b 0
)
exit /b 1

:finish_pending_winget
set "PENDING_WINGET_PACKAGE=%~1"
set "PENDING_WINGET_COMPONENT=%~2"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$name='Pending.Winget.Intent';if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Pending winget intent is missing.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending winget intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or[string]$o.Package-cne$env:PENDING_WINGET_PACKAGE-or[string]$o.Component-cne$env:PENDING_WINGET_COMPONENT-or[bool]$o.BaselinePresent){throw 'Pending winget intent verification failed.'};if($p[2]-eq'prepared'){$committed='v2|'+$p[1]+'|committed|'+$p[3]+'|'+$p[4];$state.SetValue($name,$committed,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$committed){throw 'Pending winget commit did not verify.'}};$state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw 'Pending winget intent could not be cleared.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_pending_winget
set "PENDING_WINGET_PACKAGE=%~1"
set "PENDING_WINGET_COMPONENT=%~2"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$name='Pending.Winget.Intent';if(@($state.GetValueNames())-notcontains$name){exit 0};if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Invalid pending winget intent kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-cne'prepared'-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending winget intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or[string]$o.Package-cne$env:PENDING_WINGET_PACKAGE-or[string]$o.Component-cne$env:PENDING_WINGET_COMPONENT-or[bool]$o.BaselinePresent){throw 'Pending winget intent verification failed.'};$state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw 'Pending winget intent could not be cleared.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
exit /b %ERRORLEVEL%

:read_pending_winget
set "PENDING_WINGET_INFO=%EXEC_TEMP%\cp_setup_pending_winget_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$map=@{'Git.Git'='Winget.Git';'Neovim.Neovim'='Winget.Neovim';'OpenJS.NodeJS.LTS'='Winget.Node';'EclipseAdoptium.Temurin.21.JDK'='Winget.JDK';'MSYS2.MSYS2'='Winget.MSYS2'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID);if(-not$state){throw 'Protected setup state is missing.'};try{$lines=@();$name='Pending.Winget.Intent';if(@($state.GetValueNames())-contains$name){if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Invalid pending winget intent kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending winget intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or[bool]$o.BaselinePresent-or-not$map.ContainsKey([string]$o.Package)-or$map[[string]$o.Package]-ine[string]$o.Component){throw 'Pending winget intent verification failed.'};$lines=@([string]$o.Package+'|'+[string]$o.Component+'|'+$p[2])};[IO.File]::WriteAllLines($env:PENDING_WINGET_INFO,[string[]]$lines,[Text.UTF8Encoding]::new($false))}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
if errorlevel 1 (
    del "%PENDING_WINGET_INFO%" >nul 2>nul
    exit /b 1
)
set "PENDING_WINGET_PACKAGE="
set "PENDING_WINGET_COMPONENT="
set "PENDING_WINGET_STAGE="
for /F "usebackq tokens=1,2,3 delims=|" %%A in ("%PENDING_WINGET_INFO%") do if not defined PENDING_WINGET_PACKAGE (
    set "PENDING_WINGET_PACKAGE=%%A"
    set "PENDING_WINGET_COMPONENT=%%B"
    set "PENDING_WINGET_STAGE=%%C"
)
del "%PENDING_WINGET_INFO%" >nul 2>nul
set "PENDING_WINGET_INFO="
exit /b 0

:recover_pending_winget
call :read_pending_winget
if errorlevel 1 exit /b 1
if not defined PENDING_WINGET_PACKAGE exit /b 0
call :require_winget
if errorlevel 1 exit /b 1
call :winget_has_package "%PENDING_WINGET_PACKAGE%"
set "PENDING_WINGET_QUERY_EXIT=!ERRORLEVEL!"
if "!PENDING_WINGET_QUERY_EXIT!"=="1" (
    if /i "!PENDING_WINGET_STAGE!"=="committed" exit /b 1
    call :clear_pending_winget "!PENDING_WINGET_PACKAGE!" "!PENDING_WINGET_COMPONENT!"
    exit /b !ERRORLEVEL!
)
if not "!PENDING_WINGET_QUERY_EXIT!"=="0" exit /b 1
set "PENDING_WINGET_PATH="
if /i "!PENDING_WINGET_COMPONENT!"=="Winget.Git" (
    call :find_git quiet
    set "PENDING_WINGET_PATH=!FOUND_GIT_PATH!"
)
if /i "!PENDING_WINGET_COMPONENT!"=="Winget.Neovim" (
    call :find_nvim_011 quiet
    set "PENDING_WINGET_PATH=!FOUND_NVIM_PATH!"
)
if /i "!PENDING_WINGET_COMPONENT!"=="Winget.Node" (
    call :find_node quiet
    set "PENDING_WINGET_PATH=!FOUND_NODE_PATH!"
)
if /i "!PENDING_WINGET_COMPONENT!"=="Winget.JDK" (
    call :find_javac_21 quiet
    set "PENDING_WINGET_PATH=!FOUND_JAVAC_PATH!"
)
if /i "!PENDING_WINGET_COMPONENT!"=="Winget.MSYS2" (
    call :find_msys2_shell quiet
    if not errorlevel 1 call :validate_msys2_tree
    set "PENDING_WINGET_PATH=!MSYS2_SHELL!"
)
if errorlevel 1 exit /b 1
if not defined PENDING_WINGET_PATH exit /b 1
call :record_component "!PENDING_WINGET_COMPONENT!"
if errorlevel 1 exit /b 1
call :record_component_path "!PENDING_WINGET_COMPONENT!" "!PENDING_WINGET_PATH!"
if errorlevel 1 exit /b 1
call :finish_pending_winget "!PENDING_WINGET_PACKAGE!" "!PENDING_WINGET_COMPONENT!"
exit /b !ERRORLEVEL!

:recover_pending_operations
call :recover_active_operation
if errorlevel 1 exit /b %ERRORLEVEL%
call :recover_pending_artifact_operation
if errorlevel 1 exit /b %ERRORLEVEL%
call :recover_pending_mason
if errorlevel 1 exit /b %ERRORLEVEL%
call :recover_pending_acl_archive
if errorlevel 1 exit /b %ERRORLEVEL%
call :recover_pending_registry
if errorlevel 1 exit /b %ERRORLEVEL%
call :recover_pending_winget
if errorlevel 1 exit /b 1
call :recover_pending_pacman
exit /b %ERRORLEVEL%

:recover_pending_artifact_operation
"%REG_EXE%" query "%STATE_KEY%" /v "Pending.Artifacts.Intent" >nul 2>nul
if errorlevel 1 exit /b 0
set "ARTIFACT_OPERATION_FILE="
set "ARTIFACT_OPERATION_TIME_FILE="
call :repair_target_profile_artifacts
exit /b %ERRORLEVEL%

:recover_active_operation
"%REG_EXE%" query "%STATE_KEY%" /v "Active.Operation.Intent" >nul 2>nul
if errorlevel 1 exit /b 0
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
set "ACTIVE_READ_PS=%EXEC_TEMP%\cp_setup_active_read_%RANDOM%_%RANDOM%.ps1"
set "ACTIVE_COMMIT_PS=%EXEC_TEMP%\cp_setup_active_commit_%RANDOM%_%RANDOM%.ps1"
set "ACTIVE_CLEAN_PS=%EXEC_TEMP%\cp_setup_active_clean_%RANDOM%_%RANDOM%.ps1"
set "ACTIVE_INTENT_FILE=%EXEC_TEMP%\cp_setup_active_intent_%RANDOM%_%RANDOM%.txt"
set "ACTIVE_KIND_FILE=%EXEC_TEMP%\cp_setup_active_kind_%RANDOM%_%RANDOM%.txt"
> "%ACTIVE_READ_PS%" echo $ErrorActionPreference='Stop'
>> "%ACTIVE_READ_PS%" echo . $env:PROCESS_TREE_PS
>> "%ACTIVE_READ_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%ACTIVE_READ_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID^);if^(-not$state^){throw 'Protected active-operation state is missing.'}
>> "%ACTIVE_READ_PS%" echo try{$name='Active.Operation.Intent';if^($state.GetValueKind^($name^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Invalid active-operation kind.'};$raw=[string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^([char]'^|'^);if^($p.Count-ne 11-or$p[0]-cne'v1'-or$p[1]-notmatch'^^[0-9a-f]{32}$'-or$p[2]-notin@^('Lazy','Mason'^)-or$p[6]-cne$env:CP_SETUP_TARGET_SID-or$p[7]-notmatch'^^[0-9a-f]{64}$'-or$p[8]-notmatch'^^[0-9a-f]{64}$'-or$p[9]-notmatch'^^[0-9a-f]{64}$'^){throw 'Invalid active-operation intent.'};[int]$pidValue=0;[long]$ticks=0;[int]$session=0;if^(-not[int]::TryParse^($p[3],[ref]$pidValue^)-or$pidValue-le 4-or-not[long]::TryParse^($p[4],[ref]$ticks^)-or$ticks-le 0-or-not[int]::TryParse^($p[5],[ref]$session^)-or$session-lt 0^){throw 'Invalid active-operation process identity.'};$pathBytes=[Convert]::FromBase64String^($p[10]^);if^((Hash $pathBytes^)-cne$p[9]^){throw 'Invalid active-operation path payload.'};$path=[Text.Encoding]::UTF8.GetString^($pathBytes^);$expected=[IO.Path]::GetFullPath^($env:POWERSHELL_EXE^);if^($path-cne[IO.Path]::GetFullPath^($path^)-or$path-ine$expected-or^(Get-FileHash -LiteralPath $expected -Algorithm SHA256^).Hash.ToLowerInvariant^(^)-cne$p[7]^){throw 'Invalid active-operation image.'};try{$process=[Diagnostics.Process]::GetProcessById^($pidValue^);try{$same=$process.SessionId-eq$session-and$process.StartTime.ToUniversalTime^(^).Ticks-eq$ticks;if^($same^){$same=[IO.Path]::GetFullPath^($process.MainModule.FileName^)-ieq$expected};if^(-not$same^){throw 'Active-operation process identity changed.'};Stop-CpProcessTree $process $env:TASKKILL_EXE}finally{$process.Dispose^(^)}}catch [ArgumentException]{};try{$again=[Diagnostics.Process]::GetProcessById^($pidValue^);try{if^($again.StartTime.ToUniversalTime^(^).Ticks-eq$ticks^){throw 'Active-operation process is still running.'}}finally{$again.Dispose^(^)}}catch [ArgumentException]{};[IO.File]::WriteAllText^($env:ACTIVE_INTENT_FILE,$raw,[Text.UTF8Encoding]::new^($false^)^);[IO.File]::WriteAllText^($env:ACTIVE_KIND_FILE,$p[2],[Text.Encoding]::ASCII^)}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACTIVE_READ_PS%" >nul 2>nul
set "ACTIVE_RECOVER_EXIT=%ERRORLEVEL%"
if not "%ACTIVE_RECOVER_EXIT%"=="0" goto active_recover_cleanup
set "ACTIVE_RECOVER_KIND="
set /p "ACTIVE_RECOVER_KIND="<"%ACTIVE_KIND_FILE%"
if /i "%ACTIVE_RECOVER_KIND%"=="Lazy" (
    > "%ACTIVE_CLEAN_PS%" echo $ErrorActionPreference='Stop'
    >> "%ACTIVE_CLEAN_PS%" echo $identity=[Security.Principal.WindowsIdentity]::GetCurrent^(^);if^($identity.User.Value-ine$env:CP_SETUP_TARGET_SID-or^([Security.Principal.WindowsPrincipal]::new^($identity^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)^){throw 'Active-operation cleanup token mismatch.'}
    >> "%ACTIVE_CLEAN_PS%" echo $temp=[IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_TEMP^).TrimEnd^([char]92^);$root=[IO.Path]::GetFullPath^((Join-Path $temp 'nvim'^)^).TrimEnd^([char]92^);$path=[IO.Path]::GetFullPath^((Join-Path $root 'cp_setup_lazy_lock.json'^)^);if^(-not$root.StartsWith^($temp+[char]92,[StringComparison]::OrdinalIgnoreCase^)-or-not$path.StartsWith^($root+[char]92,[StringComparison]::OrdinalIgnoreCase^)^){throw 'Unsafe Lazy residue path.'};$current=$temp;foreach^($part in $path.Substring^($temp.Length+1^).Split^([char]92,[StringSplitOptions]::RemoveEmptyEntries^)^){$current=Join-Path $current $part;if^(Test-Path -LiteralPath $current^){$item=Get-Item -LiteralPath $current -Force -ErrorAction Stop;if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^){throw 'Lazy residue path contains a reparse point.'}}};if^(Test-Path -LiteralPath $path^){$item=Get-Item -LiteralPath $path -Force;if^($item.PSIsContainer^){throw 'Lazy residue is not a file.'};Remove-Item -LiteralPath $path -Force;if^(Test-Path -LiteralPath $path^){throw 'Lazy residue cleanup failed.'}}
    "%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%ACTIVE_CLEAN_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60 >nul 2>nul
    set "ACTIVE_RECOVER_EXIT=!ERRORLEVEL!"
    if not "!ACTIVE_RECOVER_EXIT!"=="0" goto active_recover_cleanup
)
> "%ACTIVE_COMMIT_PS%" echo $ErrorActionPreference='Stop'
>> "%ACTIVE_COMMIT_PS%" echo $expected=[IO.File]::ReadAllText^($env:ACTIVE_INTENT_FILE,[Text.UTF8Encoding]::new^($false^)^);$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state^){throw 'Protected active-operation state is missing.'};try{if^($state.GetValueKind^('Active.Operation.Intent'^)-ne[Microsoft.Win32.RegistryValueKind]::String-or[string]$state.GetValue^('Active.Operation.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$expected^){throw 'Active-operation marker changed during recovery.'};$state.DeleteValue^('Active.Operation.Intent',$false^);if^(@^($state.GetValueNames^(^)^)-contains'Active.Operation.Intent'^){throw 'Active-operation marker cleanup failed.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACTIVE_COMMIT_PS%" >nul 2>nul
set "ACTIVE_RECOVER_EXIT=%ERRORLEVEL%"
:active_recover_cleanup
del "%ACTIVE_READ_PS%" "%ACTIVE_COMMIT_PS%" "%ACTIVE_CLEAN_PS%" "%ACTIVE_INTENT_FILE%" "%ACTIVE_KIND_FILE%" >nul 2>nul
set "ACTIVE_READ_PS="
set "ACTIVE_COMMIT_PS="
set "ACTIVE_CLEAN_PS="
set "ACTIVE_INTENT_FILE="
set "ACTIVE_KIND_FILE="
set "ACTIVE_RECOVER_KIND="
if "%ACTIVE_RECOVER_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
exit /b %ACTIVE_RECOVER_EXIT%

:recover_pending_mason
"%REG_EXE%" query "%STATE_KEY%" /v "Pending.Mason.Intent" >nul 2>nul
if errorlevel 1 exit /b 0
set "MASON_RECOVER_PS=%EXEC_TEMP%\cp_setup_mason_recover_%RANDOM%_%RANDOM%.ps1"
> "%MASON_RECOVER_PS%" echo $ErrorActionPreference='Stop'
>> "%MASON_RECOVER_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%MASON_RECOVER_PS%" echo function ValidList^($values^){$list=@^($values^);$sorted=@^($list^|Sort-Object -Unique^);if^($sorted.Count-ne$list.Count-or^($sorted-join"`0"^)-cne^($list-join"`0"^)-or@^($list^|Where-Object{[string]$_-notmatch'^^[A-Za-z0-9._-]+$'-or$_-in@^('.','..'^)}^).Count^){throw 'Invalid Mason inventory.'};[string[]]$list}
>> "%MASON_RECOVER_PS%" echo function Inventory^([string]$nvim^){$root=Join-Path $nvim 'mason\packages';$result=[Collections.Generic.List[string]]::new^(^);$cursor=$nvim;foreach^($part in 'mason','packages'^){$cursor=Join-Path $cursor $part;if^(Test-Path -LiteralPath $cursor^){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if^(-not$item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Unsafe Mason inventory path.'}}};if^(Test-Path -LiteralPath $root^){foreach^($item in Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop^){if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint-or$item.Name-notmatch'^^[A-Za-z0-9._-]+$'-or$item.Name-in@^('.','..'^)^){throw 'Unsafe Mason package inventory.'};$result.Add^($item.Name^)}};[string[]]@^($result^|Sort-Object -Unique^)}
>> "%MASON_RECOVER_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state^){throw 'Protected Mason recovery state is missing.'}
>> "%MASON_RECOVER_PS%" echo try{$name='Pending.Mason.Intent';if^($state.GetValueKind^($name^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Invalid pending Mason kind.'};$raw=[string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^([char]'^|'^);if^($p.Count-ne 6-or$p[0]-cne'v1'-or$p[1]-notmatch'^^[0-9a-f]{32}$'-or$p[2]-notin@^('prepared','committed'^)-or$p[3]-notmatch'^^[0-9]{1,19}$'-or$p[4]-notmatch'^^[0-9a-f]{64}$'^){throw 'Invalid pending Mason intent.'};$bytes=[Convert]::FromBase64String^($p[5]^);if^((Hash $bytes^)-cne$p[4]^){throw 'Invalid pending Mason hash.'};$json=[Text.Encoding]::UTF8.GetString^($bytes^);$plan=$json^|ConvertFrom-Json;if^(^($plan^|ConvertTo-Json -Compress^)-cne$json-or[int]$plan.Version-ne 1^){throw 'Invalid pending Mason plan.'}
>> "%MASON_RECOVER_PS%" echo $before=[string[]]^(ValidList $plan.BeforePackages^);$owned=[string[]]^(ValidList $plan.OwnedPackages^);$candidate=[string[]]^(ValidList $plan.CandidatePackages^);$excluded=[string[]]^(ValidList $plan.ExcludedPackages^);$attempt=[string[]]^(ValidList $plan.AttemptBeforePackages^);if^($state.GetValueKind^('Mason.Packages.Before'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString^){throw 'Immutable Mason inventory is missing.'};$immutable=[string[]]^(ValidList $state.GetValue^('Mason.Packages.Before'^)^);if^($before.Count-ne$immutable.Count-or^($before-join"`0"^)-cne^($immutable-join"`0"^)-or@^($candidate^|Where-Object{$before-icontains$_-or$excluded-icontains$_}^).Count-or@^($excluded^|Where-Object{$before-icontains$_}^).Count^){throw 'Invalid pending Mason package sets.'};if^($p[2]-eq'prepared'-and^($owned.Count-ne 0-or[bool]$plan.Frozen^)^){throw 'Invalid prepared Mason plan.'}
>> "%MASON_RECOVER_PS%" echo $names=@^($state.GetValueNames^(^)^);if^($p[2]-eq'prepared'-and$names-notcontains'Mason.Inventory.Frozen'^){exit 0};if^($state.GetValueKind^('Mason.Inventory.Frozen'^)-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$state.GetValue^('Mason.Inventory.Frozen',0^)-ne 1-or$state.GetValueKind^('Mason.Packages'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString^){throw 'Mason recovery metadata is invalid.'};$recorded=[string[]]^(ValidList $state.GetValue^('Mason.Packages'^)^)
>> "%MASON_RECOVER_PS%" echo if^($p[2]-eq'prepared'^){$nvim=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root'^)^).TrimEnd^([char]92^);$current=[string[]]^(Inventory $nvim^);$expected=[string[]]@^($current^|Where-Object{$candidate-icontains$_-and$before-inotcontains$_-and$excluded-inotcontains$_}^|Sort-Object -Unique^);if^($recorded.Count-ne$expected.Count-or^($recorded-join"`0"^)-cne^($expected-join"`0"^)^){throw 'Prepared Mason metadata does not match the attributed filesystem inventory.'};$owned=$expected;$committedPlan=[ordered]@{Version=1;BeforePackages=$before;OwnedPackages=$owned;Frozen=$true;CandidatePackages=$candidate;ExcludedPackages=$excluded;AttemptBeforePackages=$attempt};$committedJson=$committedPlan^|ConvertTo-Json -Compress;$committedBytes=[Text.Encoding]::UTF8.GetBytes^($committedJson^);$raw='v1^|'+$p[1]+'^|committed^|'+$p[3]+'^|'+^(Hash $committedBytes^)+'^|'+[Convert]::ToBase64String^($committedBytes^);$state.SetValue^($name,$raw,[Microsoft.Win32.RegistryValueKind]::String^)}elseif^(-not[bool]$plan.Frozen-or$recorded.Count-ne$owned.Count-or^($recorded-join"`0"^)-cne^($owned-join"`0"^)^){throw 'Committed Mason metadata does not match ownership state.'}
>> "%MASON_RECOVER_PS%" echo if^([string]$state.GetValue^($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$raw^){throw 'Pending Mason commit did not verify.'};$state.DeleteValue^($name,$false^);if^(@^($state.GetValueNames^(^)^)-contains$name^){throw 'Pending Mason intent cleanup failed.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MASON_RECOVER_PS%" >nul 2>nul
set "MASON_RECOVER_EXIT=%ERRORLEVEL%"
del "%MASON_RECOVER_PS%" >nul 2>nul
set "MASON_RECOVER_PS="
exit /b %MASON_RECOVER_EXIT%

:recover_pending_registry
"%REG_EXE%" query "%STATE_KEY%" /v "Pending.Registry.Intent" >nul 2>nul
if errorlevel 1 exit /b 0
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
set "REGISTRY_RECOVER_WORKER=%EXEC_TEMP%\cp_setup_registry_recover_%RANDOM%_%RANDOM%.worker.ps1"
set "REGISTRY_RECOVER_COMMIT=%EXEC_TEMP%\cp_setup_registry_recover_%RANDOM%_%RANDOM%.commit.ps1"
set "REGISTRY_RECOVER_UNUSED=%EXEC_TEMP%\cp_setup_registry_recover_%RANDOM%_%RANDOM%.unused.ps1"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_REGISTRY_PLAN_PS%" -Recover -WorkerScript "%REGISTRY_RECOVER_WORKER%" -CommitScript "%REGISTRY_RECOVER_COMMIT%" -RollbackScript "%REGISTRY_RECOVER_UNUSED%"
set "REGISTRY_RECOVER_PLAN_EXIT=%ERRORLEVEL%"
if not "%REGISTRY_RECOVER_PLAN_EXIT%"=="0" goto registry_recover_cleanup
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%REGISTRY_RECOVER_WORKER%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60
set "REGISTRY_RECOVER_WORKER_EXIT=%ERRORLEVEL%"
if "%REGISTRY_RECOVER_WORKER_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
if not "%REGISTRY_RECOVER_WORKER_EXIT%"=="0" (
    set "REGISTRY_RECOVER_PLAN_EXIT=%REGISTRY_RECOVER_WORKER_EXIT%"
    goto registry_recover_cleanup
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%REGISTRY_RECOVER_COMMIT%"
set "REGISTRY_RECOVER_PLAN_EXIT=%ERRORLEVEL%"
:registry_recover_cleanup
del "%REGISTRY_RECOVER_WORKER%" "%REGISTRY_RECOVER_COMMIT%" "%REGISTRY_RECOVER_UNUSED%" >nul 2>nul
set "REGISTRY_RECOVER_WORKER="
set "REGISTRY_RECOVER_COMMIT="
set "REGISTRY_RECOVER_UNUSED="
exit /b %REGISTRY_RECOVER_PLAN_EXIT%

:find_msys2_shell
if /i not "%~1"=="quiet" if defined MSYS2_SHELL exit /b 0
call :run_tool_finder "msys2" "MSYS2" "MSYS2_SHELL" "%~1"
exit /b %ERRORLEVEL%

:prepare_msys2_root
set "MSYS_ROOT_PS=%EXEC_TEMP%\cp_setup_msys_root_%RANDOM%_%RANDOM%.ps1"
> "%MSYS_ROOT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MSYS_ROOT_PS%" echo $root = [IO.Path]::GetFullPath^((Join-Path ^([IO.Path]::GetPathRoot^($env:SystemRoot^)^) 'msys64'^)^).TrimEnd^([char]92^)
>> "%MSYS_ROOT_PS%" echo if ^($root -ine ^([IO.Path]::GetPathRoot^($env:SystemRoot^).TrimEnd^([char]92^) + '\msys64'^)^) { exit 2 }
>> "%MSYS_ROOT_PS%" echo $trusted = @^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^)
>> "%MSYS_ROOT_PS%" echo $dangerous = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Modify -bor [Security.AccessControl.FileSystemRights]::FullControl -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%MSYS_ROOT_PS%" echo function Test-Acl^([string]$path^) { try { $acl = Get-Acl -LiteralPath $path -ErrorAction Stop; $owner = $acl.GetOwner^([Security.Principal.SecurityIdentifier]^).Value; if ^($trusted -notcontains $owner^) { return $false }; foreach ^($ace in $acl.GetAccessRules^($true,$true,[Security.Principal.SecurityIdentifier]^)^) { if ^($ace.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and $ace.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::InheritOnly -and ^($ace.FileSystemRights -band $dangerous^) -ne 0 -and $trusted -notcontains $ace.IdentityReference.Value^) { return $false } }; return $true } catch { return $false } }
>> "%MSYS_ROOT_PS%" echo if ^(Test-Path -LiteralPath $root^) { $item = Get-Item -LiteralPath $root -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) -or -not ^(Test-Acl $root^)^) { exit 2 }; exit 0 }
>> "%MSYS_ROOT_PS%" echo $acl = [Security.AccessControl.DirectorySecurity]::new^(^)
>> "%MSYS_ROOT_PS%" echo $acl.SetOwner^([Security.Principal.SecurityIdentifier]::new^('S-1-5-32-544'^)^)
>> "%MSYS_ROOT_PS%" echo $acl.SetAccessRuleProtection^($true,$false^)
>> "%MSYS_ROOT_PS%" echo $inherit = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
>> "%MSYS_ROOT_PS%" echo foreach ^($entry in @^(@^('S-1-5-18',[Security.AccessControl.FileSystemRights]::Modify^),@^('S-1-5-32-544',[Security.AccessControl.FileSystemRights]::Modify^),@^('S-1-5-32-545',[Security.AccessControl.FileSystemRights]::ReadAndExecute^)^)^) { $rule = [Security.AccessControl.FileSystemAccessRule]::new^([Security.Principal.SecurityIdentifier]::new^([string]$entry[0]^), [Security.AccessControl.FileSystemRights]$entry[1], $inherit, [Security.AccessControl.PropagationFlags]::None, [Security.AccessControl.AccessControlType]::Allow^); $null = $acl.AddAccessRule^($rule^) }
>> "%MSYS_ROOT_PS%" echo $item = [IO.Directory]::CreateDirectory^($root,$acl^)
>> "%MSYS_ROOT_PS%" echo if ^([IO.Path]::GetFullPath^($item.FullName^) -ine $root -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) -or @^($item.EnumerateFileSystemInfos^(^)^).Count -ne 0 -or -not ^(Test-Acl $root^)^) { exit 2 }
>> "%MSYS_ROOT_PS%" echo exit 0
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%MSYS_ROOT_PS%" >nul 2>nul
set "MSYS_ROOT_EXIT=%ERRORLEVEL%"
del "%MSYS_ROOT_PS%" >nul 2>nul
if "%MSYS_ROOT_EXIT%"=="0" exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] Existing MSYS2 root at C:\msys64 is not protected.
echo Remove it with its original uninstaller before running CP setup.
exit /b 1

:validate_existing_msys2_tree
if not exist "C:\msys64" exit /b 0
call :validate_msys2_tree
if not errorlevel 1 exit /b 0
echo [%ESC%[31mFAILED%ESC%[0m] Existing MSYS2 root at C:\msys64 is not protected.
echo Remove it with its original uninstaller before running CP setup.
exit /b 1

:validate_msys2_tree
set "MSYS_TREE_PS=%EXEC_TEMP%\cp_setup_msys_tree_%RANDOM%_%RANDOM%.ps1"
set "MSYS_TREE_OUT=%EXEC_TEMP%\cp_setup_msys_tree_%RANDOM%_%RANDOM%.out"
set "MSYS_TREE_ERR=%EXEC_TEMP%\cp_setup_msys_tree_%RANDOM%_%RANDOM%.err"
> "%MSYS_TREE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MSYS_TREE_PS%" echo $root = [IO.Path]::GetFullPath^((Join-Path ^([IO.Path]::GetPathRoot^($env:SystemRoot^)^) 'msys64'^)^).TrimEnd^([char]92^)
>> "%MSYS_TREE_PS%" echo if ^(-not ^(Test-Path -LiteralPath $root -PathType Container^)^) { exit 1 }
>> "%MSYS_TREE_PS%" echo $trusted = @^('S-1-5-18','S-1-5-32-544','S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'^)
>> "%MSYS_TREE_PS%" echo $dangerous = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Modify -bor [Security.AccessControl.FileSystemRights]::FullControl -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
>> "%MSYS_TREE_PS%" echo function Test-Item^([IO.FileSystemInfo]$item^) { if ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) { return $false }; try { $acl = $item.GetAccessControl^(^); if ^($trusted -notcontains $acl.GetOwner^([Security.Principal.SecurityIdentifier]^).Value^) { return $false }; foreach ^($ace in $acl.GetAccessRules^($true,$true,[Security.Principal.SecurityIdentifier]^)^) { if ^($ace.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and $ace.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::InheritOnly -and ^($ace.FileSystemRights -band $dangerous^) -ne 0 -and $trusted -notcontains $ace.IdentityReference.Value^) { return $false } }; return $true } catch { return $false } }
>> "%MSYS_TREE_PS%" echo $watch = [Diagnostics.Stopwatch]::StartNew^(^)
>> "%MSYS_TREE_PS%" echo $stack = [Collections.Generic.Stack[IO.DirectoryInfo]]::new^(^)
>> "%MSYS_TREE_PS%" echo $stack.Push^([IO.DirectoryInfo]::new^($root^)^)
>> "%MSYS_TREE_PS%" echo $count = 0
>> "%MSYS_TREE_PS%" echo while ^($stack.Count -gt 0^) { $directory = $stack.Pop^(^); if ^(-not ^(Test-Item $directory^)^) { exit 1 }; foreach ^($item in $directory.EnumerateFileSystemInfos^(^)^) { $count++; if ^($count -gt 250000 -or $watch.Elapsed.TotalSeconds -gt 180 -or -not ^(Test-Item $item^)^) { exit 1 }; if ^($item -is [IO.DirectoryInfo]^) { $stack.Push^($item^) } } }
>> "%MSYS_TREE_PS%" echo exit 0
set "SILENT_COMMAND="%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%MSYS_TREE_PS%""
set "SILENT_STDOUT=%MSYS_TREE_OUT%"
set "SILENT_STDERR=%MSYS_TREE_ERR%"
set "SILENT_TIMEOUT_SECONDS=210"
call :run_silent_timeout
set "MSYS_TREE_EXIT=%ERRORLEVEL%"
del "%MSYS_TREE_PS%" >nul 2>nul
del "%MSYS_TREE_OUT%" >nul 2>nul
del "%MSYS_TREE_ERR%" >nul 2>nul
exit /b %MSYS_TREE_EXIT%

:install_msys2_toolchain
call :ensure_msys2
if errorlevel 1 exit /b 1
set "PACMAN_REQUESTED=mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python"
call :capture_missing_pacman_packages "%PACMAN_REQUESTED%"
if errorlevel 1 exit /b 1
call :begin_pending_pacman
if errorlevel 1 exit /b 1
set "PACMAN_MISSING_BEFORE=%PACMAN_MISSING%"
set "PACMAN_COMMAND=/usr/bin/pacman -S --needed --noconfirm %PACMAN_REQUESTED%"
call :run_pacman_spinner "INSTALLING" "INSTALLED" "MSYS2 toolchain via pacman" "1" "this may take a while"
if errorlevel 1 (
    set "PACMAN_MISSING=!PACMAN_MISSING_BEFORE!"
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] pacman toolchain install failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :validate_msys2_tree
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Installed MSYS2 toolchain files are not protected.
    exit /b 1
)
call :capture_missing_pacman_packages "%PACMAN_REQUESTED%"
if errorlevel 1 exit /b 1
set "PACMAN_VERIFY_MISSING=!PACMAN_MISSING!"
set "PACMAN_MISSING=!PACMAN_MISSING_BEFORE!"
if defined PACMAN_VERIFY_MISSING (
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] pacman did not install every required toolchain package: !PACMAN_VERIFY_MISSING!
    echo Log: %VISIBLE_TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :record_pacman_packages
if errorlevel 1 exit /b 1
call :find_gpp quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] g++ was not usable after the pacman toolchain install.
    exit /b 1
)
call :find_python quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Python was not usable after the pacman toolchain install.
    exit /b 1
)
call :print_installed "MSYS2 toolchain via pacman"
exit /b 0

:ensure_msys2
call :find_msys2_shell
if errorlevel 1 (
    call :require_winget
    if errorlevel 1 exit /b 1
    set "PACKAGE_PREEXISTED=0"
    call :winget_has_package "MSYS2.MSYS2"
    if errorlevel 2 exit /b 1
    if not errorlevel 1 set "PACKAGE_PREEXISTED=1"
    if "!PACKAGE_PREEXISTED!"=="0" (
        call :begin_pending_winget "MSYS2.MSYS2" "Winget.MSYS2"
        if errorlevel 1 exit /b 1
    )
    call :prepare_msys2_root
    if errorlevel 1 exit /b 1
    set "INSTALL_CMD=!WINGET! install --id MSYS2.MSYS2 %WINGET_QUIET_ARGS% --override "in --confirm-command --accept-messages --accept-licenses --root C:\msys64 AllUsers=true""
    call :run_install_spinner "MSYS2 via winget: MSYS2.MSYS2" "" "%VISIBLE_TEMP%\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"
    set "INSTALL_EXIT=!ERRORLEVEL!"
    if not "!INSTALL_EXIT!"=="0" (
        echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
        exit /b 1
    )
    call :capture_winget_install_result "MSYS2.MSYS2" "Winget.MSYS2"
    if errorlevel 1 exit /b 1
    call :validate_msys2_tree
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] Installed MSYS2 files are not protected.
        exit /b 1
    )
    call :find_msys2_shell quiet
    if errorlevel 1 (
        echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was installed, but its shell was not found.
        echo Log: %VISIBLE_TEMP%\cp_setup_winget.log
        exit /b 1
    )
    if "!PACKAGE_PREEXISTED!"=="0" (
        call :record_component_path "Winget.MSYS2" "!MSYS2_SHELL!"
        if errorlevel 1 exit /b 1
        call :finish_pending_winget "MSYS2.MSYS2" "Winget.MSYS2"
        if errorlevel 1 exit /b 1
    )
    call :print_installed "MSYS2 via winget: MSYS2.MSYS2" "!MSYS2_SHELL!"
)
exit /b 0

:create_ac_library_medium_worker
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
set "AC_WORKER_MODE=%~1"
set "AC_LIBRARY_WORKER_PS=%EXEC_TEMP%\cp_setup_acl_worker_%RANDOM%_%RANDOM%.ps1"
set "AC_LIBRARY_WORKER_BUILD_PS=%EXEC_TEMP%\cp_setup_acl_worker_build_%RANDOM%_%RANDOM%.ps1"
> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $ErrorActionPreference = 'Stop'
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo function Q^([string]$value^) { if ^($null -eq $value^) { return "''" }; return "'" + $value.Replace^("'","''"^) + "'" }
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $lines=[Collections.Generic.List[string]]::new^(^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $lines.Add^('$ErrorActionPreference = ''Stop'''^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $lines.Add^('$identity=[Security.Principal.WindowsIdentity]::GetCurrent^(^)'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $lines.Add^('if^($identity.User.Value -ine ' + ^(Q $env:CP_SETUP_TARGET_SID^) + '^){throw ''ac-library worker SID mismatch.''}'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo $lines.Add^('if^(^([Security.Principal.WindowsPrincipal]::new^($identity^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)^){throw ''ac-library worker unexpectedly has an elevated token.''}'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo if ^($env:AC_WORKER_MODE -eq 'git'^) {
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$git=' + ^(Q $env:FOUND_GIT_PATH^) + ';$root=' + ^(Q $env:ROOT^)^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('^& $git ''-c'' ^(''safe.directory='' + $root^) ''-C'' $root ''submodule'' ''update'' ''--init'' ''--checkout'' ''libraries/ac-library'''^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('exit ^(if^($null-eq$LASTEXITCODE^){1}else{[int]$LASTEXITCODE}^)'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo } elseif ^($env:AC_WORKER_MODE -eq 'archive'^) {
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$ProgressPreference=''SilentlyContinue'';$commit=' + ^(Q $env:ACL_COMMIT^) + ';$stageRoot=' + ^(Q $env:ACL_STAGE_ROOT^) + ';$stagePath=' + ^(Q $env:ACL_STAGE_PATH^)^)
    >> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$temp=Join-Path $stageRoot ''.cp-setup-download'';$created=$false;try{if^([IO.Directory]::Exists^($stageRoot^)^){throw ''ac-library staging path already exists.''};[void][IO.Directory]::CreateDirectory^($stageRoot^);$created=$true;[void][IO.Directory]::CreateDirectory^($temp^);$archive=Join-Path $temp ''acl.zip'';Invoke-WebRequest -UseBasicParsing -Uri ^(''https://github.com/atcoder/ac-library/archive/''+$commit+''.zip''^) -OutFile $archive;Expand-Archive -LiteralPath $archive -DestinationPath $stageRoot -Force;if^(-not[IO.File]::Exists^((Join-Path $stagePath ''expander.py''^)^)^){throw ''Pinned ACL archive is incomplete.''};Remove-Item -LiteralPath $temp -Recurse -Force;if^(Test-Path -LiteralPath $temp^){throw ''ac-library archive temporary cleanup failed.''}}catch{if^($created^){Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue};throw}'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo } elseif ^($env:AC_WORKER_MODE -eq 'swap'^) {
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$target=' + ^(Q ^(Join-Path $env:ROOT 'libraries\ac-library'^)^) + ';$stage=' + ^(Q $env:ACL_STAGE_PATH^) + ';$stageRoot=' + ^(Q $env:ACL_STAGE_ROOT^) + ';$backup=' + ^(Q $env:ACL_BACKUP_PATH^)^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$oldMoved=$false;$newMoved=$false;try{if^(Test-Path -LiteralPath $backup^){throw ''The ac-library backup path already exists.''};if^(Test-Path -LiteralPath $target^){[IO.Directory]::Move^($target,$backup^);$oldMoved=$true};[IO.Directory]::Move^($stage,$target^);$newMoved=$true}catch{$failure=$_;$errors=[Collections.Generic.List[string]]::new^(^);if^($newMoved-and^(Test-Path -LiteralPath $target^)-and-not^(Test-Path -LiteralPath $stage^)^){try{[IO.Directory]::Move^($target,$stage^)}catch{$errors.Add^(''new target: ''+$_.Exception.Message^)}};if^($oldMoved-and^(Test-Path -LiteralPath $backup^)-and-not^(Test-Path -LiteralPath $target^)^){try{[IO.Directory]::Move^($backup,$target^)}catch{$errors.Add^(''backup: ''+$_.Exception.Message^)}};if^($errors.Count^){throw ^(''ac-library swap failed and rollback was incomplete: ''+^($errors-join''; ''^)^)};throw $failure}'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo } elseif ^($env:AC_WORKER_MODE -in @^('remove-stage','discard-backup','rollback'^)^) {
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$mode=' + ^(Q $env:AC_WORKER_MODE^) + ';$libraries=' + ^(Q ^(Join-Path $env:ROOT 'libraries'^)^) + ';$stageRoot=' + ^(Q $env:ACL_STAGE_ROOT^) + ';$stage=' + ^(Q $env:ACL_STAGE_PATH^) + ';$backup=' + ^(Q $env:ACL_BACKUP_PATH^) + ';$target=' + ^(Q ^(Join-Path $env:ROOT 'libraries\ac-library'^)^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('$libraries=[IO.Path]::GetFullPath^($libraries^).TrimEnd^([char]92^);$prefix=$libraries+[char]92;function Child^([string]$path,[string]$namePrefix^){$full=[IO.Path]::GetFullPath^($path^).TrimEnd^([char]92^);if^(-not$full.StartsWith^($prefix,[StringComparison]::OrdinalIgnoreCase^)-or-not[IO.Path]::GetFileName^($full^).StartsWith^($namePrefix,[StringComparison]::Ordinal^)^){throw ''Unsafe ac-library cleanup path.''};$full};$stageRoot=Child $stageRoot ''.ac-library-stage-'';$backup=Child $backup ''.ac-library-backup-'';if^(-not[IO.Path]::GetFullPath^($stage^).StartsWith^($stageRoot+[char]92,[StringComparison]::OrdinalIgnoreCase^)^){throw ''Unsafe ac-library rollback staging path.''}'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('function NoReparse^([string]$path^){if^(-not^(Test-Path -LiteralPath $path^)^){return};$root=Get-Item -LiteralPath $path -Force -ErrorAction Stop;if^($root.Attributes-band[IO.FileAttributes]::ReparsePoint^){throw ''ac-library cleanup root is a reparse point.''};if^($root-is[IO.DirectoryInfo]^){$stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new^(^);$stack.Push^($root^);while^($stack.Count^){foreach^($item in $stack.Pop^(^).EnumerateFileSystemInfos^(^)^){if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^){throw ^(''ac-library cleanup encountered a reparse point: ''+$item.FullName^)};if^($item-is[IO.DirectoryInfo]^){$stack.Push^($item^)}}}}};function RemoveSafe^([string]$path^){if^(-not^(Test-Path -LiteralPath $path^)^){return};NoReparse $path;[IO.Directory]::Delete^($path,$true^);if^(Test-Path -LiteralPath $path^){throw ''ac-library cleanup did not complete.''}}'^)
    >> "%AC_LIBRARY_WORKER_BUILD_PS%" echo     $lines.Add^('if^($mode-eq''remove-stage''^){RemoveSafe $stageRoot;exit 0};if^($mode-eq''discard-backup''^){RemoveSafe $backup;exit 0};foreach^($path in @^($target,$stage,$backup,$stageRoot^)^){NoReparse $path};if^(-not^(Test-Path -LiteralPath $backup^)^){RemoveSafe $stageRoot;exit 0};if^(Test-Path -LiteralPath $target^){if^(Test-Path -LiteralPath $stage^){throw ''The rollback staging path already exists.''};[IO.Directory]::Move^($target,$stage^)};[IO.Directory]::Move^($backup,$target^);RemoveSafe $stageRoot'^)
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo } else { throw 'Unknown ac-library worker mode.' }
>> "%AC_LIBRARY_WORKER_BUILD_PS%" echo [IO.File]::WriteAllText^($env:AC_LIBRARY_WORKER_PS,^($lines-join[Environment]::NewLine^),[Text.UTF8Encoding]::new^($false^)^)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%AC_LIBRARY_WORKER_BUILD_PS%"
set "AC_WORKER_BUILD_EXIT=%ERRORLEVEL%"
del "%AC_LIBRARY_WORKER_BUILD_PS%" >nul 2>nul
set "AC_LIBRARY_WORKER_BUILD_PS="
set "AC_WORKER_MODE="
if not "%AC_WORKER_BUILD_EXIT%"=="0" exit /b %AC_WORKER_BUILD_EXIT%
if not exist "%AC_LIBRARY_WORKER_PS%" exit /b 1
exit /b 0

:verify_ac_library_target_owner
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$root=[IO.Path]::GetFullPath((Join-Path $env:ROOT 'libraries\ac-library')).TrimEnd([char]92);$prefix=[IO.Path]::GetFullPath((Join-Path $env:ROOT 'libraries')).TrimEnd([char]92)+[char]92;if(-not$root.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or-not[IO.Directory]::Exists($root)){exit 1};$sid=$env:CP_SETUP_TARGET_SID;$stack=[Collections.Generic.Stack[IO.FileSystemInfo]]::new();$stack.Push([IO.DirectoryInfo]::new($root));while($stack.Count){$item=$stack.Pop();if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){exit 1};if((Get-Acl -LiteralPath $item.FullName).GetOwner([Security.Principal.SecurityIdentifier]).Value-ine$sid){exit 1};if($item-is[IO.DirectoryInfo]){foreach($child in $item.EnumerateFileSystemInfos()){$stack.Push($child)}}};exit 0" >nul 2>nul
exit /b %ERRORLEVEL%

:compute_ac_library_tree_hash
set "AC_LIBRARY_TREE_ACTUAL="
set "ACL_HASH_PS=%EXEC_TEMP%\cp_setup_acl_hash_%RANDOM%_%RANDOM%.ps1"
set "ACL_HASH_OUTPUT=%EXEC_TEMP%\cp_setup_acl_hash_%RANDOM%_%RANDOM%.txt"
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
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%ACL_HASH_PS%" "%~1" > "%ACL_HASH_OUTPUT%"
set "ACL_HASH_EXIT=%ERRORLEVEL%"
if "%ACL_HASH_EXIT%"=="0" for /F "usebackq delims=" %%P in ("%ACL_HASH_OUTPUT%") do if not defined AC_LIBRARY_TREE_ACTUAL set "AC_LIBRARY_TREE_ACTUAL=%%P"
del "%ACL_HASH_PS%" >nul 2>nul
del "%ACL_HASH_OUTPUT%" >nul 2>nul
if not "%ACL_HASH_EXIT%"=="0" exit /b 1
if not defined AC_LIBRARY_TREE_ACTUAL exit /b 1
exit /b 0

:load_pending_acl_archive
set "ACL_INTENT_INFO=%EXEC_TEMP%\cp_setup_acl_intent_%RANDOM%_%RANDOM%.txt"
set "ACL_INTENT_READ_PS=%EXEC_TEMP%\cp_setup_acl_intent_%RANDOM%_%RANDOM%.ps1"
> "%ACL_INTENT_READ_PS%" echo $ErrorActionPreference='Stop'
>> "%ACL_INTENT_READ_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%ACL_INTENT_READ_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID^);if^(-not$state-or$state.GetValueKind^('Pending.Acl.Intent'^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Pending ac-library intent is missing.'};try{$raw=[string]$state.GetValue^('Pending.Acl.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^(@^('^|'^),5^);if^($p.Count-ne 5-or$p[0]-cne'v1'-or$p[1]-notmatch'^^[0-9a-f]{32}$'-or$p[2]-notin@^('prepared','committed'^)-or$p[3]-notmatch'^^[0-9a-f]{64}$'^){throw 'Invalid pending ac-library intent.'};$bytes=[Convert]::FromBase64String^($p[4]^);if^((Hash $bytes^)-cne$p[3]^){throw 'Invalid pending ac-library hash.'};$json=[Text.Encoding]::UTF8.GetString^($bytes^);$plan=$json^|ConvertFrom-Json;if^(^($plan^|ConvertTo-Json -Compress^)-cne$json-or[int]$plan.Version-ne 1-or[string]$plan.OperationId-cne$p[1]-or[string]$plan.Commit-cne$env:ACL_COMMIT^){throw 'Invalid pending ac-library plan.'};$root=[IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^);if^([IO.Path]::GetFullPath^([string]$plan.Root^).TrimEnd^([char]92^)-ine$root^){throw 'Pending ac-library root changed.'};$libraries=[IO.Path]::GetFullPath^((Join-Path $root 'libraries'^)^).TrimEnd^([char]92^);$stageRoot=[IO.Path]::GetFullPath^([string]$plan.StageRoot^).TrimEnd^([char]92^);$stage=[IO.Path]::GetFullPath^([string]$plan.StagePath^).TrimEnd^([char]92^);$backup=[IO.Path]::GetFullPath^([string]$plan.BackupPath^).TrimEnd^([char]92^);if^([IO.Path]::GetDirectoryName^($stageRoot^)-ine$libraries-or[IO.Path]::GetFileName^($stageRoot^)-cne^('.ac-library-stage-'+$p[1]^)-or[IO.Path]::GetDirectoryName^($backup^)-ine$libraries-or[IO.Path]::GetFileName^($backup^)-cne^('.ac-library-backup-'+$p[1]^)-or$stage-ine[IO.Path]::Combine^($stageRoot,'ac-library-'+$env:ACL_COMMIT^)^){throw 'Unsafe pending ac-library paths.'};[IO.File]::WriteAllLines^($env:ACL_INTENT_INFO,@^('ACL_INTENT_NONCE='+$p[1],'ACL_INTENT_STAGE='+$p[2],'ACL_STAGE_ROOT='+$stageRoot,'ACL_STAGE_PATH='+$stage,'ACL_BACKUP_PATH='+$backup^),[Text.UTF8Encoding]::new^($false^)^)}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACL_INTENT_READ_PS%" >nul 2>nul
set "ACL_INTENT_READ_EXIT=%ERRORLEVEL%"
del "%ACL_INTENT_READ_PS%" >nul 2>nul
set "ACL_INTENT_READ_PS="
if not "%ACL_INTENT_READ_EXIT%"=="0" (
    del "%ACL_INTENT_INFO%" >nul 2>nul
    exit /b %ACL_INTENT_READ_EXIT%
)
for /F "usebackq tokens=1,* delims==" %%A in ("%ACL_INTENT_INFO%") do set "%%A=%%B"
del "%ACL_INTENT_INFO%" >nul 2>nul
set "ACL_INTENT_INFO="
if not defined ACL_INTENT_NONCE exit /b 1
if not defined ACL_STAGE_ROOT exit /b 1
if not defined ACL_STAGE_PATH exit /b 1
if not defined ACL_BACKUP_PATH exit /b 1
exit /b 0

:begin_pending_acl_archive
set "ACL_INTENT_BEGIN_PS=%EXEC_TEMP%\cp_setup_acl_begin_%RANDOM%_%RANDOM%.ps1"
> "%ACL_INTENT_BEGIN_PS%" echo $ErrorActionPreference='Stop'
>> "%ACL_INTENT_BEGIN_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%ACL_INTENT_BEGIN_PS%" echo $root=[IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^);$libraries=[IO.Path]::GetFullPath^((Join-Path $root 'libraries'^)^).TrimEnd^([char]92^);$item=Get-Item -LiteralPath $libraries -Force -ErrorAction Stop;if^(-not$item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Unsafe libraries root.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state^){throw 'Protected ac-library state is missing.'};try{if^(@^($state.GetValueNames^(^)^)-contains'Pending.Acl.Intent'^){throw 'Another ac-library operation is pending.'};$nonce=[guid]::NewGuid^(^).ToString^('N'^);$stageRoot=Join-Path $libraries ^('.ac-library-stage-'+$nonce^);$stage=Join-Path $stageRoot ^('ac-library-'+$env:ACL_COMMIT^);$backup=Join-Path $libraries ^('.ac-library-backup-'+$nonce^);$plan=[ordered]@{Version=1;OperationId=$nonce;Root=$root;Commit=$env:ACL_COMMIT;StageRoot=$stageRoot;StagePath=$stage;BackupPath=$backup};$json=$plan^|ConvertTo-Json -Compress;$bytes=[Text.Encoding]::UTF8.GetBytes^($json^);$intent='v1^|'+$nonce+'^|prepared^|'+^(Hash $bytes^)+'^|'+[Convert]::ToBase64String^($bytes^);$state.SetValue^('Pending.Acl.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String^);if^([string]$state.GetValue^('Pending.Acl.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$intent^){throw 'Pending ac-library intent did not verify.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACL_INTENT_BEGIN_PS%" >nul 2>nul
set "ACL_INTENT_BEGIN_EXIT=%ERRORLEVEL%"
del "%ACL_INTENT_BEGIN_PS%" >nul 2>nul
set "ACL_INTENT_BEGIN_PS="
if not "%ACL_INTENT_BEGIN_EXIT%"=="0" exit /b %ACL_INTENT_BEGIN_EXIT%
call :load_pending_acl_archive
exit /b %ERRORLEVEL%

:finish_pending_acl_archive
set "ACL_INTENT_FINISH_PS=%EXEC_TEMP%\cp_setup_acl_finish_%RANDOM%_%RANDOM%.ps1"
> "%ACL_INTENT_FINISH_PS%" echo $ErrorActionPreference='Stop'
>> "%ACL_INTENT_FINISH_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%ACL_INTENT_FINISH_PS%" echo $stage=[IO.Path]::GetFullPath^($env:ACL_STAGE_ROOT^).TrimEnd^([char]92^);$backup=[IO.Path]::GetFullPath^($env:ACL_BACKUP_PATH^).TrimEnd^([char]92^);if^(Test-Path -LiteralPath $stage-or Test-Path -LiteralPath $backup^){throw 'ac-library transaction files remain.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state-or$state.GetValueKind^('Pending.Acl.Intent'^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Pending ac-library intent is missing.'};try{$raw=[string]$state.GetValue^('Pending.Acl.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^(@^('^|'^),5^);if^($p.Count-ne 5-or$p[0]-cne'v1'-or$p[1]-cne$env:ACL_INTENT_NONCE-or$p[2]-notin@^('prepared','committed'^)^){throw 'Pending ac-library intent changed.'};$bytes=[Convert]::FromBase64String^($p[4]^);if^((Hash $bytes^)-cne$p[3]^){throw 'Invalid pending ac-library hash.'};if^($p[2]-eq'prepared'^){$committed='v1^|'+$p[1]+'^|committed^|'+$p[3]+'^|'+$p[4];$state.SetValue^('Pending.Acl.Intent',$committed,[Microsoft.Win32.RegistryValueKind]::String^);if^([string]$state.GetValue^('Pending.Acl.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$committed^){throw 'Pending ac-library commit did not verify.'}};$state.DeleteValue^('Pending.Acl.Intent',$false^);if^(@^($state.GetValueNames^(^)^)-contains'Pending.Acl.Intent'^){throw 'Pending ac-library intent cleanup failed.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%ACL_INTENT_FINISH_PS%" >nul 2>nul
set "ACL_INTENT_FINISH_EXIT=%ERRORLEVEL%"
del "%ACL_INTENT_FINISH_PS%" >nul 2>nul
set "ACL_INTENT_FINISH_PS="
exit /b %ACL_INTENT_FINISH_EXIT%

:recover_pending_acl_archive
"%REG_EXE%" query "%STATE_KEY%" /v "Pending.Acl.Intent" >nul 2>nul
if errorlevel 1 exit /b 0
call :load_pending_acl_archive
if errorlevel 1 exit /b 1
call :rollback_ac_library_archive
if errorlevel 1 exit /b %ERRORLEVEL%
call :finish_pending_acl_archive
exit /b %ERRORLEVEL%

:bootstrap_ac_library_archive
call :begin_pending_acl_archive
if errorlevel 1 exit /b 1
call :create_ac_library_medium_worker "archive"
if errorlevel 1 exit /b 1
set "INSTALL_CMD="%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%AC_LIBRARY_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 300"
set "SPIN_TIMEOUT_SECONDS=310"
call :run_install_spinner "ac-library" "" "%VISIBLE_TEMP%\cp_setup_acl.log" "%~1" "%~2" "1"
set "ACL_BOOTSTRAP_EXIT=%ERRORLEVEL%"
set "SPIN_TIMEOUT_SECONDS="
del "%AC_LIBRARY_WORKER_PS%" >nul 2>nul
set "AC_LIBRARY_WORKER_PS="
if not "%ACL_BOOTSTRAP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library source archive download failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_acl.log
    exit /b 1
)
if not exist "%ACL_STAGE_PATH%\expander.py" (
    call :remove_ac_library_stage
    echo [%ESC%[31mFAILED%ESC%[0m] Downloaded ac-library content is incomplete.
    echo Log: %VISIBLE_TEMP%\cp_setup_acl.log
    exit /b 1
)
call :compute_ac_library_tree_hash "%ACL_STAGE_PATH%"
if errorlevel 1 (
    call :remove_ac_library_stage
    echo [%ESC%[31mFAILED%ESC%[0m] Could not verify the downloaded ac-library integrity hash.
    echo Log: %VISIBLE_TEMP%\cp_setup_acl.log
    exit /b 1
)
if /i not "%AC_LIBRARY_TREE_ACTUAL%"=="%ACL_TREE_HASH%" (
    call :remove_ac_library_stage
    echo [%ESC%[31mFAILED%ESC%[0m] Downloaded ac-library content does not match the pinned tree hash.
    exit /b 1
)

call :ac_library_needs_update
if errorlevel 1 (
    call :remove_ac_library_stage
    call :print_ac_library_check_error
    exit /b 1
)
if /i "%~1"=="INSTALLING" if /i not "%AC_LIBRARY_STATE%"=="MISSING" (
    call :remove_ac_library_stage
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library changed while its source archive was being prepared; run the installer again.
    exit /b 1
)
if /i "%~1"=="UPDATING" if /i not "%AC_LIBRARY_STATE%"=="OUTDATED" (
    call :remove_ac_library_stage
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library changed while its source archive was being prepared; run the installer again.
    exit /b 1
)
if /i "%~1"=="INSTALLING" call :check_empty_acl_target
if /i "%~1"=="UPDATING" call :check_managed_acl_archive
if errorlevel 1 (
    call :remove_ac_library_stage
    call :print_ac_library_check_error
    exit /b 1
)

call :create_ac_library_medium_worker "swap"
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%AC_LIBRARY_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60 >> "%EXEC_TEMP%\cp_setup_acl.log" 2>&1
set "ACL_SWAP_EXIT=%ERRORLEVEL%"
if "%ACL_SWAP_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
call :publish_component_log "cp_setup_acl.log"
if errorlevel 1 if "%ACL_SWAP_EXIT%"=="0" set "ACL_SWAP_EXIT=1"
del "%AC_LIBRARY_WORKER_PS%" >nul 2>nul
set "AC_LIBRARY_WORKER_PS="
if not "%ACL_SWAP_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not replace ac-library safely.
    echo Log: %VISIBLE_TEMP%\cp_setup_acl.log
    exit /b 1
)

call :ac_library_needs_update
set "ACL_FINAL_CHECK_EXIT=%ERRORLEVEL%"
if not "%ACL_FINAL_CHECK_EXIT%"=="0" goto ac_library_archive_rollback
if /i not "%AC_LIBRARY_STATE%"=="CURRENT" goto ac_library_archive_rollback
call :handoff_ac_library_ownership "1"
if errorlevel 1 (
    set "ACL_FINAL_CHECK_EXIT=1"
    goto ac_library_archive_rollback
)
call :verify_ac_library_target_owner
if errorlevel 1 (
    set "ACL_FINAL_CHECK_EXIT=1"
    goto ac_library_archive_rollback
)
call :record_acl_archive_hash
if errorlevel 1 (
    set "ACL_FINAL_CHECK_EXIT=1"
    goto ac_library_archive_rollback
)
call :discard_ac_library_backup
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library is current, but its temporary backup could not be removed.
    echo Backup: %ACL_BACKUP_PATH%
    exit /b 1
)
call :remove_ac_library_stage
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library is current, but its staging directory could not be removed.
    echo Staging: %ACL_STAGE_ROOT%
    exit /b 1
)
call :finish_pending_acl_archive
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library is current, but its operation state could not be finalized.
    exit /b 1
)
call :print_success_status "%~2" "ac-library"
exit /b 0

:ac_library_archive_rollback
call :rollback_ac_library_archive
set "ACL_ROLLBACK_EXIT=%ERRORLEVEL%"
if not "%ACL_ROLLBACK_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] ac-library verification failed and rollback was incomplete.
    echo Target: %ROOT%\libraries\ac-library
    echo Backup: %ACL_BACKUP_PATH%
    echo Staging: %ACL_STAGE_PATH%
    exit /b 1
)
if not "%ACL_FINAL_CHECK_EXIT%"=="0" call :print_ac_library_check_error
if "%ACL_FINAL_CHECK_EXIT%"=="0" echo [%ESC%[31mFAILED%ESC%[0m] ac-library did not pass the final pinned-tree verification.
exit /b 1

:remove_ac_library_stage
call :run_ac_library_file_worker "remove-stage"
exit /b %ERRORLEVEL%

:discard_ac_library_backup
call :run_ac_library_file_worker "discard-backup"
exit /b %ERRORLEVEL%

:rollback_ac_library_archive
call :run_ac_library_file_worker "rollback"
exit /b %ERRORLEVEL%

:run_ac_library_file_worker
call :create_ac_library_medium_worker "%~1"
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%AC_LIBRARY_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60 >> "%EXEC_TEMP%\cp_setup_acl.log" 2>&1
set "ACL_FILE_EXIT=%ERRORLEVEL%"
if "%ACL_FILE_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
call :publish_component_log "cp_setup_acl.log"
if errorlevel 1 if "%ACL_FILE_EXIT%"=="0" set "ACL_FILE_EXIT=1"
del "%AC_LIBRARY_WORKER_PS%" >nul 2>nul
set "AC_LIBRARY_WORKER_PS="
exit /b %ACL_FILE_EXIT%

:capture_missing_pacman_packages
call :find_msys2_shell quiet
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 was not available while checking pacman packages.
    exit /b 1
)
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" (
    echo [%ESC%[31mFAILED%ESC%[0m] MSYS2 bash was not available while checking pacman packages.
    exit /b 1
)
set "PACMAN_MISSING="
for %%P in (%~1) do (
    call :pacman_has_package "%%P"
    set "PACMAN_CAPTURE_EXIT=!ERRORLEVEL!"
    if "!PACMAN_CAPTURE_EXIT!"=="1" set "PACMAN_MISSING=!PACMAN_MISSING! %%P"
    if not "!PACMAN_CAPTURE_EXIT!"=="0" if not "!PACMAN_CAPTURE_EXIT!"=="1" exit /b !PACMAN_CAPTURE_EXIT!
)
for /F "tokens=*" %%P in ("%PACMAN_MISSING%") do set "PACMAN_MISSING=%%P"
exit /b 0

:begin_pending_pacman
if not defined PACMAN_MISSING exit /b 0
set "PENDING_PACMAN_PACKAGES=%PACMAN_MISSING%"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$allowed=@($env:PACMAN_PACKAGES_ALLOWED-split' '|Where-Object{$_});$raw=@($env:PENDING_PACMAN_PACKAGES-split' '|Where-Object{$_});$packages=@($raw|Sort-Object -Unique);if(-not$packages.Count-or$packages.Count-ne$raw.Count-or@($packages|Where-Object{$allowed-inotcontains$_}).Count){throw 'Invalid pending pacman package set.'};$shell=[IO.Path]::GetFullPath($env:MSYS2_SHELL);$expected=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetPathRoot($env:SystemRoot)) 'msys64\msys2_shell.cmd'));if($shell-ine$expected){throw 'Invalid pending pacman shell.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$names=@($state.GetValueNames());if($names-notcontains'Snapshot.Complete'-or[int]$state.GetValue('Snapshot.Complete',0)-ne 1-or$names-contains'Pending.Pacman.Intent'){throw 'Protected setup state cannot start a pacman operation.'};$nonce=[guid]::NewGuid().ToString('N');$payload=[ordered]@{Version=2;OperationId=$nonce;Shell=$shell;BaselineAbsentPackages=[string[]]$packages;RecoveredPackages=[string[]]@()};$json=$payload|ConvertTo-Json -Compress;$bytes=[Text.Encoding]::UTF8.GetBytes($json);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$intent='v2|'+$nonce+'|prepared|'+$hash+'|'+[Convert]::ToBase64String($bytes);$state.SetValue('Pending.Pacman.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue('Pending.Pacman.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$intent){throw 'Pending pacman intent did not verify.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
if errorlevel 1 exit /b 1
set "PACMAN_STILL_MISSING="
set "PACMAN_PENDING_REQUERY_EXIT=0"
for %%P in (%PACMAN_MISSING%) do if "!PACMAN_PENDING_REQUERY_EXIT!"=="0" (
    call :pacman_has_package "%%P"
    set "PACMAN_PENDING_QUERY_EXIT=!ERRORLEVEL!"
    if "!PACMAN_PENDING_QUERY_EXIT!"=="1" set "PACMAN_STILL_MISSING=!PACMAN_STILL_MISSING! %%P"
    if not "!PACMAN_PENDING_QUERY_EXIT!"=="0" if not "!PACMAN_PENDING_QUERY_EXIT!"=="1" set "PACMAN_PENDING_REQUERY_EXIT=!PACMAN_PENDING_QUERY_EXIT!"
)
if not "!PACMAN_PENDING_REQUERY_EXIT!"=="0" (
    call :clear_pending_pacman
    exit /b !PACMAN_PENDING_REQUERY_EXIT!
)
for /F "tokens=*" %%P in ("!PACMAN_STILL_MISSING!") do set "PACMAN_STILL_MISSING=%%P"
set "PACMAN_MISSING=!PACMAN_STILL_MISSING!"
set "PENDING_PACMAN_PACKAGES=!PACMAN_MISSING!"
call :update_pending_pacman
exit /b !ERRORLEVEL!

:update_pending_pacman
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$allowed=@($env:PACMAN_PACKAGES_ALLOWED-split' '|Where-Object{$_});$new=@($env:PENDING_PACMAN_PACKAGES-split' '|Where-Object{$_}|Sort-Object -Unique);if(@($new|Where-Object{$allowed-inotcontains$_}).Count){throw 'Invalid replacement pacman package set.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$name='Pending.Pacman.Intent';if(@($state.GetValueNames())-notcontains$name){if($new.Count){throw 'Pending pacman intent is missing.'};exit 0};if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Invalid pending pacman intent kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-cne'prepared'-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending pacman intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;$old=@($o.BaselineAbsentPackages|Sort-Object -Unique);$expected=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetPathRoot($env:SystemRoot)) 'msys64\msys2_shell.cmd'));if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or[IO.Path]::GetFullPath([string]$o.Shell)-ine$expected-or-not$old.Count-or@($old|Where-Object{$allowed-inotcontains$_}).Count-or@($o.RecoveredPackages).Count-or@($new|Where-Object{$old-inotcontains$_}).Count){throw 'Pending pacman intent verification failed.'};if(-not$new.Count){$state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw 'Pending pacman intent could not be cleared.'};exit 0};$payload=[ordered]@{Version=2;OperationId=$p[1];Shell=$expected;BaselineAbsentPackages=[string[]]$new;RecoveredPackages=[string[]]@()};$newJson=$payload|ConvertTo-Json -Compress;$newBytes=[Text.Encoding]::UTF8.GetBytes($newJson);$sha=[Security.Cryptography.SHA256]::Create();try{$newHash=([BitConverter]::ToString($sha.ComputeHash($newBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$replacement='v2|'+$p[1]+'|prepared|'+$newHash+'|'+[Convert]::ToBase64String($newBytes);$state.SetValue($name,$replacement,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$replacement){throw 'Pending pacman intent did not verify.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
exit /b %ERRORLEVEL%

:clear_pending_pacman
set "PENDING_PACMAN_PACKAGES="
call :update_pending_pacman
exit /b %ERRORLEVEL%

:read_pending_pacman
set "PENDING_PACMAN_INFO=%EXEC_TEMP%\cp_setup_pending_pacman_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$allowed=@($env:PACMAN_PACKAGES_ALLOWED-split' '|Where-Object{$_});$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID);if(-not$state){throw 'Protected setup state is missing.'};try{$lines=@();$name='Pending.Pacman.Intent';if(@($state.GetValueNames())-contains$name){if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Invalid pending pacman intent kind.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending pacman intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;$shell=[IO.Path]::GetFullPath([string]$o.Shell);$expected=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetPathRoot($env:SystemRoot)) 'msys64\msys2_shell.cmd'));$baseline=@($o.BaselineAbsentPackages|Sort-Object -Unique);$recovered=@($o.RecoveredPackages|Sort-Object -Unique);$packages=if($p[2]-eq'committed'){$recovered}else{$baseline};if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or$shell-ine$expected-or-not$packages.Count-or@($baseline|Where-Object{$allowed-inotcontains$_}).Count-or@($recovered|Where-Object{$baseline-inotcontains$_}).Count){throw 'Pending pacman intent verification failed.'};$lines=@($shell,($packages-join' '),$p[2])};[IO.File]::WriteAllLines($env:PENDING_PACMAN_INFO,[string[]]$lines,[Text.UTF8Encoding]::new($false))}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
if errorlevel 1 (
    del "%PENDING_PACMAN_INFO%" >nul 2>nul
    exit /b 1
)
set "PENDING_PACMAN_SHELL="
set "PENDING_PACMAN_PACKAGES="
set "PENDING_PACMAN_STAGE="
if exist "%PENDING_PACMAN_INFO%" (
    set /p "PENDING_PACMAN_SHELL="<"%PENDING_PACMAN_INFO%"
    for /F "usebackq skip=1 delims=" %%P in ("%PENDING_PACMAN_INFO%") do if not defined PENDING_PACMAN_PACKAGES set "PENDING_PACMAN_PACKAGES=%%P"
    for /F "usebackq skip=2 delims=" %%P in ("%PENDING_PACMAN_INFO%") do if not defined PENDING_PACMAN_STAGE set "PENDING_PACMAN_STAGE=%%P"
)
del "%PENDING_PACMAN_INFO%" >nul 2>nul
set "PENDING_PACMAN_INFO="
exit /b 0

:recover_pending_pacman
call :read_pending_pacman
if errorlevel 1 exit /b 1
if not defined PENDING_PACMAN_SHELL exit /b 0
set "MSYS2_SHELL=%PENDING_PACMAN_SHELL%"
if not exist "%MSYS2_SHELL%" (
    if /i "!PENDING_PACMAN_STAGE!"=="committed" exit /b 1
    call :clear_pending_pacman
    exit /b !ERRORLEVEL!
)
call :validate_msys2_tree
if errorlevel 1 exit /b 1
for %%I in ("%MSYS2_SHELL%") do set "MSYS2_BASH=%%~dpIusr\bin\bash.exe"
if not exist "%MSYS2_BASH%" exit /b 1
set "PACMAN_RECOVERED="
for %%P in (%PENDING_PACMAN_PACKAGES%) do (
    call :pacman_has_package "%%P"
    set "PACMAN_RECOVERY_QUERY_EXIT=!ERRORLEVEL!"
    if "!PACMAN_RECOVERY_QUERY_EXIT!"=="0" set "PACMAN_RECOVERED=!PACMAN_RECOVERED! %%P"
    if not "!PACMAN_RECOVERY_QUERY_EXIT!"=="0" if not "!PACMAN_RECOVERY_QUERY_EXIT!"=="1" exit /b !PACMAN_RECOVERY_QUERY_EXIT!
)
for /F "tokens=*" %%P in ("!PACMAN_RECOVERED!") do set "PACMAN_RECOVERED=%%P"
if not defined PACMAN_RECOVERED (
    call :clear_pending_pacman
    exit /b !ERRORLEVEL!
)
set "PACMAN_MISSING=!PACMAN_RECOVERED!"
call :record_pacman_packages
exit /b !ERRORLEVEL!

:record_pacman_packages
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $key=$env:CP_SETUP_TARGET_STATE; $allowed=@($env:PACMAN_PACKAGES_ALLOWED -split ' ' | Where-Object { $_ }); $new=@($env:PACMAN_MISSING -split ' ' | Where-Object { $_ }); $existing=@((Get-ItemProperty -Path $key -Name 'Pacman.Packages' -ErrorAction SilentlyContinue).'Pacman.Packages' | Where-Object { $_ }); foreach ($name in @($existing+$new)) { if ($allowed -inotcontains $name) { throw ('Unsafe setup-owned pacman package: '+$name) } }; $owned=@($existing+$new | Sort-Object -Unique); if ($owned.Count) { New-ItemProperty -Path $key -Name 'Pacman.Packages' -PropertyType MultiString -Value ([string[]]$owned) -Force | Out-Null; New-ItemProperty -Path $key -Name 'Pacman.Toolchain' -PropertyType DWord -Value 1 -Force | Out-Null; $shell=$env:MSYS2_SHELL; if ($shell -and (Test-Path -LiteralPath $shell)) { New-ItemProperty -Path $key -Name 'Pacman.Shell.Path' -PropertyType String -Value ([IO.Path]::GetFullPath($shell)) -Force | Out-Null } }"
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not record setup ownership for pacman packages.
    exit /b 1
)
call :finish_pending_pacman
exit /b %ERRORLEVEL%

:finish_pending_pacman
set "PENDING_PACMAN_PACKAGES=%PACMAN_MISSING%"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$allowed=@($env:PACMAN_PACKAGES_ALLOWED-split' '|Where-Object{$_});$recovered=@($env:PENDING_PACMAN_PACKAGES-split' '|Where-Object{$_}|Sort-Object -Unique);if(-not$recovered.Count-or@($recovered|Where-Object{$allowed-inotcontains$_}).Count){throw 'Invalid recovered pacman package set.'};$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);try{$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not$state){throw 'Protected setup state is missing.'};try{$name='Pending.Pacman.Intent';if($state.GetValueKind($name)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Pending pacman intent is missing.'};$raw=[string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$p=$raw.Split(@('|'),5);if($p.Count-ne 5-or$p[0]-cne'v2'-or$p[1]-notmatch'^[0-9a-f]{32}$'-or$p[2]-notin@('prepared','committed')-or$p[3]-notmatch'^[0-9a-f]{64}$'){throw 'Invalid pending pacman intent.'};$bytes=[Convert]::FromBase64String($p[4]);$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$json=[Text.Encoding]::UTF8.GetString($bytes);$o=$json|ConvertFrom-Json;$baseline=@($o.BaselineAbsentPackages|Sort-Object -Unique);$recorded=@($o.RecoveredPackages|Sort-Object -Unique);if($hash-cne$p[3]-or($o|ConvertTo-Json -Compress)-cne$json-or[int]$o.Version-ne 2-or[string]$o.OperationId-cne$p[1]-or@($recovered|Where-Object{$baseline-inotcontains$_}).Count){throw 'Pending pacman intent verification failed.'};if($p[2]-eq'committed'){if($recorded.Count-ne$recovered.Count-or@($recovered|Where-Object{$recorded-inotcontains$_}).Count){throw 'Committed pacman recovery set changed.'}}else{$payload=[ordered]@{Version=2;OperationId=$p[1];Shell=[string]$o.Shell;BaselineAbsentPackages=[string[]]$baseline;RecoveredPackages=[string[]]$recovered};$newJson=$payload|ConvertTo-Json -Compress;$newBytes=[Text.Encoding]::UTF8.GetBytes($newJson);$sha=[Security.Cryptography.SHA256]::Create();try{$newHash=([BitConverter]::ToString($sha.ComputeHash($newBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$committed='v2|'+$p[1]+'|committed|'+$newHash+'|'+[Convert]::ToBase64String($newBytes);$state.SetValue($name,$committed,[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$committed){throw 'Pending pacman commit did not verify.'}};$state.DeleteValue($name,$false);if(@($state.GetValueNames())-contains$name){throw 'Pending pacman intent could not be cleared.'}}finally{$state.Dispose()}}finally{$machine.Dispose()}" >nul 2>nul
exit /b %ERRORLEVEL%

:record_partial_pacman_packages
set "PACMAN_INSTALLED_NEW="
for %%P in (%PACMAN_MISSING%) do (
    call :pacman_has_package "%%P"
    set "PACMAN_PARTIAL_QUERY_EXIT=!ERRORLEVEL!"
    if "!PACMAN_PARTIAL_QUERY_EXIT!"=="0" set "PACMAN_INSTALLED_NEW=!PACMAN_INSTALLED_NEW! %%P"
    if not "!PACMAN_PARTIAL_QUERY_EXIT!"=="0" if not "!PACMAN_PARTIAL_QUERY_EXIT!"=="1" exit /b !PACMAN_PARTIAL_QUERY_EXIT!
)
set "PACMAN_MISSING=!PACMAN_INSTALLED_NEW!"
if not defined PACMAN_MISSING (
    call :clear_pending_pacman
    exit /b !ERRORLEVEL!
)
call :record_pacman_packages
exit /b %ERRORLEVEL%

:pacman_has_package
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
set "PACMAN_QUERY_PACKAGE=%~1"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; . $env:PROCESS_TREE_PS; $allowed=@($env:PACMAN_PACKAGES_ALLOWED -split ' ' | Where-Object { $_ }); $package=$env:PACMAN_QUERY_PACKAGE; if ($allowed -inotcontains $package) { exit 2 }; $command='exec /usr/bin/env -i MSYSTEM=MINGW64 HOME=/tmp/cp-setup PATH=/usr/bin:/bin:/mingw64/bin /usr/bin/pacman -Qq -- '+$package; $quoted=[char]34+$command+[char]34; $p=Start-Process -FilePath $env:MSYS2_BASH -ArgumentList @('--noprofile','--norc','-c',$quoted) -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru; if (-not $p.WaitForExit(60000)) { Stop-CpProcessTree $p $env:TASKKILL_EXE; exit 124 }; exit $p.ExitCode" >nul 2>nul
set "PACMAN_QUERY_EXIT=%ERRORLEVEL%"
if "%PACMAN_QUERY_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
set "PACMAN_QUERY_PACKAGE="
exit /b %PACMAN_QUERY_EXIT%

:run_pacman_spinner
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
set "PACMAN_ACTION=%~1"
set "PACMAN_SUCCESS=%~2"
set "PACMAN_LABEL=%~3"
set "PACMAN_DEFER_SUCCESS=%~4"
set "PACMAN_HINT=%~5"
if not defined PACMAN_ACTION set "PACMAN_ACTION=INSTALLING"
if not defined PACMAN_SUCCESS set "PACMAN_SUCCESS=INSTALLED"
if not defined PACMAN_LABEL set "PACMAN_LABEL=MSYS2 toolchain via pacman"
set "SPIN_PS=%EXEC_TEMP%\cp_setup_pacman_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo . $env:PROCESS_TREE_PS
>> "%SPIN_PS%" echo $label = $env:PACMAN_LABEL
>> "%SPIN_PS%" echo $hint = [string]$env:PACMAN_HINT
>> "%SPIN_PS%" echo $hintSuffix = if ^([string]::IsNullOrWhiteSpace^($hint^)^) { '' } else { ' ^(' + $hint + '^)' }
>> "%SPIN_PS%" echo $deferSuccess = $env:PACMAN_DEFER_SUCCESS -eq '1'
>> "%SPIN_PS%" echo $log = Join-Path $env:EXEC_TEMP 'cp_setup_pacman.log'
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:EXEC_TEMP ('cp_setup_pacman_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $consoleWidth = try { [Math]::Max^(20,[Console]::BufferWidth^) } catch { 80 }
>> "%SPIN_PS%" echo function Shorten^([string]$value,[int]$limit^) { if ^(-not $value -or $limit -lt 4^) { return '' }; if ^($value.Length -le $limit^) { return $value }; return $value.Substring^(0,$limit-3^) + '...' }
>> "%SPIN_PS%" echo function Fit-Line^([string]$name,[string]$detail,[int]$statusLength,[bool]$hasFrame^) { $fixed=$statusLength+3; if^($hasFrame^){$fixed+=2}; $nameBudget=[Math]::Max^(4,$consoleWidth-1-$fixed^); $shownName=Shorten $name $nameBudget; $detailBudget=$consoleWidth-1-$fixed-$shownName.Length-3; $shownDetail=if^($detailBudget-ge 8^){Shorten $detail $detailBudget}else{''}; [pscustomobject]@{Name=$shownName;Detail=$shownDetail} }
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:PACMAN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:PACMAN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo $failure = '[' + $esc + '[31mFAILED' + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo $shell = $null
>> "%SPIN_PS%" echo foreach ($path in @($env:MSYS2_SHELL,'C:\msys64\msys2_shell.cmd')) { if ($path -and (Split-Path -Leaf $path) -ieq 'msys2_shell.cmd' -and (Test-Path -LiteralPath $path)) { $shell = [IO.Path]::GetFullPath($path); break } }
>> "%SPIN_PS%" echo if (-not $shell) { $cmd = Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue; if ($cmd) { $shell = $cmd.Source } }
>> "%SPIN_PS%" echo if (-not $shell) { 'Could not find msys2_shell.cmd after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($failure + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $bash = Join-Path (Split-Path -Parent $shell) 'usr\bin\bash.exe'
>> "%SPIN_PS%" echo if (-not (Test-Path -LiteralPath $bash)) { 'Could not find MSYS2 bash.exe after installing MSYS2.' ^| Set-Content -LiteralPath $log; Write-Host ($failure + ' ' + $label); exit 1 }
>> "%SPIN_PS%" echo $pacman = $env:PACMAN_COMMAND
>> "%SPIN_PS%" echo $safeCommand = 'exec /usr/bin/env -i MSYSTEM=MINGW64 HOME=/tmp/cp-setup PATH=/usr/bin:/bin:/mingw64/bin ' + $pacman
>> "%SPIN_PS%" echo $runLine = [string]^($q + $bash + $q + ' --noprofile --norc -c ' + $q + $safeCommand + $q + ' 1^>' + $q + $log + $q + ' 2^>^&1'^)
>> "%SPIN_PS%" echo $lines = @^('@echo off','setlocal DisableDelayedExpansion','set "MSYSTEM=MINGW64"','set "CHERE_INVOKING=enabled_from_arguments"','set "MSYS2_PATH_TYPE=strict"','set "BASH_ENV="','set "ENV="','set "BASHOPTS="','set "SHELLOPTS="',$runLine,'exit /b %%ERRORLEVEL%%'^)
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SPIN_PS%" echo $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo $started = [Diagnostics.Stopwatch]::StartNew^(^)
>> "%SPIN_PS%" echo $timedOut = $false
>> "%SPIN_PS%" echo while ^(-not $process.HasExited^) { Write-Host -NoNewline ^($cr + $clear + $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $label + $hintSuffix^); [Console]::Out.Flush^(^); if ^($started.Elapsed.TotalSeconds -ge 1800^) { $timedOut = $true; Stop-CpProcessTree $process $env:TASKKILL_EXE; try { 'Timed out after 1800 seconds.' ^| Add-Content -LiteralPath $log -ErrorAction Stop } catch {}; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo if ^($timedOut^) { $exitCode = 124 } elseif ^(-not $process.WaitForExit^(1000^)^) { Stop-CpProcessTree $process $env:TASKKILL_EXE; $exitCode=124 } else { $exitCode = $process.ExitCode }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($exitCode -eq 0 -and $deferSuccess) { Write-Host -NoNewline ($cr + $clear) } elseif ($exitCode -eq 0) { Write-Host ($cr + $clear + $success + ' ' + $label) } else { Write-Host ($cr + $clear + $failure + ' ' + $label) }
>> "%SPIN_PS%" echo exit $exitCode
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%SPIN_PS%" >nul 2>nul
call :publish_component_log "cp_setup_pacman.log"
set "SPIN_PUBLISH_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="0" if not "%SPIN_PUBLISH_EXIT%"=="0" set "SPIN_EXIT=1"
exit /b %SPIN_EXIT%

:publish_component_log
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
set "CP_SETUP_LOG_NAME=%~1"
set "CP_SETUP_LOG_SOURCE=%EXEC_TEMP%\%~1"
set "COMPONENT_LOG_WORKER=%EXEC_TEMP%\cp_setup_log_publish_%RANDOM%_%RANDOM%.ps1"
> "%COMPONENT_LOG_WORKER%" echo $ErrorActionPreference='Stop'
>> "%COMPONENT_LOG_WORKER%" echo Set-StrictMode -Version 2
>> "%COMPONENT_LOG_WORKER%" echo $sid=^([Security.Principal.WindowsIdentity]::GetCurrent^(^)^).User.Value;if^($sid-ine$env:CP_SETUP_TARGET_SID^){throw 'Log publisher SID mismatch.'};$principal=[Security.Principal.WindowsPrincipal]::new^([Security.Principal.WindowsIdentity]::GetCurrent^(^)^);if^($principal.IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)^){throw 'Log publisher unexpectedly has an elevated token.'}
>> "%COMPONENT_LOG_WORKER%" echo $name=[string]$env:CP_SETUP_LOG_NAME;if^($name-notmatch'^^cp_setup_^('+'winget^|pacman^|git^|acl^|nvim^|mason'+^'^)\.log$'^){throw 'Invalid component log name.'};$source=[IO.Path]::GetFullPath^($env:CP_SETUP_LOG_SOURCE^);$exec=[IO.Path]::GetFullPath^($env:CP_SETUP_LOG_EXEC_ROOT^).TrimEnd^([char]92^);if^(-not$source.StartsWith^($exec+[char]92,[StringComparison]::OrdinalIgnoreCase^)-or[IO.Path]::GetFileName^($source^)-cne$name-or-not[IO.File]::Exists^($source^)^){throw 'Protected component log is missing.'}
>> "%COMPONENT_LOG_WORKER%" echo function Assert-Path^([string]$path,[bool]$leafMayBeMissing^){$full=[IO.Path]::GetFullPath^($path^);$root=[IO.Path]::GetPathRoot^($full^);$current=$root;$parts=$full.Substring^($root.Length^).Split^([char[]]@^([char]92^),[StringSplitOptions]::RemoveEmptyEntries^);for^($i=0;$i-lt$parts.Count;$i++^){$current=[IO.Path]::Combine^($current,$parts[$i]^);if^($leafMayBeMissing-and$i-eq$parts.Count-1-and-not[IO.File]::Exists^($current^)-and-not[IO.Directory]::Exists^($current^)^){continue};$item=Get-Item -LiteralPath $current -Force -ErrorAction Stop;if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^){throw ^('Component log path contains a reparse point: '+$current^)}};$full}
>> "%COMPONENT_LOG_WORKER%" echo [void]^(Assert-Path $source $false^);$targetRoot=Assert-Path $env:CP_SETUP_TARGET_TEMP $false;$destination=[IO.Path]::GetFullPath^((Join-Path $targetRoot $name^)^);if^([IO.Path]::GetDirectoryName^($destination^)-ine$targetRoot^){throw 'Component log destination escaped target Temp.'};if^(Test-Path -LiteralPath $destination^){$item=Get-Item -LiteralPath $destination -Force -ErrorAction Stop;if^($item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Component log destination is unsafe.'}}
>> "%COMPONENT_LOG_WORKER%" echo $temporary=Join-Path $targetRoot ^('.'+$name+'.'+[guid]::NewGuid^(^).ToString^('N'^)+'.tmp'^);$input=[IO.FileStream]::new^($source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read^);try{$output=[IO.FileStream]::new^($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read^);try{$input.CopyTo^($output^);$output.Flush^($true^)}finally{$output.Dispose^(^)}}finally{$input.Dispose^(^)};try{if^(Test-Path -LiteralPath $destination^){$item=Get-Item -LiteralPath $destination -Force;if^($item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Component log destination changed.'};[IO.File]::Delete^($destination^)};[IO.File]::Move^($temporary,$destination^);if^(-not[IO.File]::Exists^($destination^)-or^([IO.File]::GetAttributes^($destination^)-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Component log publication did not verify.'}}finally{if^(Test-Path -LiteralPath $temporary^){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
set "CP_SETUP_LOG_EXEC_ROOT=%EXEC_TEMP%"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%COMPONENT_LOG_WORKER%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60 >nul 2>nul
set "COMPONENT_LOG_EXIT=%ERRORLEVEL%"
if "%COMPONENT_LOG_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%COMPONENT_LOG_WORKER%" >nul 2>nul
set "COMPONENT_LOG_WORKER="
set "CP_SETUP_LOG_NAME="
set "CP_SETUP_LOG_SOURCE="
set "CP_SETUP_LOG_EXEC_ROOT="
exit /b %COMPONENT_LOG_EXIT%

:run_install_spinner
call :prepare_process_tree_helper
if errorlevel 1 exit /b 1
set "SPIN_LABEL=%~1"
set "SPIN_HINT=%~2"
for %%L in ("%~3") do set "SPIN_LOG_NAME=%%~nxL"
set "SPIN_LOG=%EXEC_TEMP%\!SPIN_LOG_NAME!"
set "SPIN_ACTION=%~4"
set "SPIN_SUCCESS=%~5"
set "SPIN_DEFER_SUCCESS=%~6"
if not defined SPIN_ACTION set "SPIN_ACTION=INSTALLING"
if not defined SPIN_SUCCESS set "SPIN_SUCCESS=INSTALLED"
set "SPIN_PS=%EXEC_TEMP%\cp_setup_install_spinner_%RANDOM%_%RANDOM%.ps1"
> "%SPIN_PS%" echo $ErrorActionPreference = 'Stop'
>> "%SPIN_PS%" echo . $env:PROCESS_TREE_PS
>> "%SPIN_PS%" echo $label = $env:SPIN_LABEL
>> "%SPIN_PS%" echo $hint = $env:SPIN_HINT
>> "%SPIN_PS%" echo $log = $env:SPIN_LOG
>> "%SPIN_PS%" echo $cmd = [string]$env:INSTALL_CMD
>> "%SPIN_PS%" echo $deferSuccess = $env:SPIN_DEFER_SUCCESS -eq '1'
>> "%SPIN_PS%" echo $progressFile = $env:SPIN_PROGRESS_FILE
>> "%SPIN_PS%" echo $mediumWorker = $env:SPIN_MEDIUM_WORKER -eq '1'
>> "%SPIN_PS%" echo [int]$timeoutSeconds = 0
>> "%SPIN_PS%" echo if (-not [int]::TryParse($env:SPIN_TIMEOUT_SECONDS, [ref]$timeoutSeconds) -or $timeoutSeconds -lt 1) { $timeoutSeconds = 1800 }
>> "%SPIN_PS%" echo $wrapper = Join-Path $env:EXEC_TEMP ('cp_setup_install_' + [guid]::NewGuid().ToString('N') + '.cmd')
>> "%SPIN_PS%" echo $q = [char]34
>> "%SPIN_PS%" echo $esc = [char]27
>> "%SPIN_PS%" echo $cr = [char]13
>> "%SPIN_PS%" echo $clear = $esc + '[2K'
>> "%SPIN_PS%" echo $consoleWidth = try { [Math]::Max^(20,[Console]::BufferWidth^) } catch { 80 }
>> "%SPIN_PS%" echo function Shorten^([string]$value,[int]$limit^) { if ^(-not $value -or $limit -lt 4^) { return '' }; if ^($value.Length -le $limit^) { return $value }; return $value.Substring^(0,$limit-3^) + '...' }
>> "%SPIN_PS%" echo function Fit-Line^([string]$name,[string]$detail,[int]$statusLength,[bool]$hasFrame^) { $fixed=$statusLength+3; if^($hasFrame^){$fixed+=2}; $nameBudget=[Math]::Max^(4,$consoleWidth-1-$fixed^); $shownName=Shorten $name $nameBudget; $detailBudget=$consoleWidth-1-$fixed-$shownName.Length-3; $shownDetail=if^($detailBudget-ge 8^){Shorten $detail $detailBudget}else{''}; [pscustomobject]@{Name=$shownName;Detail=$shownDetail} }
>> "%SPIN_PS%" echo $action = '[' + $esc + '[38;5;153m' + $env:SPIN_ACTION + $esc + '[0m]'
>> "%SPIN_PS%" echo $success = '[' + $esc + '[38;5;114m' + $env:SPIN_SUCCESS + $esc + '[0m]'
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $log,$wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($progressFile) { Remove-Item -LiteralPath $progressFile -ErrorAction SilentlyContinue }
>> "%SPIN_PS%" echo $runLine = [string]('call ' + $cmd + ' 1^>' + $q + $log + $q + ' 2^>^&1')
>> "%SPIN_PS%" echo $lines = @('@echo off',$runLine,'exit /b %%ERRORLEVEL%%')
>> "%SPIN_PS%" echo [IO.File]::WriteAllLines($wrapper, $lines)
>> "%SPIN_PS%" echo $arguments = '/d /s /c ""' + $wrapper + '""'
>> "%SPIN_PS%" echo $process = Start-Process -FilePath $env:CMD_EXE -ArgumentList $arguments -WorkingDirectory $env:EXEC_TEMP -WindowStyle Hidden -PassThru
>> "%SPIN_PS%" echo $frames = @([char]92,'-','/','^|')
>> "%SPIN_PS%" echo $i = 0
>> "%SPIN_PS%" echo $started = [Diagnostics.Stopwatch]::StartNew()
>> "%SPIN_PS%" echo $timedOut = $false
>> "%SPIN_PS%" echo while (-not $process.HasExited) { $detail = $hint; if ($progressFile -and (Test-Path -LiteralPath $progressFile)) { try { $progress = (Get-Content -LiteralPath $progressFile -First 1 -ErrorAction Stop).Trim(); if ($progress) { $detail = $progress } } catch {} } elseif ($mediumWorker -and (Test-Path -LiteralPath $log)) { try { foreach ($line in @(Get-Content -LiteralPath $log -Tail 32 -ErrorAction Stop)) { if ($line -match '^\[MASON ([^\x00-\x1f\x7f]{1,160})\]$') { $detail = $Matches[1] } } } catch {} }; $fitted=Fit-Line $label $detail $env:SPIN_ACTION.Length $true; $text = $action + ' ' + $frames[$i %% $frames.Count] + ' ' + $fitted.Name; if ($fitted.Detail) { $text += ' (' + $fitted.Detail + ')' }; Write-Host -NoNewline ($cr + $clear + $text); [Console]::Out.Flush(); if ($timeoutSeconds -gt 0 -and $started.Elapsed.TotalSeconds -ge $timeoutSeconds) { $timedOut = $true; Stop-CpProcessTree $process $env:TASKKILL_EXE; try { ('Timed out after ' + $timeoutSeconds + ' seconds.') ^| Add-Content -LiteralPath $log -ErrorAction Stop } catch {}; break }; Start-Sleep -Milliseconds 100; $i++ }
>> "%SPIN_PS%" echo if ($timedOut) { $exitCode = 124 } elseif (-not $process.WaitForExit(1000)) { Stop-CpProcessTree $process $env:TASKKILL_EXE; $exitCode=124 } else { $exitCode = $process.ExitCode }
>> "%SPIN_PS%" echo $finalDetail = $null
>> "%SPIN_PS%" echo if ($progressFile -and (Test-Path -LiteralPath $progressFile)) { try { $finalDetail = (Get-Content -LiteralPath $progressFile -First 1 -ErrorAction Stop).Trim() } catch {} }
>> "%SPIN_PS%" echo if (-not $finalDetail -and $mediumWorker -and (Test-Path -LiteralPath $log)) { try { foreach ($line in @(Get-Content -LiteralPath $log -Tail 32 -ErrorAction Stop)) { if ($line -match '^\[MASON ([^\x00-\x1f\x7f]{1,160})\]$') { $finalDetail = $Matches[1] } } } catch {} }
>> "%SPIN_PS%" echo Remove-Item -LiteralPath $wrapper -ErrorAction SilentlyContinue
>> "%SPIN_PS%" echo if ($progressFile) { Remove-Item -LiteralPath $progressFile -ErrorAction SilentlyContinue }
>> "%SPIN_PS%" echo if ($exitCode -eq 0 -and $deferSuccess) { Write-Host -NoNewline ($cr + $clear) } else { $statusLength=if($exitCode-eq 0){$env:SPIN_SUCCESS.Length}else{6}; $fitted=Fit-Line $label $finalDetail $statusLength $false; if ($exitCode -eq 0) { $finalText = $success + ' ' + $fitted.Name } else { $finalText = '[' + $esc + '[31mFAILED' + $esc + '[0m] ' + $fitted.Name }; if ($fitted.Detail) { $finalText += ' (' + $fitted.Detail + ')' }; Write-Host ($cr + $clear + $finalText) }
>> "%SPIN_PS%" echo exit $exitCode
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%SPIN_PS%"
set "SPIN_EXIT=%ERRORLEVEL%"
if "%SPIN_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%SPIN_PS%" >nul 2>nul
call :publish_component_log "!SPIN_LOG_NAME!"
set "SPIN_PUBLISH_EXIT=!ERRORLEVEL!"
if "!SPIN_EXIT!"=="0" if not "!SPIN_PUBLISH_EXIT!"=="0" set "SPIN_EXIT=1"
set "SPIN_LOG_NAME="
exit /b %SPIN_EXIT%

:run_target_registry_transaction
set "REGISTRY_PLAN_EXIT=1"
set "REGISTRY_WORKER_EXIT=1"
set "REGISTRY_COMMIT_EXIT=1"
set "REGISTRY_TRANSACTION_EXIT=1"
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
set "REGISTRY_WORKER_PS=%EXEC_TEMP%\cp_setup_registry_worker_%RANDOM%_%RANDOM%.ps1"
set "REGISTRY_COMMIT_PS=%EXEC_TEMP%\cp_setup_registry_commit_%RANDOM%_%RANDOM%.ps1"
set "REGISTRY_ROLLBACK_PS=%EXEC_TEMP%\cp_setup_registry_rollback_%RANDOM%_%RANDOM%.ps1"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_REGISTRY_PLAN_PS%" -Mode "%~1" -WorkerScript "%REGISTRY_WORKER_PS%" -CommitScript "%REGISTRY_COMMIT_PS%" -RollbackScript "%REGISTRY_ROLLBACK_PS%"
set "REGISTRY_PLAN_EXIT=%ERRORLEVEL%"
if not "%REGISTRY_PLAN_EXIT%"=="0" goto registry_transaction_cleanup
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%REGISTRY_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60
set "REGISTRY_WORKER_EXIT=%ERRORLEVEL%"
if "%REGISTRY_WORKER_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
if not "%REGISTRY_WORKER_EXIT%"=="0" (
    call :recover_pending_registry >nul 2>nul
    goto registry_transaction_cleanup
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%REGISTRY_COMMIT_PS%"
set "REGISTRY_COMMIT_EXIT=%ERRORLEVEL%"
if "%REGISTRY_COMMIT_EXIT%"=="0" goto registry_transaction_cleanup
call :recover_pending_registry >nul 2>nul
if errorlevel 1 echo [%ESC%[31mFAILED%ESC%[0m] Could not recover target-user registry changes.
:registry_transaction_cleanup
if defined REGISTRY_WORKER_PS del "%REGISTRY_WORKER_PS%" >nul 2>nul
if defined REGISTRY_COMMIT_PS del "%REGISTRY_COMMIT_PS%" >nul 2>nul
if defined REGISTRY_ROLLBACK_PS del "%REGISTRY_ROLLBACK_PS%" >nul 2>nul
if not "%REGISTRY_PLAN_EXIT%"=="0" set "REGISTRY_TRANSACTION_EXIT=%REGISTRY_PLAN_EXIT%"
if "%REGISTRY_PLAN_EXIT%"=="0" if not "%REGISTRY_WORKER_EXIT%"=="0" set "REGISTRY_TRANSACTION_EXIT=%REGISTRY_WORKER_EXIT%"
if "%REGISTRY_PLAN_EXIT%"=="0" if "%REGISTRY_WORKER_EXIT%"=="0" set "REGISTRY_TRANSACTION_EXIT=%REGISTRY_COMMIT_EXIT%"
set "REGISTRY_WORKER_PS="
set "REGISTRY_COMMIT_PS="
set "REGISTRY_ROLLBACK_PS="
exit /b %REGISTRY_TRANSACTION_EXIT%

:install_paths
if /i "%~1"=="check" exit /b 0
call :run_target_registry_transaction "Path"
exit /b %ERRORLEVEL%

:write_target_environment
call :run_target_registry_transaction "Environment"
exit /b %ERRORLEVEL%

:prepare_config_mutation
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$key=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true);if(-not $key){exit 1};$raw=$key.GetValue('Config.MutationStarted',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);if($null -eq $raw){$key.SetValue('Config.MutationStarted',1,[Microsoft.Win32.RegistryValueKind]::DWord)}elseif($key.GetValueKind('Config.MutationStarted') -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$raw -ne 1){exit 1};$key.Dispose();$machine.Dispose();exit 0"
exit /b %ERRORLEVEL%

:prepare_nvim_bootstrap
set "NVIM_STATE_PS=%EXEC_TEMP%\cp_setup_nvim_state_%RANDOM%_%RANDOM%.ps1"
> "%NVIM_STATE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%NVIM_STATE_PS%" echo $option = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
>> "%NVIM_STATE_PS%" echo $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^)
>> "%NVIM_STATE_PS%" echo $state = $machine.OpenSubKey^('Software\my-cp-setup\Users\' + $env:CP_SETUP_TARGET_SID,$true^)
>> "%NVIM_STATE_PS%" echo if ^(-not $state^) { throw 'Protected Neovim state is missing.' }
>> "%NVIM_STATE_PS%" echo try {
>> "%NVIM_STATE_PS%" echo     $names = @^($state.GetValueNames^(^)^)
>> "%NVIM_STATE_PS%" echo     foreach ^($name in @^('Snapshot.Complete','NvimData.Root','NvimData.Existed','Mason.Packages.Before','JdtlsWorkspace.Path','JdtlsWorkspace.Existed'^)^) { if ^($names -notcontains $name^) { throw ^('Incomplete immutable Neovim snapshot: '+$name^) } }
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('Snapshot.Complete'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('Snapshot.Complete',0,$option^) -ne 1^) { throw 'Invalid Neovim snapshot completion state.' }
>> "%NVIM_STATE_PS%" echo     $nvimData = [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_NVIMDATA_ROOT^).TrimEnd^([char]92^)
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('NvimData.Root'^) -ne [Microsoft.Win32.RegistryValueKind]::String -or [IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root',$null,$option^)^).TrimEnd^([char]92^) -ine $nvimData^) { throw 'Protected Neovim data root changed.' }
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('NvimData.Existed'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('NvimData.Existed',-1,$option^) -notin @^(0,1^)^) { throw 'Invalid immutable Neovim data snapshot.' }
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('Mason.Packages.Before'^) -ne [Microsoft.Win32.RegistryValueKind]::MultiString^) { throw 'Invalid immutable Mason inventory kind.' }; $seen=[Collections.Generic.HashSet[string]]::new^([StringComparer]::OrdinalIgnoreCase^); foreach ^($package in @^($state.GetValue^('Mason.Packages.Before',$null,$option^)^)^) { if ^([string]$package -notmatch '^^[A-Za-z0-9._-]+$' -or $package -in @^('.','..'^) -or -not $seen.Add^([string]$package^)^) { throw ^('Invalid immutable Mason inventory entry: '+$package^) } }
>> "%NVIM_STATE_PS%" echo     $setupRoot = [IO.Path]::GetFullPath^($env:ROOT^).TrimEnd^([char]92^); $sha=[Security.Cryptography.SHA256]::Create^(^); try { $rootHash=^([BitConverter]::ToString^($sha.ComputeHash^([Text.UTF8Encoding]::new^($false^).GetBytes^($setupRoot^)^)^)^).Replace^('-',''^).ToLowerInvariant^(^) } finally { $sha.Dispose^(^) }
>> "%NVIM_STATE_PS%" echo     $jdtls = [IO.Path]::GetFullPath^((Join-Path $nvimData ^('jdtls-workspaces\cp-' + $rootHash.Substring^(0,16^)^)^)^)
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('JdtlsWorkspace.Path'^) -ne [Microsoft.Win32.RegistryValueKind]::String -or [IO.Path]::GetFullPath^([string]$state.GetValue^('JdtlsWorkspace.Path',$null,$option^)^) -ine $jdtls^) { throw 'Immutable JDT LS workspace path changed.' }
>> "%NVIM_STATE_PS%" echo     if ^($state.GetValueKind^('JdtlsWorkspace.Existed'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('JdtlsWorkspace.Existed',-1,$option^) -notin @^(0,1^)^) { throw 'Invalid immutable JDT LS workspace snapshot.' }
>> "%NVIM_STATE_PS%" echo     if ^($names -contains 'Nvim.BootstrapStarted'^) { if ^($state.GetValueKind^('Nvim.BootstrapStarted'^) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or [int]$state.GetValue^('Nvim.BootstrapStarted',0,$option^) -ne 1^) { throw 'Invalid Neovim bootstrap state.' } } else { $state.SetValue^('Nvim.BootstrapStarted',1,[Microsoft.Win32.RegistryValueKind]::DWord^) }
>> "%NVIM_STATE_PS%" echo } finally { $state.Dispose^(^); $machine.Dispose^(^) }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%NVIM_STATE_PS%"
set "NVIM_STATE_EXIT=%ERRORLEVEL%"
del "%NVIM_STATE_PS%" >nul 2>nul
set "NVIM_STATE_PS="
exit /b %NVIM_STATE_EXIT%

:activate_target_profile_environment
set "LOCALAPPDATA=%CP_SETUP_TARGET_LOCALAPPDATA%"
set "APPDATA=%CP_SETUP_TARGET_APPDATA%"
set "USERPROFILE=%CP_SETUP_TARGET_PROFILE%"
set "HOME=%CP_SETUP_TARGET_PROFILE%"
for %%I in ("%CP_SETUP_TARGET_PROFILE%") do (
    set "HOMEDRIVE=%%~dI"
    set "HOMEPATH=%%~pI"
)
exit /b 0

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
set "CP_SETUP_ROOT=%ROOT%"
call :run_target_registry_transaction "AutoRun"
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
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not record the resolved path for %~1.
    exit /b 1
)
exit /b 0

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
call :begin_pending_pacman
if errorlevel 1 exit /b 1
set "PACMAN_MISSING_BEFORE=%PACMAN_MISSING%"
set "PACMAN_COMMAND=/usr/bin/pacman -S --needed --noconfirm %PACMAN_REQUESTED%"
call :run_pacman_spinner "INSTALLING" "INSTALLED" "Ruff via pacman" "1"
if errorlevel 1 (
    set "PACMAN_MISSING=!PACMAN_MISSING_BEFORE!"
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] Ruff install failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :validate_msys2_tree
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Installed Ruff files are not protected.
    exit /b 1
)
call :capture_missing_pacman_packages "%PACMAN_REQUESTED%"
if errorlevel 1 exit /b 1
set "PACMAN_VERIFY_MISSING=!PACMAN_MISSING!"
set "PACMAN_MISSING=!PACMAN_MISSING_BEFORE!"
if defined PACMAN_VERIFY_MISSING (
    call :record_partial_pacman_packages
    echo [%ESC%[31mFAILED%ESC%[0m] pacman did not install Ruff.
    echo Log: %VISIBLE_TEMP%\cp_setup_pacman.log
    exit /b 1
)
call :record_pacman_packages
if errorlevel 1 exit /b 1
call :find_ruff quiet
if not errorlevel 1 (
    call :print_installed "Ruff via pacman" "!FOUND_RUFF_PATH!"
    exit /b 0
)
echo [%ESC%[31mFAILED%ESC%[0m] Ruff was installed, but ruff.exe was not found.
exit /b 1

:find_ruff
call :run_tool_finder "ruff" "Ruff" "FOUND_RUFF_PATH" "%~1"
exit /b %ERRORLEVEL%

:refresh_path
if not "%CP_SETUP_PRIVILEGED%"=="1" goto refresh_user_path
set "PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0"
for %%E in ("%FOUND_GIT_PATH%" "%FOUND_NODE_PATH%" "%FOUND_NPM_PATH%" "%FOUND_NVIM_PATH%" "%FOUND_JAVAC_PATH%" "%FOUND_JAVA_PATH%" "%CP_GPP%" "%CP_PYTHON%" "%FOUND_RUFF_PATH%") do if exist "%%~fE" set "PATH=%%~dpE;%PATH%"
exit /b 0
:refresh_user_path
set "USER_PATH_DATA=%EXEC_TEMP%\cp_setup_user_path_%RANDOM%_%RANDOM%.txt"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$o=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames;$lm=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$mk=$lm.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment');$machine=[string]$mk.GetValue('Path','',$o);$hu=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users,[Microsoft.Win32.RegistryView]::Default);$uk=$hu.OpenSubKey($env:CP_SETUP_TARGET_SID+'\Environment');$user=if($uk){[string]$uk.GetValue('Path','',$o)}else{''};[IO.File]::WriteAllText($env:USER_PATH_DATA,$machine+';'+$user,[Text.Encoding]::Unicode);if($uk){$uk.Dispose()};$hu.Dispose();$mk.Dispose();$lm.Dispose()" >nul 2>nul
if errorlevel 1 exit /b 1
for /F "usebackq tokens=* delims=" %%P in ("%USER_PATH_DATA%") do set "PATH=%%P"
del "%USER_PATH_DATA%" >nul 2>nul
set "USER_PATH_DATA="
exit /b 0

:find_python
call :run_tool_finder "python" "Python" "CP_PYTHON" "%~1"
exit /b %ERRORLEVEL%

:find_gpp
call :run_tool_finder "gpp" "g++" "CP_GPP" "%~1"
if errorlevel 1 exit /b %ERRORLEVEL%
for %%I in ("%CP_GPP%") do set "PATH=%%~dpI;%PATH%"
exit /b 0

:check_mason_tools
set "MASON_BIN=%CP_SETUP_TARGET_LOCALAPPDATA%\nvim-data\mason\bin"
call :check_mason_binary "Pyright" "pyright.cmd" "--version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :check_mason_binary "JDT LS" "jdtls.cmd" ""
if errorlevel 1 exit /b %ERRORLEVEL%
call :check_mason_binary "Google Java Format" "google-java-format.cmd" "--version"
if errorlevel 1 exit /b %ERRORLEVEL%
call :check_mason_binary "clangd" "clangd.cmd" "--version"
if errorlevel 1 exit /b %ERRORLEVEL%
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
set "MASON_PROBE_OUT=%EXEC_TEMP%\cp_setup_mason_probe_%RANDOM%_%RANDOM%.out"
set "MASON_PROBE_ERR=%EXEC_TEMP%\cp_setup_mason_probe_%RANDOM%_%RANDOM%.err"
set "SILENT_COMMAND="%MASON_BIN%\%~2" %~3"
set "SILENT_STDOUT=%MASON_PROBE_OUT%"
set "SILENT_STDERR=%MASON_PROBE_ERR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "MASON_PROBE_EXIT=%ERRORLEVEL%"
del "%MASON_PROBE_OUT%" "%MASON_PROBE_ERR%" >nul 2>nul
set "MASON_PROBE_OUT="
set "MASON_PROBE_ERR="
if "%MASON_PROBE_EXIT%"=="124" exit /b 124
if not "%MASON_PROBE_EXIT%"=="0" (
    call :print_missing "Mason %~1 executable"
) else (
    call :print_found "Mason %~1"
)
exit /b 0

:prepare_medium_worker_launcher
if defined MEDIUM_LAUNCHER_PS if defined MEDIUM_NATIVE_CS if defined MEDIUM_REGISTRY_PLAN_PS if exist "%MEDIUM_LAUNCHER_PS%" if exist "%MEDIUM_NATIVE_CS%" if exist "%MEDIUM_REGISTRY_PLAN_PS%" exit /b 0
set "MEDIUM_LAUNCHER_PS=%EXEC_TEMP%\cp_setup_medium_launcher_%RANDOM%_%RANDOM%.ps1"
set "MEDIUM_NATIVE_CS=%EXEC_TEMP%\cp_setup_medium_native_%RANDOM%_%RANDOM%.cs"
set "MEDIUM_REGISTRY_PLAN_PS=%EXEC_TEMP%\cp_setup_medium_registry_%RANDOM%_%RANDOM%.ps1"
set "MEDIUM_EXTRACT_PS=%EXEC_TEMP%\cp_setup_medium_extract_%RANDOM%_%RANDOM%.ps1"
> "%MEDIUM_EXTRACT_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MEDIUM_EXTRACT_PS%" echo $lines = [IO.File]::ReadAllLines^($env:INSTALL_SCRIPT^)
>> "%MEDIUM_EXTRACT_PS%" echo function Export-Block^([string]$begin, [string]$end, [string]$destination^) {
>> "%MEDIUM_EXTRACT_PS%" echo     $first = [Array]::IndexOf^($lines, '::' + $begin^)
>> "%MEDIUM_EXTRACT_PS%" echo     $last = [Array]::IndexOf^($lines, '::' + $end^)
>> "%MEDIUM_EXTRACT_PS%" echo     if ^($first -lt 0 -or $last -le $first^) { throw ^('Missing protected source block: ' + $begin^) }
>> "%MEDIUM_EXTRACT_PS%" echo     $content = [Collections.Generic.List[string]]::new^(^)
>> "%MEDIUM_EXTRACT_PS%" echo     for ^($i = $first + 1; $i -lt $last; $i++^) { if ^(-not $lines[$i].StartsWith^('::',[StringComparison]::Ordinal^)^) { throw 'Malformed protected source block.' }; $content.Add^($lines[$i].Substring^(2^)^) }
>> "%MEDIUM_EXTRACT_PS%" echo     [IO.File]::WriteAllLines^($destination, $content, [Text.UTF8Encoding]::new^($false^)^)
>> "%MEDIUM_EXTRACT_PS%" echo }
>> "%MEDIUM_EXTRACT_PS%" echo Export-Block '__CP_MEDIUM_LAUNCHER_BEGIN__' '__CP_MEDIUM_LAUNCHER_END__' $env:MEDIUM_LAUNCHER_PS
>> "%MEDIUM_EXTRACT_PS%" echo Export-Block '__CP_MEDIUM_NATIVE_BEGIN__' '__CP_MEDIUM_NATIVE_END__' $env:MEDIUM_NATIVE_CS
>> "%MEDIUM_EXTRACT_PS%" echo Export-Block '__CP_USER_REGISTRY_PLAN_BEGIN__' '__CP_USER_REGISTRY_PLAN_END__' $env:MEDIUM_REGISTRY_PLAN_PS
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_EXTRACT_PS%"
set "MEDIUM_EXTRACT_EXIT=%ERRORLEVEL%"
del "%MEDIUM_EXTRACT_PS%" >nul 2>nul
set "MEDIUM_EXTRACT_PS="
if not "%MEDIUM_EXTRACT_EXIT%"=="0" exit /b %MEDIUM_EXTRACT_EXIT%
if not exist "%MEDIUM_LAUNCHER_PS%" exit /b 1
if not exist "%MEDIUM_NATIVE_CS%" exit /b 1
if not exist "%MEDIUM_REGISTRY_PLAN_PS%" exit /b 1
exit /b 0

:prepare_nvim_worktree_guard
call :cleanup_nvim_worktree_guard
set "NVIM_WORKTREE_PS=%EXEC_TEMP%\cp_setup_worktree_%RANDOM%_%RANDOM%.ps1"
set "NVIM_WORKTREE_SNAPSHOT=%EXEC_TEMP%\cp_setup_worktree_%RANDOM%_%RANDOM%.snapshot"
> "%NVIM_WORKTREE_PS%" echo param^([ValidateSet^('capture','verify'^)][string]$Mode,[string]$Root,[string]$Snapshot^)
>> "%NVIM_WORKTREE_PS%" echo $ErrorActionPreference = 'Stop'
>> "%NVIM_WORKTREE_PS%" echo $rootPath = [IO.Path]::GetFullPath^($Root^).TrimEnd^([char]92^)
>> "%NVIM_WORKTREE_PS%" echo $gitPath = [IO.Path]::GetFullPath^((Join-Path $rootPath '.git'^)^).TrimEnd^([char]92^)
>> "%NVIM_WORKTREE_PS%" echo $rootItem = Get-Item -LiteralPath $rootPath -Force -ErrorAction Stop
>> "%NVIM_WORKTREE_PS%" echo if ^(-not $rootItem.PSIsContainer -or ^($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw 'Unsafe setup worktree root.' }
>> "%NVIM_WORKTREE_PS%" echo $manifest = [Collections.Generic.List[string]]::new^(^)
>> "%NVIM_WORKTREE_PS%" echo $stack = [Collections.Generic.Stack[IO.DirectoryInfo]]::new^(^); $stack.Push^([IO.DirectoryInfo]$rootItem^)
>> "%NVIM_WORKTREE_PS%" echo while ^($stack.Count^) {
>> "%NVIM_WORKTREE_PS%" echo     $directory = $stack.Pop^(^)
>> "%NVIM_WORKTREE_PS%" echo     foreach ^($item in @^($directory.GetFileSystemInfos^(^) ^| Sort-Object Name^)^) {
>> "%NVIM_WORKTREE_PS%" echo         $full = [IO.Path]::GetFullPath^($item.FullName^); if ^($full -ieq $gitPath^) { continue }
>> "%NVIM_WORKTREE_PS%" echo         if ^($full -ine $rootPath -and -not $full.StartsWith^($rootPath + [char]92,[StringComparison]::OrdinalIgnoreCase^)^) { throw ^('Worktree entry escaped the setup root: '+$full^) }
>> "%NVIM_WORKTREE_PS%" echo         $relative = $full.Substring^($rootPath.Length^).TrimStart^([char]92^).Replace^([char]92,[char]47^)
>> "%NVIM_WORKTREE_PS%" echo         if ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^) { throw ^('Reparse point blocks worktree verification: '+$relative^) }
>> "%NVIM_WORKTREE_PS%" echo         if ^($item -is [IO.DirectoryInfo]^) { $manifest.Add^('D^|' + $relative + '^|' + [int]$item.Attributes^); $stack.Push^($item^); continue }
>> "%NVIM_WORKTREE_PS%" echo         $stream = [IO.File]::Open^($full,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read^); $sha=[Security.Cryptography.SHA256]::Create^(^)
>> "%NVIM_WORKTREE_PS%" echo         try { $hash = ^([BitConverter]::ToString^($sha.ComputeHash^($stream^)^)^).Replace^('-',''^).ToLowerInvariant^(^) } finally { $sha.Dispose^(^); $stream.Dispose^(^) }
>> "%NVIM_WORKTREE_PS%" echo         $item.Refresh^(^); $manifest.Add^('F^|' + $relative + '^|' + [int]$item.Attributes + '^|' + $item.Length + '^|' + $hash^)
>> "%NVIM_WORKTREE_PS%" echo     }
>> "%NVIM_WORKTREE_PS%" echo }
>> "%NVIM_WORKTREE_PS%" echo $manifest.Sort^([StringComparer]::OrdinalIgnoreCase^)
>> "%NVIM_WORKTREE_PS%" echo if ^($Mode -eq 'capture'^) { [IO.File]::WriteAllLines^($Snapshot,$manifest,[Text.UTF8Encoding]::new^($false^)^); exit 0 }
>> "%NVIM_WORKTREE_PS%" echo if ^(-not [IO.File]::Exists^($Snapshot^)^) { throw 'Missing setup worktree snapshot.' }; $before=[IO.File]::ReadAllLines^($Snapshot^)
>> "%NVIM_WORKTREE_PS%" echo if ^($before.Length -ne $manifest.Count^) { throw 'The setup worktree changed during Neovim bootstrap.' }; for ^($i=0; $i -lt $before.Length; $i++^) { if ^($before[$i] -cne $manifest[$i]^) { throw 'The setup worktree changed during Neovim bootstrap.' } }
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%NVIM_WORKTREE_PS%" -Mode capture -Root "%ROOT%" -Snapshot "%NVIM_WORKTREE_SNAPSHOT%"
set "NVIM_WORKTREE_EXIT=%ERRORLEVEL%"
if not "%NVIM_WORKTREE_EXIT%"=="0" call :cleanup_nvim_worktree_guard
exit /b %NVIM_WORKTREE_EXIT%

:verify_nvim_worktree_guard
if not defined NVIM_WORKTREE_PS exit /b 1
if not defined NVIM_WORKTREE_SNAPSHOT exit /b 1
if not exist "%NVIM_WORKTREE_PS%" exit /b 1
if not exist "%NVIM_WORKTREE_SNAPSHOT%" exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%NVIM_WORKTREE_PS%" -Mode verify -Root "%ROOT%" -Snapshot "%NVIM_WORKTREE_SNAPSHOT%"
exit /b %ERRORLEVEL%

:cleanup_nvim_worktree_guard
if defined NVIM_WORKTREE_PS del "%NVIM_WORKTREE_PS%" >nul 2>nul
if defined NVIM_WORKTREE_SNAPSHOT del "%NVIM_WORKTREE_SNAPSHOT%" >nul 2>nul
set "NVIM_WORKTREE_PS="
set "NVIM_WORKTREE_SNAPSHOT="
exit /b 0

:create_nvim_medium_worker
set "MEDIUM_WORKER_MODE=%~1"
set "MEDIUM_WORKER_INPUT=%~2"
set "MEDIUM_WORKER_PS=%EXEC_TEMP%\cp_setup_nvim_worker_%RANDOM%_%RANDOM%.ps1"
set "MEDIUM_WORKER_BUILD_PS=%EXEC_TEMP%\cp_setup_nvim_worker_build_%RANDOM%_%RANDOM%.ps1"
> "%MEDIUM_WORKER_BUILD_PS%" echo $ErrorActionPreference = 'Stop'
>> "%MEDIUM_WORKER_BUILD_PS%" echo function Q^([string]$value^) { if ^($null -eq $value^) { return "''" }; return "'" + $value.Replace^("'","''"^) + "'" }
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines = [Collections.Generic.List[string]]::new^(^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$ErrorActionPreference = ''Stop'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$identity = [Security.Principal.WindowsIdentity]::GetCurrent^(^)'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('if ^($identity.User.Value -ine ' + ^(Q $env:CP_SETUP_TARGET_SID^) + '^) { throw ''Neovim worker SID mismatch.'' }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('if ^(^(^[Security.Principal.WindowsPrincipal]::new^($identity^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)^) { throw ''Neovim worker unexpectedly has an elevated token.'' }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$root = ' + ^(Q $env:ROOT^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$nvim = ' + ^(Q $env:FOUND_NVIM_PATH^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$lockfile = [IO.Path]::GetFullPath^((Join-Path $root ''nvim\lazy-lock.json''^)^)'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$configRoot = [IO.Path]::GetFullPath^((Join-Path $root ''nvim''^)^).TrimEnd^([char]92^) + [char]92'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('if ^(-not $lockfile.StartsWith^($configRoot,[StringComparison]::OrdinalIgnoreCase^) -or -not [IO.File]::Exists^($lockfile^) -or ^([IO.File]::GetAttributes^($lockfile^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw ''Unsafe Lazy lockfile.'' }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:XDG_CONFIG_HOME = $root'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:CP_SETUP_ROOT = $root'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:CP_MASON_BOOTSTRAP = ''1'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:CP_SETUP_LAZY_LOCKFILE = $null'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo foreach ^($name in @^('CP_GPP','CP_PYTHON','CP_JAVAC','CP_JAVA'^)^) { $lines.Add^('$env:' + $name + ' = ' + ^(Q ^([Environment]::GetEnvironmentVariable^($name,'Process'^)^)^)^) }
>> "%MEDIUM_WORKER_BUILD_PS%" echo $tools=@^($env:FOUND_GIT_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH,$env:FOUND_NVIM_PATH^); $pathParts=[Collections.Generic.List[string]]::new^(^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo foreach ^($tool in $tools^) { if ^([string]::IsNullOrWhiteSpace^($tool^) -or -not [IO.File]::Exists^($tool^) -or ^([IO.File]::GetAttributes^($tool^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^('Missing or unsafe validated Neovim dependency: '+$tool^) }; $directory=[IO.Path]::GetFullPath^((Split-Path -Parent $tool^)^).TrimEnd^([char]92^); if ^(-not @^($pathParts ^| Where-Object { $_ -ieq $directory }^)^) { $pathParts.Add^($directory^) } }
>> "%MEDIUM_WORKER_BUILD_PS%" echo $system32=[IO.Path]::GetFullPath^($env:SYSTEM32_DIR^).TrimEnd^([char]92^); if ^(-not [IO.Directory]::Exists^($system32^) -or ^([IO.File]::GetAttributes^($system32^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw 'Missing or unsafe System32 dependency.' }; if ^(-not @^($pathParts ^| Where-Object { $_ -ieq $system32 }^)^) { $pathParts.Add^($system32^) }; $pathPrefix=$pathParts -join ';'
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:PATH = ' + ^(Q $pathPrefix^) + ' + '';'' + [Environment]::GetEnvironmentVariable^(''PATH'',''Process''^)'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:PATHEXT = ''.COM;.EXE;.BAT;.CMD'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo foreach ^($name in @^('NODE_OPTIONS','NODE_PATH','JAVA_TOOL_OPTIONS','JDK_JAVA_OPTIONS','JDK_JAVAC_OPTIONS','_JAVA_OPTIONS','CLASSPATH','PYTHONHOME','PYTHONPATH','GIT_EXEC_PATH','GIT_CONFIG_PARAMETERS','GIT_CONFIG_COUNT','BASH_ENV','ENV','SHELLOPTS','BASHOPTS','VIMINIT','EXINIT','NVIM_APPNAME','LUA_PATH','LUA_CPATH'^)^) { $lines.Add^('$env:'+$name+' = $null'^) }
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$env:GIT_CONFIG_GLOBAL = ''NUL''; $env:GIT_CONFIG_NOSYSTEM = ''1''; $env:GIT_TERMINAL_PROMPT = ''0'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('Set-Location -LiteralPath $root'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$lockHandle = [IO.File]::Open^($lockfile,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read^)'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('try {'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo if ^($env:MEDIUM_WORKER_MODE -eq 'lazy'^) {
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $targetLocal = [IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_LOCALAPPDATA^).TrimEnd^([char]92^); $targetTemp = [IO.Path]::GetFullPath^((Join-Path $targetLocal 'Temp'^)^).TrimEnd^([char]92^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$targetLocal = ' + ^(Q $targetLocal^) + '; $targetTemp = ' + ^(Q $targetTemp^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('if ^($targetTemp -ine [IO.Path]::GetFullPath^((Join-Path $targetLocal ''Temp''^)^).TrimEnd^([char]92^)^) { throw ''Unexpected target temporary directory.'' }; foreach ^($path in @^($targetLocal,$targetTemp^)^) { if ^(-not [IO.Directory]::Exists^($path^)^) { throw ^(''Missing target directory: ''+$path^) }; $rootPath=[IO.Path]::GetPathRoot^($path^); $current=$rootPath.TrimEnd^([char]92^); foreach ^($part in $path.Substring^($rootPath.Length^).Split^([char]92,[StringSplitOptions]::RemoveEmptyEntries^)^) { $current=Join-Path $current $part; $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop; if ^(-not $item.PSIsContainer -or ^($item.Attributes -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^(''Unsafe target temporary path component: ''+$current^) } } }'^)
    >> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$lazyRoot=[IO.Path]::GetFullPath^((Join-Path $targetTemp ''nvim''^)^).TrimEnd^([char]92^); if ^(-not $lazyRoot.StartsWith^($targetTemp+[char]92,[StringComparison]::OrdinalIgnoreCase^)^) { throw ''Temporary Lazy root escaped target Temp.'' }; if ^(Test-Path -LiteralPath $lazyRoot^) { $lazyRootItem=Get-Item -LiteralPath $lazyRoot -Force -ErrorAction Stop; if ^(-not $lazyRootItem.PSIsContainer -or ^($lazyRootItem.Attributes-band[IO.FileAttributes]::ReparsePoint^)^) { throw ''Unsafe temporary Lazy root.'' } } else { [void][IO.Directory]::CreateDirectory^($lazyRoot^) }; $lazyLock=[IO.Path]::GetFullPath^((Join-Path $lazyRoot ''cp_setup_lazy_lock.json''^)^)'^)
    >> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('try { $sourceStream=[IO.File]::Open^($lockfile,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read^); try { $targetStream=[IO.File]::Open^($lazyLock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None^); try { $sourceStream.CopyTo^($targetStream^) } finally { $targetStream.Dispose^(^) } } finally { $sourceStream.Dispose^(^) }; if ^([IO.File]::GetAttributes^($lazyLock^) -band [IO.FileAttributes]::ReparsePoint^) { throw ''Unsafe temporary Lazy lockfile.'' }; $env:CP_SETUP_LAZY_LOCKFILE=$lazyLock; ^& $nvim ''--headless'' ''+Lazy^! restore'' ''+qa'' } finally { $env:CP_SETUP_LAZY_LOCKFILE=$null; Remove-Item -LiteralPath $lazyLock -Force -ErrorAction SilentlyContinue; if ^(Test-Path -LiteralPath $lazyLock^) { throw ''Temporary Lazy lockfile cleanup failed.'' } }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo } elseif ^($env:MEDIUM_WORKER_MODE -eq 'mason'^) {
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $inputPath = [IO.Path]::GetFullPath^($env:MEDIUM_WORKER_INPUT^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $execRoot = [IO.Path]::GetFullPath^($env:EXEC_TEMP^).TrimEnd^([char]92^) + [char]92
>> "%MEDIUM_WORKER_BUILD_PS%" echo     if ^(-not $inputPath.StartsWith^($execRoot,[StringComparison]::OrdinalIgnoreCase^) -or -not [IO.File]::Exists^($inputPath^) -or ^([IO.File]::GetAttributes^($inputPath^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw 'Unsafe Mason bootstrap input.' }
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $luaBase64 = [Convert]::ToBase64String^([IO.File]::ReadAllBytes^($inputPath^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$luaBase64 = ' + ^(Q $luaBase64^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$expression = ''lua assert(load(vim.base64.decode([==['' + $luaBase64 + '']==]), "@cp-setup-mason"))()'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('^& $nvim ''--headless'' ''-c'' $expression'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo } elseif ^($env:MEDIUM_WORKER_MODE -eq 'verify'^) {
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $masonBin = [IO.Path]::GetFullPath^((Join-Path $env:CP_SETUP_TARGET_LOCALAPPDATA 'nvim-data\mason\bin'^)^).TrimEnd^([char]92^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$masonBin = ' + ^(Q $masonBin^)^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$commands = @^(''pyright.cmd'',''google-java-format.cmd'',''clangd.cmd''^)'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('foreach ^($name in @^(''pyright.cmd'',''jdtls.cmd'',''google-java-format.cmd'',''clangd.cmd''^)^) { $path=Join-Path $masonBin $name; if ^(-not [IO.File]::Exists^($path^) -or ^([IO.File]::GetAttributes^($path^) -band [IO.FileAttributes]::ReparsePoint^)^) { throw ^(''Missing or unsafe Mason executable: ''+$name^) } }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$jdtls=Join-Path $masonBin ''..\packages\jdtls''; if ^(-not ^(Test-Path -LiteralPath ^(Join-Path $jdtls ''config_win''^) -PathType Container^) -or -not @^(Get-ChildItem -LiteralPath ^(Join-Path $jdtls ''plugins''^) -Filter ''org.eclipse.equinox.launcher_*.jar'' -File -Force -ErrorAction Stop^).Count^) { throw ''JDT LS installation is incomplete.'' }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('foreach ^($name in $commands^) { ^& ^(Join-Path $masonBin $name^) ''--version''; if ^($LASTEXITCODE -ne 0^) { throw ^(''Mason executable failed: ''+$name^) } }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('$expression = ''lua for _,tool in ipairs^({"pyright-langserver","jdtls","google-java-format","clangd"}^) do assert^(vim.fn.executable^(tool^)==1, tool.." is not executable"^) end'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo     $lines.Add^('^& $nvim ''--headless'' ''-c'' $expression ''+qa'''^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo } else { throw 'Unknown Neovim worker mode.' }
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('} finally { $lockHandle.Dispose^(^) }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('$code = if ($null -eq $LASTEXITCODE) { 1 } else { [int]$LASTEXITCODE }'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $lines.Add^('exit $code'^)
>> "%MEDIUM_WORKER_BUILD_PS%" echo $source = $lines -join [Environment]::NewLine
>> "%MEDIUM_WORKER_BUILD_PS%" echo $encodedLength = [Convert]::ToBase64String^([Text.Encoding]::Unicode.GetBytes^($source^)^).Length
>> "%MEDIUM_WORKER_BUILD_PS%" echo if ^($encodedLength + $env:POWERSHELL_EXE.Length + 128 -ge 32760^) { throw 'Neovim worker exceeds the Windows command-line limit.' }
>> "%MEDIUM_WORKER_BUILD_PS%" echo [IO.File]::WriteAllText^($env:MEDIUM_WORKER_PS, $source, [Text.UTF8Encoding]::new^($false^)^)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_WORKER_BUILD_PS%"
set "MEDIUM_WORKER_BUILD_EXIT=%ERRORLEVEL%"
del "%MEDIUM_WORKER_BUILD_PS%" >nul 2>nul
set "MEDIUM_WORKER_BUILD_PS="
set "MEDIUM_WORKER_MODE="
set "MEDIUM_WORKER_INPUT="
if not "%MEDIUM_WORKER_BUILD_EXIT%"=="0" exit /b %MEDIUM_WORKER_BUILD_EXIT%
if not exist "%MEDIUM_WORKER_PS%" exit /b 1
exit /b 0

:bootstrap_nvim_tools
call :activate_target_profile_environment
call :begin_pending_mason
if errorlevel 1 exit /b 1
call :capture_missing_mason_packages
if errorlevel 1 exit /b 1
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
call :prepare_nvim_worktree_guard
if errorlevel 1 exit /b 1
set "CP_MASON_BOOTSTRAP=1"
call :create_nvim_medium_worker "lazy"
if errorlevel 1 (
    call :cleanup_nvim_worktree_guard
    exit /b 1
)
set "INSTALL_CMD="%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%MEDIUM_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 590 -OperationKind Lazy"
set "SPIN_MEDIUM_WORKER=1"
set "SPIN_TIMEOUT_SECONDS=600"
call :run_install_spinner "LazyVim plugins" "this may take a while" "%VISIBLE_TEMP%\cp_setup_nvim.log"
set "LAZY_BOOTSTRAP_EXIT=%ERRORLEVEL%"
call :verify_nvim_worktree_guard >> "%EXEC_TEMP%\cp_setup_nvim.log" 2>&1
if errorlevel 1 set "LAZY_BOOTSTRAP_EXIT=1"
call :publish_component_log "cp_setup_nvim.log"
if errorlevel 1 set "LAZY_BOOTSTRAP_EXIT=1"
del "%MEDIUM_WORKER_PS%" >nul 2>nul
set "MEDIUM_WORKER_PS="
set "SPIN_MEDIUM_WORKER="
set "SPIN_TIMEOUT_SECONDS="
if not "%LAZY_BOOTSTRAP_EXIT%"=="0" (
    set "CP_MASON_BOOTSTRAP="
    call :record_mason_packages progress
    call :cleanup_nvim_worktree_guard
    echo [%ESC%[31mFAILED%ESC%[0m] LazyVim plugin bootstrap failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_nvim.log
    exit /b 1
)
call :verify_mason_tools
set "MASON_VERIFY_EXIT=%ERRORLEVEL%"
if "%MASON_VERIFY_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
call :verify_nvim_worktree_guard >> "%EXEC_TEMP%\cp_setup_nvim.log" 2>&1
if errorlevel 1 set "MASON_VERIFY_EXIT=1"
call :publish_component_log "cp_setup_nvim.log"
if errorlevel 1 set "MASON_VERIFY_EXIT=1"
if "%MASON_VERIFY_EXIT%"=="0" (
    set "CP_MASON_BOOTSTRAP="
    call :record_mason_packages
    if errorlevel 1 (
        call :cleanup_nvim_worktree_guard
        echo [%ESC%[31mFAILED%ESC%[0m] Could not record setup-owned Mason packages.
        exit /b 1
    )
    call :cleanup_nvim_worktree_guard
    call :print_found "Neovim language tools"
    exit /b 0
)
set "MASON_BOOTSTRAP_LUA=%EXEC_TEMP%\cp_setup_mason_%RANDOM%_%RANDOM%.lua"
> "%MASON_BOOTSTRAP_LUA%" echo local names = { "pyright", "jdtls", "google-java-format", "clangd" }
>> "%MASON_BOOTSTRAP_LUA%" echo local handles = {}
>> "%MASON_BOOTSTRAP_LUA%" echo local progress_file = vim.env.SPIN_PROGRESS_FILE
>> "%MASON_BOOTSTRAP_LUA%" echo local function describe(value)
>> "%MASON_BOOTSTRAP_LUA%" echo   if type(value) == "string" then return value end
>> "%MASON_BOOTSTRAP_LUA%" echo   local ok, text = pcall(vim.inspect, value)
>> "%MASON_BOOTSTRAP_LUA%" echo   return ok and text or tostring(value)
>> "%MASON_BOOTSTRAP_LUA%" echo end
>> "%MASON_BOOTSTRAP_LUA%" echo local function write_progress(text)
>> "%MASON_BOOTSTRAP_LUA%" echo   pcall(vim.api.nvim_out_write, "[MASON " .. text .. "]\n")
>> "%MASON_BOOTSTRAP_LUA%" echo   if progress_file and progress_file ~= "" then pcall(vim.fn.writefile, { text }, progress_file) end
>> "%MASON_BOOTSTRAP_LUA%" echo end
>> "%MASON_BOOTSTRAP_LUA%" echo local function stop_active()
>> "%MASON_BOOTSTRAP_LUA%" echo   for _, handle in ipairs(handles) do if not handle:is_closed() then pcall(function() handle:terminate() end) end end
>> "%MASON_BOOTSTRAP_LUA%" echo   vim.wait(5000, function()
>> "%MASON_BOOTSTRAP_LUA%" echo     for _, handle in ipairs(handles) do if not handle:is_closed() then return false end end
>> "%MASON_BOOTSTRAP_LUA%" echo     return true
>> "%MASON_BOOTSTRAP_LUA%" echo   end, 50)
>> "%MASON_BOOTSTRAP_LUA%" echo end
>> "%MASON_BOOTSTRAP_LUA%" echo local ok, err = xpcall(function()
>> "%MASON_BOOTSTRAP_LUA%" echo   local registry = require("mason-registry")
>> "%MASON_BOOTSTRAP_LUA%" echo   local total, completed, failure = #names, 0, nil
>> "%MASON_BOOTSTRAP_LUA%" echo   local state = {}
>> "%MASON_BOOTSTRAP_LUA%" echo   local function report(name, status)
>> "%MASON_BOOTSTRAP_LUA%" echo     write_progress(("%%d/%%d %%s %%s"):format(completed, total, name, status))
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   local function fail(name, reason)
>> "%MASON_BOOTSTRAP_LUA%" echo     if failure then return end
>> "%MASON_BOOTSTRAP_LUA%" echo     failure = name .. ": " .. describe(reason)
>> "%MASON_BOOTSTRAP_LUA%" echo     if progress_file and progress_file ~= "" then pcall(vim.fn.writefile, { "FAILED " .. name }, progress_file) end
>> "%MASON_BOOTSTRAP_LUA%" echo     pcall(vim.api.nvim_err_writeln, failure)
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   local function done(name, status)
>> "%MASON_BOOTSTRAP_LUA%" echo     if state[name] == "done" then return end
>> "%MASON_BOOTSTRAP_LUA%" echo     state[name] = "done"
>> "%MASON_BOOTSTRAP_LUA%" echo     completed = completed + 1
>> "%MASON_BOOTSTRAP_LUA%" echo     report(name, status)
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   local function ready(package)
>> "%MASON_BOOTSTRAP_LUA%" echo     if package:is_installing() or not package:is_installed() then return false end
>> "%MASON_BOOTSTRAP_LUA%" echo     local receipt_ok, present = pcall(function() return package:get_receipt():is_present() end)
>> "%MASON_BOOTSTRAP_LUA%" echo     return receipt_ok and present
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   local start_install
>> "%MASON_BOOTSTRAP_LUA%" echo   local function install_result(name, package, success, result, forced)
>> "%MASON_BOOTSTRAP_LUA%" echo     if state[name] == "done" or state[name] == "failed" then return end
>> "%MASON_BOOTSTRAP_LUA%" echo     if success then done(name, forced and "repaired" or "installed") return end
>> "%MASON_BOOTSTRAP_LUA%" echo     local message = describe(result)
>> "%MASON_BOOTSTRAP_LUA%" echo     if not forced and message:lower():find("already linked", 1, true) then
>> "%MASON_BOOTSTRAP_LUA%" echo       state[name] = "repairing"
>> "%MASON_BOOTSTRAP_LUA%" echo       report(name, "repairing stale links")
>> "%MASON_BOOTSTRAP_LUA%" echo       vim.schedule(function() start_install(name, package, true) end)
>> "%MASON_BOOTSTRAP_LUA%" echo     else
>> "%MASON_BOOTSTRAP_LUA%" echo       state[name] = "failed"
>> "%MASON_BOOTSTRAP_LUA%" echo       fail(name, message)
>> "%MASON_BOOTSTRAP_LUA%" echo     end
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   start_install = function(name, package, forced)
>> "%MASON_BOOTSTRAP_LUA%" echo     if failure then return end
>> "%MASON_BOOTSTRAP_LUA%" echo     state[name] = forced and "repairing" or "installing"
>> "%MASON_BOOTSTRAP_LUA%" echo     if not forced then report(name, "installing") end
>> "%MASON_BOOTSTRAP_LUA%" echo     local started_ok, handle_or_error = pcall(function()
>> "%MASON_BOOTSTRAP_LUA%" echo       return package:install({ force = forced }, function(success, result)
>> "%MASON_BOOTSTRAP_LUA%" echo         vim.schedule(function() install_result(name, package, success, result, forced) end)
>> "%MASON_BOOTSTRAP_LUA%" echo       end)
>> "%MASON_BOOTSTRAP_LUA%" echo     end)
>> "%MASON_BOOTSTRAP_LUA%" echo     if started_ok then handles[#handles + 1] = handle_or_error else state[name] = "failed" fail(name, handle_or_error) end
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   local function watch(name, package)
>> "%MASON_BOOTSTRAP_LUA%" echo     local event_result = nil
>> "%MASON_BOOTSTRAP_LUA%" echo     local on_success, on_failed
>> "%MASON_BOOTSTRAP_LUA%" echo     local function detach()
>> "%MASON_BOOTSTRAP_LUA%" echo       pcall(function() package:off("install:success", on_success) end)
>> "%MASON_BOOTSTRAP_LUA%" echo       pcall(function() package:off("install:failed", on_failed) end)
>> "%MASON_BOOTSTRAP_LUA%" echo     end
>> "%MASON_BOOTSTRAP_LUA%" echo     on_success = function(receipt)
>> "%MASON_BOOTSTRAP_LUA%" echo       event_result = { true, receipt }
>> "%MASON_BOOTSTRAP_LUA%" echo       detach()
>> "%MASON_BOOTSTRAP_LUA%" echo       vim.schedule(function() install_result(name, package, true, receipt, false) end)
>> "%MASON_BOOTSTRAP_LUA%" echo     end
>> "%MASON_BOOTSTRAP_LUA%" echo     on_failed = function(reason)
>> "%MASON_BOOTSTRAP_LUA%" echo       event_result = { false, reason }
>> "%MASON_BOOTSTRAP_LUA%" echo       detach()
>> "%MASON_BOOTSTRAP_LUA%" echo       vim.schedule(function() install_result(name, package, false, reason, false) end)
>> "%MASON_BOOTSTRAP_LUA%" echo     end
>> "%MASON_BOOTSTRAP_LUA%" echo     package:once("install:success", on_success)
>> "%MASON_BOOTSTRAP_LUA%" echo     package:once("install:failed", on_failed)
>> "%MASON_BOOTSTRAP_LUA%" echo     if package:is_installing() then state[name] = "installing" report(name, "waiting") return end
>> "%MASON_BOOTSTRAP_LUA%" echo     if event_result then return end
>> "%MASON_BOOTSTRAP_LUA%" echo     detach()
>> "%MASON_BOOTSTRAP_LUA%" echo     if ready(package) then done(name, "ready") else start_install(name, package, false) end
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   report("registry", "refreshing")
>> "%MASON_BOOTSTRAP_LUA%" echo   local refresh_started, refresh_error = pcall(registry.refresh, function(success, result)
>> "%MASON_BOOTSTRAP_LUA%" echo     vim.schedule(function()
>> "%MASON_BOOTSTRAP_LUA%" echo       local callback_ok, callback_error = xpcall(function()
>> "%MASON_BOOTSTRAP_LUA%" echo         if not success then fail("registry refresh", result) return end
>> "%MASON_BOOTSTRAP_LUA%" echo         for _, name in ipairs(names) do
>> "%MASON_BOOTSTRAP_LUA%" echo           local found, package = pcall(registry.get_package, name)
>> "%MASON_BOOTSTRAP_LUA%" echo           if not found then fail(name, package) return end
>> "%MASON_BOOTSTRAP_LUA%" echo           watch(name, package)
>> "%MASON_BOOTSTRAP_LUA%" echo         end
>> "%MASON_BOOTSTRAP_LUA%" echo       end, debug.traceback)
>> "%MASON_BOOTSTRAP_LUA%" echo       if not callback_ok then fail("registry callback", callback_error) end
>> "%MASON_BOOTSTRAP_LUA%" echo     end)
>> "%MASON_BOOTSTRAP_LUA%" echo   end)
>> "%MASON_BOOTSTRAP_LUA%" echo   if not refresh_started then fail("registry refresh", refresh_error) end
>> "%MASON_BOOTSTRAP_LUA%" echo   local complete = vim.wait(300000, function() return failure ~= nil or completed == total end, 100)
>> "%MASON_BOOTSTRAP_LUA%" echo   if not complete then
>> "%MASON_BOOTSTRAP_LUA%" echo     local pending = {}
>> "%MASON_BOOTSTRAP_LUA%" echo     for _, name in ipairs(names) do if state[name] ~= "done" then pending[#pending + 1] = name end end
>> "%MASON_BOOTSTRAP_LUA%" echo     fail("timeout", "pending: " .. table.concat(pending, ", "))
>> "%MASON_BOOTSTRAP_LUA%" echo   end
>> "%MASON_BOOTSTRAP_LUA%" echo   if failure then error(failure, 0) end
>> "%MASON_BOOTSTRAP_LUA%" echo end, debug.traceback)
>> "%MASON_BOOTSTRAP_LUA%" echo if not ok then
>> "%MASON_BOOTSTRAP_LUA%" echo   stop_active()
>> "%MASON_BOOTSTRAP_LUA%" echo   pcall(vim.api.nvim_err_writeln, err)
>> "%MASON_BOOTSTRAP_LUA%" echo   vim.cmd("cquit")
>> "%MASON_BOOTSTRAP_LUA%" echo else
>> "%MASON_BOOTSTRAP_LUA%" echo   vim.cmd("qa^!")
>> "%MASON_BOOTSTRAP_LUA%" echo end
call :create_nvim_medium_worker "mason" "%MASON_BOOTSTRAP_LUA%"
if errorlevel 1 (
    set "CP_MASON_BOOTSTRAP="
    del "%MASON_BOOTSTRAP_LUA%" >nul 2>nul
    call :cleanup_nvim_worktree_guard
    exit /b 1
)
set "INSTALL_CMD="%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%MEDIUM_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 320 -OperationKind Mason"
set "SPIN_MEDIUM_WORKER=1"
set "SPIN_TIMEOUT_SECONDS=330"
call :run_install_spinner "Neovim language tools" "this may take a while" "%VISIBLE_TEMP%\cp_setup_mason.log" "INSTALLING" "INSTALLED" "1"
set "MASON_BOOTSTRAP_EXIT=%ERRORLEVEL%"
call :verify_nvim_worktree_guard >> "%EXEC_TEMP%\cp_setup_mason.log" 2>&1
if errorlevel 1 set "MASON_BOOTSTRAP_EXIT=1"
call :publish_component_log "cp_setup_mason.log"
if errorlevel 1 set "MASON_BOOTSTRAP_EXIT=1"
del "%MEDIUM_WORKER_PS%" >nul 2>nul
set "MEDIUM_WORKER_PS="
set "SPIN_MEDIUM_WORKER="
set "SPIN_TIMEOUT_SECONDS="
set "CP_MASON_BOOTSTRAP="
del "%MASON_BOOTSTRAP_LUA%" >nul 2>nul
if not "%MASON_BOOTSTRAP_EXIT%"=="0" (
    call :record_mason_packages progress
    call :cleanup_nvim_worktree_guard
    echo [%ESC%[31mFAILED%ESC%[0m] Mason tool bootstrap failed.
    echo Log: %VISIBLE_TEMP%\cp_setup_mason.log
    exit /b 1
)
call :record_mason_packages
set "MASON_RECORD_EXIT=%ERRORLEVEL%"
if not "%MASON_RECORD_EXIT%"=="0" (
    call :cleanup_nvim_worktree_guard
    echo [%ESC%[31mFAILED%ESC%[0m] Could not record setup-owned Mason packages.
    exit /b 1
)
call :verify_mason_tools
set "MASON_VERIFY_EXIT=%ERRORLEVEL%"
call :verify_nvim_worktree_guard >> "%EXEC_TEMP%\cp_setup_mason.log" 2>&1
if errorlevel 1 set "MASON_VERIFY_EXIT=1"
call :publish_component_log "cp_setup_mason.log"
if errorlevel 1 set "MASON_VERIFY_EXIT=1"
if not "%MASON_VERIFY_EXIT%"=="0" (
    call :cleanup_nvim_worktree_guard
    echo [%ESC%[31mFAILED%ESC%[0m] Mason tools were installed, but their executables are not usable.
    echo Log: %VISIBLE_TEMP%\cp_setup_mason.log
    exit /b 1
)
call :cleanup_nvim_worktree_guard
call :print_installed "Neovim language tools"
exit /b 0

:capture_missing_mason_packages
set "MASON_MISSING="
for %%T in (%MASON_TOOLS%) do if not exist "%CP_SETUP_TARGET_LOCALAPPDATA%\nvim-data\mason\packages\%%T" set "MASON_MISSING=!MASON_MISSING! %%T"
exit /b 0

:begin_pending_mason
set "MASON_BEGIN_PS=%EXEC_TEMP%\cp_setup_mason_begin_%RANDOM%_%RANDOM%.ps1"
> "%MASON_BEGIN_PS%" echo $ErrorActionPreference='Stop'
>> "%MASON_BEGIN_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%MASON_BEGIN_PS%" echo function Inventory^([string]$nvim^){$root=Join-Path $nvim 'mason\packages';$result=[Collections.Generic.List[string]]::new^(^);$cursor=$nvim;foreach^($part in 'mason','packages'^){$cursor=Join-Path $cursor $part;if^(Test-Path -LiteralPath $cursor^){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if^(-not$item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Unsafe Mason inventory path.'}}};if^(Test-Path -LiteralPath $root^){foreach^($item in Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop^){if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint-or$item.Name-notmatch'^^[A-Za-z0-9._-]+$'-or$item.Name-in@^('.','..'^)^){throw 'Unsafe Mason package inventory.'};$result.Add^($item.Name^)}};@^($result^|Sort-Object -Unique^)}
>> "%MASON_BEGIN_PS%" echo function ValidList^($values^){$list=@^($values^);$sorted=@^($list^|Sort-Object -Unique^);if^($sorted.Count-ne$list.Count-or^($sorted-join"`0"^)-cne^($list-join"`0"^)-or@^($list^|Where-Object{[string]$_-notmatch'^^[A-Za-z0-9._-]+$'-or$_-in@^('.','..'^)}^).Count^){throw 'Invalid Mason inventory.'};[string[]]$list}
>> "%MASON_BEGIN_PS%" echo function ReadIntent^($state^){if^(@^($state.GetValueNames^(^)^)-notcontains'Pending.Mason.Intent'^){return $null};if^($state.GetValueKind^('Pending.Mason.Intent'^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Invalid pending Mason kind.'};$raw=[string]$state.GetValue^('Pending.Mason.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^([char]'^|'^);if^($p.Count-ne 6-or$p[0]-cne'v1'-or$p[1]-notmatch'^^[0-9a-f]{32}$'-or$p[2]-notin@^('prepared','committed'^)-or$p[3]-notmatch'^^[0-9]{1,19}$'-or$p[4]-notmatch'^^[0-9a-f]{64}$'^){throw 'Invalid pending Mason intent.'};$bytes=[Convert]::FromBase64String^($p[5]^);if^((Hash $bytes^)-cne$p[4]^){throw 'Invalid pending Mason hash.'};$json=[Text.Encoding]::UTF8.GetString^($bytes^);$plan=$json^|ConvertFrom-Json;if^(^($plan^|ConvertTo-Json -Compress^)-cne$json-or[int]$plan.Version-ne 1^){throw 'Invalid pending Mason plan.'};$before=ValidList $plan.BeforePackages;$owned=ValidList $plan.OwnedPackages;$candidate=if^($null-ne$plan.CandidatePackages^){ValidList $plan.CandidatePackages}else{[string[]]@^(^)};$excluded=if^($null-ne$plan.ExcludedPackages^){ValidList $plan.ExcludedPackages}else{[string[]]@^(^)};$attempt=if^($null-ne$plan.AttemptBeforePackages^){ValidList $plan.AttemptBeforePackages}else{$before};if^($p[2]-eq'prepared'-and^($owned.Count-ne 0-or[bool]$plan.Frozen^)^){throw 'Invalid prepared Mason plan.'};[pscustomobject]@{Stage=$p[2];Nonce=$p[1];Started=$p[3];Before=$before;Candidate=$candidate;Excluded=$excluded;Attempt=$attempt}}
>> "%MASON_BEGIN_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state^){throw 'Protected Mason ownership state is missing.'}
>> "%MASON_BEGIN_PS%" echo try{$names=@^($state.GetValueNames^(^)^);if^($names-notcontains'Snapshot.Complete'-or[int]$state.GetValue^('Snapshot.Complete',0^)-ne 1-or$state.GetValueKind^('NvimData.Root'^)-ne[Microsoft.Win32.RegistryValueKind]::String-or$state.GetValueKind^('Mason.Packages.Before'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString^){throw 'Mason snapshot is incomplete.'};$nvim=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root'^)^).TrimEnd^([char]92^);if^($nvim-ine[IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_NVIMDATA_ROOT^).TrimEnd^([char]92^)^){throw 'Protected Mason root changed.'};$immutable=[string[]]^(ValidList $state.GetValue^('Mason.Packages.Before'^)^);$closure=[string[]]^(ValidList @^($env:MASON_CANDIDATE_CLOSURE -split '\s+'^|Where-Object{$_}^)^);$pending=ReadIntent $state
>> "%MASON_BEGIN_PS%" echo if^($names-contains'Mason.Inventory.Frozen'^){if^($state.GetValueKind^('Mason.Inventory.Frozen'^)-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$state.GetValue^('Mason.Inventory.Frozen',0^)-ne 1-or$state.GetValueKind^('Mason.Packages'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString-or$pending^){throw 'Frozen Mason inventory is invalid.'};[void]^(ValidList $state.GetValue^('Mason.Packages'^)^);exit 0};if^($names-contains'Mason.Packages'^){throw 'Unfrozen Mason ownership inventory exists.'};$current=[string[]]@^(Inventory $nvim^)
>> "%MASON_BEGIN_PS%" echo if^($pending^){if^($pending.Stage-cne'prepared'^){throw 'Committed Mason intent was not recovered.'};if^($pending.Before.Count-ne$immutable.Count-or^($pending.Before-join"`0"^)-cne^($immutable-join"`0"^)^){throw 'Pending Mason intent changed the immutable inventory.'};$before=$immutable;$candidate=[string[]]$pending.Candidate;$unknown=[string[]]@^($current^|Where-Object{$before-inotcontains$_-and$candidate-inotcontains$_}^|Sort-Object -Unique^);$excluded=[string[]]@^($pending.Excluded+$unknown^|Sort-Object -Unique^);$nonce=$pending.Nonce;$started=$pending.Started}else{$before=$immutable;$candidate=[string[]]@^($closure^|Where-Object{$before-inotcontains$_}^|Sort-Object -Unique^);$excluded=[string[]]@^(^);$nonce=[guid]::NewGuid^(^).ToString^('N'^);$started=[string][DateTime]::UtcNow.Ticks}
>> "%MASON_BEGIN_PS%" echo if^(@^($candidate^|Where-Object{$before-icontains$_-or$excluded-icontains$_}^).Count-or@^($excluded^|Where-Object{$before-icontains$_}^).Count^){throw 'Pending Mason package sets overlap.'};$plan=[ordered]@{Version=1;BeforePackages=[string[]]$before;OwnedPackages=[string[]]@^(^);Frozen=$false;CandidatePackages=[string[]]$candidate;ExcludedPackages=[string[]]$excluded;AttemptBeforePackages=$current};$json=$plan^|ConvertTo-Json -Compress;$bytes=[Text.Encoding]::UTF8.GetBytes^($json^);$intent='v1^|'+$nonce+'^|prepared^|'+$started+'^|'+^(Hash $bytes^)+'^|'+[Convert]::ToBase64String^($bytes^);$state.SetValue^('Pending.Mason.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String^);if^([string]$state.GetValue^('Pending.Mason.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$intent^){throw 'Pending Mason intent did not verify.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MASON_BEGIN_PS%" >nul 2>nul
set "MASON_BEGIN_EXIT=%ERRORLEVEL%"
del "%MASON_BEGIN_PS%" >nul 2>nul
set "MASON_BEGIN_PS="
exit /b %MASON_BEGIN_EXIT%

:record_mason_packages
set "MASON_RECORD_MODE=%~1"
if not defined MASON_RECORD_MODE set "MASON_RECORD_MODE=commit"
set "MASON_RECORD_PS=%EXEC_TEMP%\cp_setup_mason_record_%RANDOM%_%RANDOM%.ps1"
> "%MASON_RECORD_PS%" echo $ErrorActionPreference='Stop'
>> "%MASON_RECORD_PS%" echo function Hash^([byte[]]$bytes^){$sha=[Security.Cryptography.SHA256]::Create^(^);try{^([BitConverter]::ToString^($sha.ComputeHash^($bytes^)^)^).Replace^('-',''^).ToLowerInvariant^(^)}finally{$sha.Dispose^(^)}}
>> "%MASON_RECORD_PS%" echo function ValidList^($values^){$list=@^($values^);$sorted=@^($list^|Sort-Object -Unique^);if^($sorted.Count-ne$list.Count-or^($sorted-join"`0"^)-cne^($list-join"`0"^)-or@^($list^|Where-Object{[string]$_-notmatch'^^[A-Za-z0-9._-]+$'-or$_-in@^('.','..'^)}^).Count^){throw 'Invalid Mason inventory.'};[string[]]$list}
>> "%MASON_RECORD_PS%" echo function Inventory^([string]$nvim^){$root=Join-Path $nvim 'mason\packages';$result=[Collections.Generic.List[string]]::new^(^);$cursor=$nvim;foreach^($part in 'mason','packages'^){$cursor=Join-Path $cursor $part;if^(Test-Path -LiteralPath $cursor^){$item=Get-Item -LiteralPath $cursor -Force -ErrorAction Stop;if^(-not$item.PSIsContainer-or^($item.Attributes-band[IO.FileAttributes]::ReparsePoint^)^){throw 'Unsafe Mason inventory path.'}}};if^(Test-Path -LiteralPath $root^){foreach^($item in Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction Stop^){if^($item.Attributes-band[IO.FileAttributes]::ReparsePoint-or$item.Name-notmatch'^^[A-Za-z0-9._-]+$'-or$item.Name-in@^('.','..'^)^){throw 'Unsafe Mason package inventory.'};$result.Add^($item.Name^)}};[string[]]@^($result^|Sort-Object -Unique^)}
>> "%MASON_RECORD_PS%" echo $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey^([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default^);$state=$machine.OpenSubKey^('Software\my-cp-setup\Users\'+$env:CP_SETUP_TARGET_SID,$true^);if^(-not$state^){throw 'Protected Mason ownership state is missing.'};try{$names=@^($state.GetValueNames^(^)^);if^($names-contains'Mason.Inventory.Frozen'^){if^($env:MASON_RECORD_MODE-cne'commit'-or$state.GetValueKind^('Mason.Inventory.Frozen'^)-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$state.GetValue^('Mason.Inventory.Frozen',0^)-ne 1-or$state.GetValueKind^('Mason.Packages'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString-or$names-contains'Pending.Mason.Intent'^){throw 'Frozen Mason inventory is invalid.'};[void]^(ValidList $state.GetValue^('Mason.Packages'^)^);exit 0};if^($state.GetValueKind^('Pending.Mason.Intent'^)-ne[Microsoft.Win32.RegistryValueKind]::String^){throw 'Pending Mason intent is missing.'};$raw=[string]$state.GetValue^('Pending.Mason.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^);$p=$raw.Split^([char]'^|'^);if^($p.Count-ne 6-or$p[0]-cne'v1'-or$p[1]-notmatch'^^[0-9a-f]{32}$'-or$p[2]-cne'prepared'-or$p[3]-notmatch'^^[0-9]{1,19}$'-or$p[4]-notmatch'^^[0-9a-f]{64}$'^){throw 'Invalid pending Mason intent.'};$bytes=[Convert]::FromBase64String^($p[5]^);if^((Hash $bytes^)-cne$p[4]^){throw 'Invalid pending Mason hash.'};$json=[Text.Encoding]::UTF8.GetString^($bytes^);$plan=$json^|ConvertFrom-Json;if^(^($plan^|ConvertTo-Json -Compress^)-cne$json-or[int]$plan.Version-ne 1-or[bool]$plan.Frozen-or@^($plan.OwnedPackages^).Count^){throw 'Invalid pending Mason plan.'};$before=ValidList $plan.BeforePackages;$candidate=if^($null-ne$plan.CandidatePackages^){ValidList $plan.CandidatePackages}else{[string[]]@^(^)};$excluded=if^($null-ne$plan.ExcludedPackages^){ValidList $plan.ExcludedPackages}else{[string[]]@^(^)};$attempt=if^($null-ne$plan.AttemptBeforePackages^){ValidList $plan.AttemptBeforePackages}else{$before};$nvim=[IO.Path]::GetFullPath^([string]$state.GetValue^('NvimData.Root'^)^).TrimEnd^([char]92^);if^($nvim-ine[IO.Path]::GetFullPath^($env:CP_SETUP_TARGET_NVIMDATA_ROOT^).TrimEnd^([char]92^)^){throw 'Protected Mason root changed.'};$current=[string[]]@^(Inventory $nvim^);$delta=[string[]]@^($current^|Where-Object{$attempt-inotcontains$_-and$excluded-inotcontains$_}^|Sort-Object -Unique^);$candidate=[string[]]@^($candidate+$delta^|Where-Object{$before-inotcontains$_-and$excluded-inotcontains$_}^|Sort-Object -Unique^);if^($env:MASON_RECORD_MODE-ceq'progress'^){$next=[ordered]@{Version=1;BeforePackages=[string[]]$before;OwnedPackages=[string[]]@^(^);Frozen=$false;CandidatePackages=$candidate;ExcludedPackages=[string[]]$excluded;AttemptBeforePackages=$current};$nextJson=$next^|ConvertTo-Json -Compress;$nextBytes=[Text.Encoding]::UTF8.GetBytes^($nextJson^);$prepared='v1^|'+$p[1]+'^|prepared^|'+$p[3]+'^|'+^(Hash $nextBytes^)+'^|'+[Convert]::ToBase64String^($nextBytes^);$state.SetValue^('Pending.Mason.Intent',$prepared,[Microsoft.Win32.RegistryValueKind]::String^);if^([string]$state.GetValue^('Pending.Mason.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$prepared^){throw 'Mason progress journal did not verify.'};exit 0};if^($env:MASON_RECORD_MODE-cne'commit'^){throw 'Unknown Mason record mode.'};$owned=[string[]]@^($current^|Where-Object{$candidate-icontains$_-and$before-inotcontains$_-and$excluded-inotcontains$_}^|Sort-Object -Unique^);$state.SetValue^('Mason.Packages',$owned,[Microsoft.Win32.RegistryValueKind]::MultiString^);$state.SetValue^('Mason.Inventory.Frozen',1,[Microsoft.Win32.RegistryValueKind]::DWord^);$committedPlan=[ordered]@{Version=1;BeforePackages=[string[]]$before;OwnedPackages=$owned;Frozen=$true;CandidatePackages=$candidate;ExcludedPackages=[string[]]$excluded;AttemptBeforePackages=$current};$committedJson=$committedPlan^|ConvertTo-Json -Compress;$committedBytes=[Text.Encoding]::UTF8.GetBytes^($committedJson^);$committed='v1^|'+$p[1]+'^|committed^|'+$p[3]+'^|'+^(Hash $committedBytes^)+'^|'+[Convert]::ToBase64String^($committedBytes^);$state.SetValue^('Pending.Mason.Intent',$committed,[Microsoft.Win32.RegistryValueKind]::String^);if^($state.GetValueKind^('Mason.Packages'^)-ne[Microsoft.Win32.RegistryValueKind]::MultiString-or$state.GetValueKind^('Mason.Inventory.Frozen'^)-ne[Microsoft.Win32.RegistryValueKind]::DWord-or[int]$state.GetValue^('Mason.Inventory.Frozen',0^)-ne 1-or[string]$state.GetValue^('Pending.Mason.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames^)-cne$committed^){throw 'Mason ownership commit did not verify.'};$state.DeleteValue^('Pending.Mason.Intent',$false^);if^(@^($state.GetValueNames^(^)^)-contains'Pending.Mason.Intent'^){throw 'Pending Mason intent cleanup failed.'}}finally{$state.Dispose^(^);$machine.Dispose^(^)}
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MASON_RECORD_PS%"
set "MASON_RECORD_EXIT=%ERRORLEVEL%"
del "%MASON_RECORD_PS%" >nul 2>nul
set "MASON_RECORD_PS="
set "MASON_RECORD_MODE="
exit /b %MASON_RECORD_EXIT%

:verify_mason_tools
call :activate_target_profile_environment
call :prepare_medium_worker_launcher
if errorlevel 1 exit /b 1
call :create_nvim_medium_worker "verify"
if errorlevel 1 exit /b 1
"%POWERSHELL_EXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%MEDIUM_LAUNCHER_PS%" -WorkerScript "%MEDIUM_WORKER_PS%" -TargetSid "%CP_SETUP_TARGET_SID%" -System32 "%SYSTEM32_DIR%" -ExecTemp "%EXEC_TEMP%" -NativeSource "%MEDIUM_NATIVE_CS%" -TimeoutSeconds 60 >nul 2>nul
set "MASON_VERIFY_EXIT=%ERRORLEVEL%"
if "%MASON_VERIFY_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
del "%MEDIUM_WORKER_PS%" >nul 2>nul
set "MEDIUM_WORKER_PS="
exit /b %MASON_VERIFY_EXIT%

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
set "RUFF_VERIFY_STDIN=%EXEC_TEMP%\cp_setup_ruff_verify_%RANDOM%_%RANDOM%.txt"
set "RUFF_VERIFY_OUT=%EXEC_TEMP%\cp_setup_ruff_verify_%RANDOM%_%RANDOM%.out"
set "RUFF_VERIFY_ERR=%EXEC_TEMP%\cp_setup_ruff_verify_%RANDOM%_%RANDOM%.err"
> "%RUFF_VERIFY_STDIN%" type nul
set "SILENT_COMMAND="%FOUND_RUFF_PATH%" check --no-cache --force-exclude --quiet --select E9 --stdin-filename "%ROOT%\template\python\solve.py" --no-fix --output-format json - ^< "%RUFF_VERIFY_STDIN%""
set "SILENT_STDOUT=%RUFF_VERIFY_OUT%"
set "SILENT_STDERR=%RUFF_VERIFY_ERR%"
set "SILENT_TIMEOUT_SECONDS=30"
call :run_silent_timeout
set "RUFF_VERIFY_EXIT=%ERRORLEVEL%"
del "%RUFF_VERIFY_STDIN%" "%RUFF_VERIFY_OUT%" "%RUFF_VERIFY_ERR%" >nul 2>nul
if not "%RUFF_VERIFY_EXIT%"=="0" (
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
call :prepare_nvim_worktree_guard
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not protect the setup worktree during Mason verification.
    exit /b 1
)
call :verify_mason_tools
set "MASON_VERIFY_EXIT=%ERRORLEVEL%"
call :verify_nvim_worktree_guard >nul 2>nul
if errorlevel 1 set "MASON_VERIFY_EXIT=1"
call :cleanup_nvim_worktree_guard
if not "%MASON_VERIFY_EXIT%"=="0" (
    echo [%ESC%[31mFAILED%ESC%[0m] Required Mason tools are not usable.
    exit /b 1
)
call :ensure_spinner
if errorlevel 1 (
    echo [%ESC%[31mFAILED%ESC%[0m] Could not create verification spinner.
    exit /b 1
)
set "VERIFY_DIR=%EXEC_TEMP%\cp_setup_verify_%RANDOM%_%RANDOM%_%RANDOM%"
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

if defined FOUND_GIT_PATH if exist "%ROOT%\.git" (
    set "VERIFY_GIT_OUT=%EXEC_TEMP%\cp_setup_verify_git_%RANDOM%_%RANDOM%.out"
    set "VERIFY_GIT_ERR=%EXEC_TEMP%\cp_setup_verify_git_%RANDOM%_%RANDOM%.err"
    set "SILENT_COMMAND="%FOUND_GIT_PATH%" -c "safe.directory=%ROOT%" -c "core.hooksPath=NUL" -C "%ROOT%" submodule status"
    set "SILENT_STDOUT=%VERIFY_GIT_OUT%"
    set "SILENT_STDERR=%VERIFY_GIT_ERR%"
    set "SILENT_TIMEOUT_SECONDS=30"
    call :run_silent_timeout
    set "VERIFY_GIT_EXIT=!ERRORLEVEL!"
    del "%VERIFY_GIT_OUT%" "%VERIFY_GIT_ERR%" >nul 2>nul
    if not "!VERIFY_GIT_EXIT!"=="0" exit /b 1
)

echo [%ESC%[38;5;114mVERIFIED%ESC%[0m] Verification passed
exit /b 0

:verify_failed
set "VERIFY_FAILURE_EXIT=%ERRORLEVEL%"
if "%VERIFY_FAILURE_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
call :cleanup_verify
if "%CP_SETUP_TIMEOUT_OCCURRED%"=="1" exit /b 124
exit /b 1

:ensure_spinner
set "SPINNER_PY=%EXEC_TEMP%\cp_setup_spinner_%RANDOM%_%RANDOM%_%RANDOM%.py"
> "%SPINNER_PY%" echo import argparse
>> "%SPINNER_PY%" echo import ctypes
>> "%SPINNER_PY%" echo import os
>> "%SPINNER_PY%" echo import subprocess
>> "%SPINNER_PY%" echo import sys
>> "%SPINNER_PY%" echo import tempfile
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
>> "%SPINNER_PY%" echo class ProcessEntry32W(ctypes.Structure):
>> "%SPINNER_PY%" echo     _fields_ = [
>> "%SPINNER_PY%" echo         ("dwSize", ctypes.c_uint32), ("cntUsage", ctypes.c_uint32),
>> "%SPINNER_PY%" echo         ("th32ProcessID", ctypes.c_uint32), ("th32DefaultHeapID", ctypes.c_size_t),
>> "%SPINNER_PY%" echo         ("th32ModuleID", ctypes.c_uint32), ("cntThreads", ctypes.c_uint32),
>> "%SPINNER_PY%" echo         ("th32ParentProcessID", ctypes.c_uint32), ("pcPriClassBase", ctypes.c_long),
>> "%SPINNER_PY%" echo         ("dwFlags", ctypes.c_uint32), ("szExeFile", ctypes.c_wchar * 260),
>> "%SPINNER_PY%" echo     ]
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo def capture_tree_handles(root_pid):
>> "%SPINNER_PY%" echo     if sys.platform != "win32":
>> "%SPINNER_PY%" echo         return []
>> "%SPINNER_PY%" echo     kernel32 = ctypes.windll.kernel32
>> "%SPINNER_PY%" echo     kernel32.CreateToolhelp32Snapshot.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
>> "%SPINNER_PY%" echo     kernel32.CreateToolhelp32Snapshot.restype = ctypes.c_void_p
>> "%SPINNER_PY%" echo     kernel32.Process32FirstW.argtypes = [ctypes.c_void_p, ctypes.POINTER(ProcessEntry32W)]
>> "%SPINNER_PY%" echo     kernel32.Process32NextW.argtypes = [ctypes.c_void_p, ctypes.POINTER(ProcessEntry32W)]
>> "%SPINNER_PY%" echo     kernel32.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
>> "%SPINNER_PY%" echo     kernel32.OpenProcess.restype = ctypes.c_void_p
>> "%SPINNER_PY%" echo     kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
>> "%SPINNER_PY%" echo     snapshot = kernel32.CreateToolhelp32Snapshot(2, 0)
>> "%SPINNER_PY%" echo     if snapshot == ctypes.c_void_p(-1).value:
>> "%SPINNER_PY%" echo         return []
>> "%SPINNER_PY%" echo     children = {}
>> "%SPINNER_PY%" echo     entry = ProcessEntry32W()
>> "%SPINNER_PY%" echo     entry.dwSize = ctypes.sizeof(entry)
>> "%SPINNER_PY%" echo     try:
>> "%SPINNER_PY%" echo         present = kernel32.Process32FirstW(snapshot, ctypes.byref(entry))
>> "%SPINNER_PY%" echo         while present:
>> "%SPINNER_PY%" echo             children.setdefault(entry.th32ParentProcessID, []).append(entry.th32ProcessID)
>> "%SPINNER_PY%" echo             present = kernel32.Process32NextW(snapshot, ctypes.byref(entry))
>> "%SPINNER_PY%" echo     finally:
>> "%SPINNER_PY%" echo         kernel32.CloseHandle(snapshot)
>> "%SPINNER_PY%" echo     pids = [root_pid]
>> "%SPINNER_PY%" echo     index = 0
>> "%SPINNER_PY%" echo     while index ^< len(pids):
>> "%SPINNER_PY%" echo         pids.extend(pid for pid in children.get(pids[index], []) if pid not in pids)
>> "%SPINNER_PY%" echo         index += 1
>> "%SPINNER_PY%" echo     handles = []
>> "%SPINNER_PY%" echo     for pid in pids:
>> "%SPINNER_PY%" echo         handle = kernel32.OpenProcess(0x00100001, False, pid)
>> "%SPINNER_PY%" echo         if handle:
>> "%SPINNER_PY%" echo             handles.append(handle)
>> "%SPINNER_PY%" echo     return handles
>> "%SPINNER_PY%" echo.
>> "%SPINNER_PY%" echo def wait_for_tree_exit(handles):
>> "%SPINNER_PY%" echo     if sys.platform != "win32":
>> "%SPINNER_PY%" echo         return
>> "%SPINNER_PY%" echo     kernel32 = ctypes.windll.kernel32
>> "%SPINNER_PY%" echo     kernel32.WaitForSingleObject.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
>> "%SPINNER_PY%" echo     kernel32.WaitForSingleObject.restype = ctypes.c_uint32
>> "%SPINNER_PY%" echo     kernel32.TerminateProcess.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
>> "%SPINNER_PY%" echo     kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
>> "%SPINNER_PY%" echo     deadline = time.monotonic() + 5
>> "%SPINNER_PY%" echo     try:
>> "%SPINNER_PY%" echo         for handle in handles:
>> "%SPINNER_PY%" echo             remaining = max(0, int((deadline - time.monotonic()) * 1000))
>> "%SPINNER_PY%" echo             if kernel32.WaitForSingleObject(handle, remaining) == 258:
>> "%SPINNER_PY%" echo                 kernel32.TerminateProcess(handle, 124)
>> "%SPINNER_PY%" echo                 kernel32.WaitForSingleObject(handle, 1000)
>> "%SPINNER_PY%" echo     finally:
>> "%SPINNER_PY%" echo         for handle in handles:
>> "%SPINNER_PY%" echo             kernel32.CloseHandle(handle)
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
>> "%SPINNER_PY%" echo     parser.add_argument("--timeout", type=float, default=300.0)
>> "%SPINNER_PY%" echo     parser.add_argument("command", nargs=argparse.REMAINDER)
>> "%SPINNER_PY%" echo     args = parser.parse_args()
>> "%SPINNER_PY%" echo     command = args.command[1:] if args.command and args.command[0] == "--" else args.command
>> "%SPINNER_PY%" echo     if not command:
>> "%SPINNER_PY%" echo         print("spinner: missing command", file=sys.stderr)
>> "%SPINNER_PY%" echo         return 1
>> "%SPINNER_PY%" echo     if args.timeout ^<= 0:
>> "%SPINNER_PY%" echo         print("spinner: timeout must be positive", file=sys.stderr)
>> "%SPINNER_PY%" echo         return 1
>> "%SPINNER_PY%" echo     stdin = subprocess.DEVNULL if args.stdin_empty else None
>> "%SPINNER_PY%" echo     with tempfile.TemporaryFile() as stdout_file, tempfile.TemporaryFile() as stderr_file:
>> "%SPINNER_PY%" echo         process = subprocess.Popen(command, cwd=args.cwd, stdin=stdin, stdout=stdout_file, stderr=stderr_file)
>> "%SPINNER_PY%" echo         index = 0
>> "%SPINNER_PY%" echo         deadline = time.monotonic() + args.timeout
>> "%SPINNER_PY%" echo         timed_out = False
>> "%SPINNER_PY%" echo         while True:
>> "%SPINNER_PY%" echo             try:
>> "%SPINNER_PY%" echo                 process.wait(timeout=0.1)
>> "%SPINNER_PY%" echo                 break
>> "%SPINNER_PY%" echo             except subprocess.TimeoutExpired:
>> "%SPINNER_PY%" echo                 print("\r{}[{}VERIFYING{}] {} {}".format(CLEAR, PURPLE, RESET, FRAMES[index %% len(FRAMES)], args.label), end="", flush=True)
>> "%SPINNER_PY%" echo                 index += 1
>> "%SPINNER_PY%" echo                 if time.monotonic() ^>= deadline:
>> "%SPINNER_PY%" echo                     timed_out = True
>> "%SPINNER_PY%" echo                     break
>> "%SPINNER_PY%" echo         if timed_out:
>> "%SPINNER_PY%" echo             tree_handles = capture_tree_handles(process.pid)
>> "%SPINNER_PY%" echo             taskkill = Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32" / "taskkill.exe"
>> "%SPINNER_PY%" echo             try:
>> "%SPINNER_PY%" echo                 subprocess.run([str(taskkill), "/PID", str(process.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15, check=False)
>> "%SPINNER_PY%" echo             except (OSError, subprocess.TimeoutExpired):
>> "%SPINNER_PY%" echo                 pass
>> "%SPINNER_PY%" echo             wait_for_tree_exit(tree_handles)
>> "%SPINNER_PY%" echo             try:
>> "%SPINNER_PY%" echo                 process.wait(timeout=5)
>> "%SPINNER_PY%" echo             except subprocess.TimeoutExpired:
>> "%SPINNER_PY%" echo                 process.kill()
>> "%SPINNER_PY%" echo                 try:
>> "%SPINNER_PY%" echo                     process.wait(timeout=5)
>> "%SPINNER_PY%" echo                 except subprocess.TimeoutExpired:
>> "%SPINNER_PY%" echo                     pass
>> "%SPINNER_PY%" echo         stdout_file.seek(0)
>> "%SPINNER_PY%" echo         stderr_file.seek(0)
>> "%SPINNER_PY%" echo         stdout = stdout_file.read().decode("utf-8", errors="backslashreplace")
>> "%SPINNER_PY%" echo         stderr = stderr_file.read().decode("utf-8", errors="backslashreplace")
>> "%SPINNER_PY%" echo     if timed_out:
>> "%SPINNER_PY%" echo         print("\r{}[{}FAILED{}] {}".format(CLEAR, RED, RESET, args.label), file=sys.stderr)
>> "%SPINNER_PY%" echo         print("Timed out after {:.0f} seconds.".format(args.timeout), file=sys.stderr)
>> "%SPINNER_PY%" echo         if stderr:
>> "%SPINNER_PY%" echo             print(stderr, file=sys.stderr, end="")
>> "%SPINNER_PY%" echo         if stdout:
>> "%SPINNER_PY%" echo             print(stdout, file=sys.stderr, end="")
>> "%SPINNER_PY%" echo         return 124
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
    "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$target=[IO.Path]::GetFullPath($env:VERIFY_DIR); $temp=[IO.Path]::GetFullPath($env:EXEC_TEMP).TrimEnd('\')+'\'; if (-not $target.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $target) -notlike 'cp_setup_verify_*') { exit 1 }; Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop"
    if errorlevel 1 exit /b 1
)
exit /b 0

:failed
set "INSTALL_FAILURE_EXIT=%ERRORLEVEL%"
if "%INSTALL_FAILURE_EXIT%"=="124" set "CP_SETUP_TIMEOUT_OCCURRED=1"
if "%CHECK_ONLY%"=="0" if "%STATE_ROOT_CLAIMED%"=="1" call :recover_pending_operations >nul 2>nul
if "%CHECK_ONLY%"=="0" if "%STATE_ROOT_CLAIMED%"=="1" call :repair_target_profile_artifacts >nul 2>nul
call :cleanup_secure_temp
echo.
echo [%ESC%[31mFAILED%ESC%[0m] CP setup install did not complete.
if "%CP_SETUP_TIMEOUT_OCCURRED%"=="1" exit /b 124
exit /b 1

::__CP_ELEVATE_ORCHESTRATOR_BEGIN__
::$ErrorActionPreference = 'Stop'
::Set-StrictMode -Version 2
::function Read-Block([string]$begin,[string]$end) {
::    $lines = $script:sourceLines
::    if (-not $lines) { throw 'Installer source is not locked.' }
::    $first = [Array]::IndexOf($lines,'::' + $begin)
::    $last = [Array]::IndexOf($lines,'::' + $end)
::    if ($first -lt 0 -or $last -le $first) { throw ('Missing source block: ' + $begin) }
::    $content = [Collections.Generic.List[string]]::new()
::    for ($i=$first+1;$i -lt $last;$i++) {
::        if (-not $lines[$i].StartsWith('::',[StringComparison]::Ordinal)) { throw 'Malformed source block.' }
::        $content.Add($lines[$i].Substring(2))
::    }
::    $content -join [Environment]::NewLine
::}
::function Assert-SourcePath([string]$path) {
::    $full=[IO.Path]::GetFullPath($path)
::    if ($full -notmatch '^[A-Za-z]:\\') { throw 'Installer source is not on a local drive.' }
::    $root=[IO.Path]::GetPathRoot($full);$current=$root
::    foreach($part in $full.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)) {
::        $current=[IO.Path]::Combine($current,$part)
::        $item=Get-Item -LiteralPath $current -Force -ErrorAction Stop
::        if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw ('Installer source contains a reparse point: '+$current)}
::    }
::    if(-not[IO.File]::Exists($full)){throw 'Installer source is missing.'}
::    $full
::}
::$pathLockSource=@'
::using System;
::using System.Collections.Generic;
::using System.ComponentModel;
::using System.IO;
::using System.Runtime.InteropServices;
::using System.Text;
::using Microsoft.Win32.SafeHandles;
::public sealed class CpSetupSourceLease : IDisposable {
:: const uint GENERIC_READ=0x80000000,FILE_SHARE_READ=1,OPEN_EXISTING=3,FILE_ATTRIBUTE_DIRECTORY=0x10,FILE_ATTRIBUTE_REPARSE_POINT=0x400,FILE_FLAG_OPEN_REPARSE_POINT=0x00200000;
:: SafeFileHandle handle;
:: public byte[] Bytes { get; private set; }
:: public string FinalPathValue { get; private set; }
:: [StructLayout(LayoutKind.Sequential)]struct BY_HANDLE_FILE_INFORMATION{public uint Attributes,CreationLow,CreationHigh,AccessLow,AccessHigh,WriteLow,WriteHigh,VolumeSerial,FileSizeHigh,FileSizeLow,Links,FileIndexHigh,FileIndexLow;}
:: [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern SafeFileHandle CreateFileW(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
:: [DllImport("kernel32.dll",SetLastError=true)]static extern bool GetFileInformationByHandle(SafeFileHandle handle,out BY_HANDLE_FILE_INFORMATION info);
:: [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern uint GetFinalPathNameByHandleW(SafeFileHandle handle,StringBuilder path,uint length,uint flags);
:: [DllImport("kernel32.dll",SetLastError=true)]static extern bool ReadFile(SafeFileHandle handle,IntPtr buffer,uint bytesToRead,out uint bytesRead,IntPtr overlapped);
:: static string Canonical(string value){string full=Path.GetFullPath(value).TrimEnd(Path.DirectorySeparatorChar);return full.Length==2&&full[1]==':'?full+Path.DirectorySeparatorChar:full;}
:: static string FinalPath(SafeFileHandle handle){var buffer=new StringBuilder(32768);uint count=GetFinalPathNameByHandleW(handle,buffer,(uint)buffer.Capacity,0);if(count==0||count>=buffer.Capacity)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not resolve locked source handle.");string value=buffer.ToString();if(value.StartsWith(@"\\?\UNC\",StringComparison.OrdinalIgnoreCase))value=@"\\"+value.Substring(8);else if(value.StartsWith(@"\\?\",StringComparison.OrdinalIgnoreCase))value=value.Substring(4);return Canonical(value);}
:: static byte[] ReadBytes(SafeFileHandle handle,BY_HANDLE_FILE_INFORMATION info){long length=((long)info.FileSizeHigh<<32)|info.FileSizeLow;if(length<1||length>16777216)throw new IOException("Installer source size is invalid.");byte[] bytes=new byte[(int)length];GCHandle pin=GCHandle.Alloc(bytes,GCHandleType.Pinned);try{int offset=0;while(offset<bytes.Length){uint read;if(!ReadFile(handle,IntPtr.Add(pin.AddrOfPinnedObject(),offset),(uint)(bytes.Length-offset),out read,IntPtr.Zero))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not read locked installer source.");if(read==0)throw new EndOfStreamException("Locked installer source ended early.");offset+=checked((int)read);}return bytes;}finally{pin.Free();}}
:: public static CpSetupSourceLease Acquire(string file){string full=Canonical(file);if(!Path.IsPathRooted(full))throw new IOException("Installer source is not rooted.");SafeFileHandle handle=CreateFileW(full,GENERIC_READ,FILE_SHARE_READ,IntPtr.Zero,OPEN_EXISTING,FILE_FLAG_OPEN_REPARSE_POINT,IntPtr.Zero);if(handle.IsInvalid)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not lease installer source.");try{BY_HANDLE_FILE_INFORMATION info;if(!GetFileInformationByHandle(handle,out info))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not inspect installer source handle.");if((info.Attributes&(FILE_ATTRIBUTE_DIRECTORY|FILE_ATTRIBUTE_REPARSE_POINT))!=0)throw new IOException("Installer source is not a regular file.");string finalPath=FinalPath(handle);if(!String.Equals(finalPath,full,StringComparison.OrdinalIgnoreCase))throw new IOException("Installer source handle resolved to another path.");return new CpSetupSourceLease{handle=handle,FinalPathValue=finalPath,Bytes=ReadBytes(handle,info)};}catch{handle.Dispose();throw;}}
:: public void Dispose(){if(handle!=null){handle.Dispose();handle=null;}Bytes=null;}
::}
::public static class CpSetupProcessImage {
:: const uint PROCESS_QUERY_LIMITED_INFORMATION=0x1000;static readonly IntPtr InvalidHandle=new IntPtr(-1);
:: [DllImport("kernel32.dll",SetLastError=true)]static extern IntPtr OpenProcess(uint access,bool inherit,int processId);
:: [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern bool QueryFullProcessImageNameW(IntPtr process,uint flags,StringBuilder image,ref uint length);
:: [DllImport("kernel32.dll")]static extern bool CloseHandle(IntPtr handle);
:: public static string Query(int processId){IntPtr handle=OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION,false,processId);if(handle==IntPtr.Zero||handle==InvalidHandle)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not query elevated process.");try{var buffer=new StringBuilder(32768);uint length=(uint)buffer.Capacity;if(!QueryFullProcessImageNameW(handle,0,buffer,ref length))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not resolve elevated process image.");return Path.GetFullPath(buffer.ToString());}finally{CloseHandle(handle);}}
::}
::'@
::Add-Type -TypeDefinition $pathLockSource -Language CSharp -ErrorAction Stop|Out-Null
::$treeSource=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:CP_PROCESS_TREE_NATIVE_BASE64))
::Add-Type -TypeDefinition $treeSource -Language CSharp -ErrorAction Stop|Out-Null
::$mediumSource=Read-Block '__CP_MEDIUM_NATIVE_BEGIN__' '__CP_MEDIUM_NATIVE_END__'
::Add-Type -TypeDefinition $mediumSource -Language CSharp -ErrorAction Stop|Out-Null
::function Get-TreeMembers([int]$rootPid) {
::    $members=@{}
::    for($pass=0;$pass-lt 3;$pass++){foreach($pidValue in [CpSetupProcessTree]::Snapshot($rootPid)){try{$candidate=[Diagnostics.Process]::GetProcessById($pidValue);$started=$candidate.StartTime.ToUniversalTime().Ticks;$members[[string]$pidValue]=[pscustomobject]@{Process=$candidate;Started=$started}}catch{}};if($pass-lt 2){Start-Sleep -Milliseconds 25}}
::    $members
::}
::function Parse-Seconds([string]$value,[int]$fallback) {
::    [int]$parsed = 0
::    if (-not [int]::TryParse($value,[ref]$parsed) -or $parsed -lt 1) { return $fallback }
::    $parsed
::}
::function Assert-LogDestination([string]$path) {
::    if ([string]::IsNullOrWhiteSpace($path)) { $path = Join-Path $env:VISIBLE_TEMP 'cp_setup_install.log' }
::    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $env:CP_INSTALL_CWD $path }
::    $full = [IO.Path]::GetFullPath($path)
::    $parent = [IO.Path]::GetDirectoryName($full)
::    if (-not $parent -or -not [IO.Directory]::Exists($parent)) { throw 'Transcript destination directory does not exist.' }
::    $root = [IO.Path]::GetPathRoot($parent)
::    $current = $root
::    foreach ($part in $parent.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)) {
::        $current = [IO.Path]::Combine($current,$part)
::        if ([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) { throw 'Transcript destination contains a reparse point.' }
::    }
::    if ([IO.File]::Exists($full) -and ([IO.File]::GetAttributes($full) -band [IO.FileAttributes]::ReparsePoint)) { throw 'Transcript destination is a reparse point.' }
::    $full
::}
::function Remove-ProtectedTranscript([string]$path) {
::    if (-not [IO.Directory]::Exists($path)) { return }
::    $base = [IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92) + [char]92
::    $full = [IO.Path]::GetFullPath($path).TrimEnd([char]92)
::    if (-not $full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($full) -notmatch '^cp-setup-transcript-[0-9a-f]{32}$') { throw 'Unsafe transcript cleanup path.' }
::    $root = [IO.DirectoryInfo]::new($full)
::    if ($root.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Transcript root is a reparse point.' }
::    $stack = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
::    $stack.Push($root)
::    while ($stack.Count) { $dir=$stack.Pop(); foreach ($item in $dir.EnumerateFileSystemInfos()) { if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Transcript contains a reparse point.' }; if ($item -is [IO.DirectoryInfo]) { $stack.Push($item) } } }
::    [IO.Directory]::Delete($full,$true)
::}
::function Remove-ForcedRuntime([string]$nonce,[string]$transcriptDir) {
::    if($nonce-notmatch'^[0-9a-f]{32}$'){throw 'Invalid forced-runtime nonce.'}
::    $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)
::    $path=[IO.Path]::GetFullPath((Join-Path $base ('cp-setup-'+$nonce))).TrimEnd([char]92)
::    $marker=Join-Path $transcriptDir 'runtime.marker'
::    if([IO.File]::Exists($marker)-and([IO.File]::GetAttributes($marker)-band[IO.FileAttributes]::ReparsePoint)){throw 'Forced-runtime marker is a reparse point.'}
::    if(-not[IO.Directory]::Exists($path)){Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue;return}
::    $root=[IO.DirectoryInfo]::new($path);if($root.Attributes-band[IO.FileAttributes]::ReparsePoint){throw 'Forced runtime is a reparse point.'}
::    $acl=$root.GetAccessControl();$sid=([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value;$rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]));$expected=@{'S-1-5-18'=[Security.AccessControl.FileSystemRights]::Modify;'S-1-5-32-544'=[Security.AccessControl.FileSystemRights]::Modify;$sid=([Security.AccessControl.FileSystemRights]::ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete)};$inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit
::    if(-not$acl.AreAccessRulesProtected-or$acl.GetOwner([Security.Principal.SecurityIdentifier]).Value-ne'S-1-5-32-544'-or$rules.Count-ne$expected.Count-or@($rules|Where-Object{$_.IsInherited-or$_.AccessControlType-ne[Security.AccessControl.AccessControlType]::Allow-or-not$expected.ContainsKey($_.IdentityReference.Value)-or$_.FileSystemRights-ne$expected[$_.IdentityReference.Value]-or$_.InheritanceFlags-ne$inherit-or$_.PropagationFlags-ne[Security.AccessControl.PropagationFlags]::None}).Count){throw 'Forced runtime ACL is invalid.'}
::    $stack=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$stack.Push($root);while($stack.Count){foreach($item in $stack.Pop().EnumerateFileSystemInfos()){if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw 'Forced runtime contains a reparse point.'};if($item-is[IO.DirectoryInfo]){$stack.Push($item)}}}
::    [IO.Directory]::Delete($path,$true);if([IO.Directory]::Exists($path)){throw 'Forced runtime cleanup failed.'};Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
::}
::function Get-ValidatedElevatedProcess([string]$path,[string]$nonce,[datetime]$notBefore) {
::    if (-not [IO.File]::Exists($path)) { return $null }
::    if ([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint) { throw 'Elevated process marker is a reparse point.' }
::    $raw = [IO.File]::ReadAllText($path,[Text.Encoding]::ASCII).Trim()
::    $match = [regex]::Match($raw,'^([0-9a-f]{32})\|([1-9][0-9]{0,9})\|([0-9]{1,19})\|([0-9]{1,10})\|([0-9a-f]{64})\|([0-9a-f]{64})\|([A-Za-z0-9+/]+={0,2})$')
::    if (-not $match.Success -or $match.Groups[1].Value -ine $nonce) { throw 'Elevated process marker is invalid.' }
::    [int]$processId = 0
::    [long]$startTicks=0;[int]$session=0
::    if (-not [int]::TryParse($match.Groups[2].Value,[ref]$processId) -or $processId -eq $PID -or -not[long]::TryParse($match.Groups[3].Value,[ref]$startTicks)-or$startTicks-le 0-or-not[int]::TryParse($match.Groups[4].Value,[ref]$session)-or$session-lt 0) { throw 'Elevated process marker contains an invalid identity.' }
::    $imageBytes=[Convert]::FromBase64String($match.Groups[7].Value);$sha=[Security.Cryptography.SHA256]::Create();try{$pathHash=([BitConverter]::ToString($sha.ComputeHash($imageBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::    $expected=[IO.Path]::GetFullPath($env:POWERSHELL_EXE);$image=[Text.Encoding]::UTF8.GetString($imageBytes)
::    if($pathHash-cne$match.Groups[6].Value-or$image-cne[IO.Path]::GetFullPath($image)-or$image-ine$expected-or(Get-FileHash -LiteralPath $expected -Algorithm SHA256).Hash.ToLowerInvariant()-cne$match.Groups[5].Value){throw 'Elevated process marker contains an invalid image.'}
::    try { $process = [Diagnostics.Process]::GetProcessById($processId) } catch [ArgumentException] { return $null }
::    if ($process.HasExited) { return $null }
::    if ($process.SessionId -ne $session-or$process.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId-or$process.StartTime.ToUniversalTime().Ticks-ne$startTicks-or[CpSetupProcessImage]::Query($process.Id)-ine$expected) { throw 'Elevated process marker identifies an unexpected process.' }
::    $started = $process.StartTime.ToUniversalTime()
::    if ($started -lt $notBefore.AddSeconds(-5) -or $started -gt [DateTime]::UtcNow.AddSeconds(5)) { throw 'Elevated process marker identifies a stale process.' }
::    $process
::}
::function Stop-ElevatedTree([string]$path,[string]$nonce,[datetime]$notBefore) {
::    $process = Get-ValidatedElevatedProcess $path $nonce $notBefore
::    if (-not $process -or $process.HasExited) { return }
::    $members=Get-TreeMembers $process.Id
::    $taskkill = Join-Path ([Environment]::SystemDirectory) 'taskkill.exe'
::    $killer = Start-Process -FilePath $taskkill -ArgumentList @('/PID',[string]$process.Id,'/T','/F') -WindowStyle Hidden -PassThru
::    if (-not $killer.WaitForExit(10000)) { try { $killer.Kill() } catch {}; [void]$killer.WaitForExit(1000) }
::    $deadline=[DateTime]::UtcNow.AddSeconds(10)
::    foreach($entry in @($members.Values)){try{$candidate=$entry.Process;if(-not$candidate.HasExited-and$candidate.StartTime.ToUniversalTime().Ticks-eq[long]$entry.Started){$candidate.Kill()}}catch{}}
::    foreach($entry in @($members.Values)){try{$candidate=$entry.Process;if(-not$candidate.HasExited){$remaining=[Math]::Max(0,[int]$deadline.Subtract([DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt 0){[void]$candidate.WaitForExit($remaining)}};if(-not$candidate.HasExited-and$candidate.StartTime.ToUniversalTime().Ticks-eq[long]$entry.Started){throw ('Elevated process-tree survivor: '+$candidate.Id)}}finally{$entry.Process.Dispose()}}
::}
::function Get-TranscriptSummary([string]$path) {
::    $raw = [IO.File]::ReadAllText($path,[Text.Encoding]::Default)
::    $ansi = [string][char]27 + '\[[0-?]*[ -/]*[@-~]'
::    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
::    $summary = [Collections.Generic.List[string]]::new()
::    foreach ($fragment in [regex]::Split($raw,'[\r\n]+')) {
::        $plain = [regex]::Replace($fragment,$ansi,'')
::        $plain = [regex]::Replace($plain,'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]','').Trim()
::        if ($plain.Length -gt 512 -or $plain -notmatch '^\[(FOUND|INSTALLED|UPDATED|UP TO DATE)\] .+') { continue }
::        if ($seen.Add($plain)) { $summary.Add($plain) }
::        if ($summary.Count -ge 100) { break }
::    }
::    @($summary)
::}
::function Publish-Transcript([string]$source,[string]$destination,[string[]]$fallback,[int]$exitCode) {
::    $source64=if($source){[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($source)))}else{''}
::    $destination64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($destination)))
::    $fallbackText=if($fallback){[string]::Join([Environment]::NewLine,$fallback)}else{''}
::    $fallback64=[Convert]::ToBase64String([Text.Encoding]::Default.GetBytes($fallbackText))
::    $sid64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($env:CP_SETUP_TARGET_SID))
::    $body=@'
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::function Decode([string]$value,[Text.Encoding]$encoding){$encoding.GetString([Convert]::FromBase64String($value))}
::function Assert-NoReparse([string]$path,[bool]$leafMayBeMissing){$full=[IO.Path]::GetFullPath($path);$root=[IO.Path]::GetPathRoot($full);$current=$root;$parts=$full.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries);for($i=0;$i-lt$parts.Count;$i++){$current=[IO.Path]::Combine($current,$parts[$i]);if($leafMayBeMissing-and$i-eq$parts.Count-1-and-not[IO.File]::Exists($current)-and-not[IO.Directory]::Exists($current)){continue};$item=Get-Item -LiteralPath $current -Force -ErrorAction Stop;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw ('Transcript path contains a reparse point: '+$current)}};$full}
::$expectedSid=Decode $env:CP_TRANSCRIPT_SID64 ([Text.Encoding]::UTF8);$identity=[Security.Principal.WindowsIdentity]::GetCurrent();if($identity.User.Value-ine$expectedSid){throw 'Transcript publisher SID mismatch.'};$principal=[Security.Principal.WindowsPrincipal]::new($identity);if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Transcript publisher unexpectedly has an elevated token.'}
::$destination=Decode $env:CP_TRANSCRIPT_DEST64 ([Text.Encoding]::UTF8);$destination=Assert-NoReparse $destination $true;$parent=[IO.Path]::GetDirectoryName($destination);if(-not[IO.Directory]::Exists($parent)){throw 'Transcript destination directory does not exist.'};if(Test-Path -LiteralPath $destination){$item=Get-Item -LiteralPath $destination -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Transcript destination is unsafe.'}}
::$lines=[Collections.Generic.List[string]]::new();if($env:CP_TRANSCRIPT_SOURCE64){$source=Decode $env:CP_TRANSCRIPT_SOURCE64 ([Text.Encoding]::UTF8);$source=Assert-NoReparse $source $false;if(-not[IO.File]::Exists($source)){throw 'Protected transcript source is missing.'};foreach($line in [IO.File]::ReadAllLines($source,[Text.Encoding]::Default)){if($line-notmatch'^\[CP-SETUP\] END(?:\s|$)'){$lines.Add($line)}}}else{$fallback=Decode $env:CP_TRANSCRIPT_FALLBACK64 ([Text.Encoding]::Default);foreach($line in [regex]::Split($fallback,'\r?\n')){if($line-and$line-notmatch'^\[CP-SETUP\] END(?:\s|$)'){$lines.Add($line)}}}
::if(-not$lines.Count-or$lines[0]-notmatch'^\[CP-SETUP\] START(?:\s|$)'){$lines.Insert(0,'[CP-SETUP] START timestamp='+[DateTimeOffset]::Now.ToString('o')+' runnerPid='+$PID+' targetSid='+$expectedSid+' elevatedSid=none')};$lines.Add('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit='+[int]$env:CP_TRANSCRIPT_EXIT)
::$temporary=Join-Path $parent ('.'+[IO.Path]::GetFileName($destination)+'.'+[guid]::NewGuid().ToString('N')+'.tmp');$bytes=[Text.Encoding]::Default.GetBytes(($lines-join[Environment]::NewLine)+[Environment]::NewLine);$stream=[IO.FileStream]::new($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()};try{if(Test-Path -LiteralPath $destination){$item=Get-Item -LiteralPath $destination -Force;if($item.PSIsContainer-or($item.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Transcript destination changed.'};[IO.File]::Delete($destination)};[IO.File]::Move($temporary,$destination);if(-not[IO.File]::Exists($destination)-or([IO.File]::GetAttributes($destination)-band[IO.FileAttributes]::ReparsePoint)){throw 'Transcript publication did not verify.'}}finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
::'@
::    $bootstrap=@('$env:CP_TRANSCRIPT_SOURCE64='''+$source64+'''','$env:CP_TRANSCRIPT_DEST64='''+$destination64+'''','$env:CP_TRANSCRIPT_FALLBACK64='''+$fallback64+'''','$env:CP_TRANSCRIPT_SID64='''+$sid64+'''','$env:CP_TRANSCRIPT_EXIT='''+$exitCode+'''')
::    $worker=($bootstrap-join[Environment]::NewLine)+[Environment]::NewLine+$body
::    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($worker));if($encoded.Length-ge30000){throw 'Transcript publisher exceeds the safe Windows command-line budget.'}
::    $system32=[Environment]::SystemDirectory;$windows=[IO.Directory]::GetParent($system32).FullName;$powershell=[IO.Path]::Combine($system32,'WindowsPowerShell\v1.0\powershell.exe');$explorer=[IO.Path]::Combine($windows,'explorer.exe')
::    $code=[CpSetup.Native.MediumTokenRunner]::Run($env:CP_SETUP_TARGET_SID,$explorer,$powershell,$system32,$encoded,60);if($code-ne0){throw ('Transcript publisher exited with code '+$code)}
::}
::$sourcePath=Assert-SourcePath $env:CP_INSTALL_SCRIPT
::$sourceLease=[CpSetupSourceLease]::Acquire($sourcePath)
::$sha=[Security.Cryptography.SHA256]::Create()
::try{$sourceHash=([BitConverter]::ToString($sha.ComputeHash($sourceLease.Bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::$sourceMemory=[IO.MemoryStream]::new($sourceLease.Bytes,$false);$reader=[IO.StreamReader]::new($sourceMemory,[Text.Encoding]::UTF8,$true,4096,$false)
::try{$sourceText=$reader.ReadToEnd()}finally{$reader.Dispose()}
::$script:sourceLines=[regex]::Split($sourceText,'\r?\n')
::$tokens = @($env:CP_INSTALL_ARGS -split '\s+' | Where-Object { $_ })
::$allowed = @('--verbose','--non-interactive','--no-pause')
::if (@($tokens | Where-Object { $allowed -notcontains $_ }).Count) { throw 'Unsafe elevated installer arguments.' }
::$uacTimeout = Parse-Seconds $env:CP_ELEVATE_UAC_TIMEOUT_SECONDS 300
::$childTimeout = Parse-Seconds $env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS 7200
::$alreadyAdmin = $env:CP_ELEVATE_ALREADY_ADMIN -eq '1'
::$destination = Assert-LogDestination $env:INSTALL_LOG_REQUESTED
::$transcriptDir = Join-Path (Join-Path $env:SystemRoot 'Temp') ('cp-setup-transcript-' + [guid]::NewGuid().ToString('N'))
::$transcript = Join-Path $transcriptDir 'install.log'
::$payload = Read-Block '__CP_ELEVATED_CHILD_BEGIN__' '__CP_ELEVATED_CHILD_END__'
::$payloadBytes=[Text.Encoding]::UTF8.GetBytes($payload);$compressedMemory=[IO.MemoryStream]::new();$gzip=[IO.Compression.GzipStream]::new($compressedMemory,[IO.Compression.CompressionMode]::Compress,$true);try{$gzip.Write($payloadBytes,0,$payloadBytes.Length)}finally{$gzip.Dispose()};$payloadGzip=[Convert]::ToBase64String($compressedMemory.ToArray());$compressedMemory.Dispose()
::$bootstrap='$raw=[Convert]::FromBase64String('''+$payloadGzip+''');$memory=[IO.MemoryStream]::new(,$raw);$gzip=[IO.Compression.GzipStream]::new($memory,[IO.Compression.CompressionMode]::Decompress);$reader=[IO.StreamReader]::new($gzip,[Text.Encoding]::UTF8);try{$source=$reader.ReadToEnd()}finally{$reader.Dispose();$gzip.Dispose();$memory.Dispose()};&([scriptblock]::Create($source))'
::$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap))
::if($encoded.Length-ge 30000){throw 'Elevated bootstrap exceeds the safe Windows command-line budget.'}
::$startedFile = Join-Path $transcriptDir 'elevated.marker'
::$cancelFile = Join-Path $transcriptDir 'cancel.marker'
::$markerNonce = [guid]::NewGuid().ToString('N')
::$orchestratorStarted = [DateTime]::UtcNow
::Remove-Item -LiteralPath $startedFile,$cancelFile -Force -ErrorAction SilentlyContinue
::$env:CP_ELEVATE_TRANSCRIPT_DIR=$transcriptDir
::$env:CP_SETUP_TARGET_SID=$env:CP_SETUP_TARGET_SID
::$env:CP_SETUP_ELEVATED_CHILD='1'
::$env:CP_ELEVATE_CANCEL_FILE=$cancelFile
::$env:CP_ELEVATE_MARKER_NONCE=$markerNonce
::$env:CP_RUNTIME_OPERATION_ID=$markerNonce
::$env:CP_INSTALL_SCRIPT=$sourcePath
::$env:CP_INSTALL_SCRIPT_SHA256=$sourceHash
::$env:CP_SETUP_ORIGINAL_ROOT=$env:CP_INSTALL_CWD
::$env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS=[string]$childTimeout
::$env:CP_ELEVATED_BOOTSTRAP=$encoded
::$env:CP_ELEVATE_ALREADY_ADMIN_VALUE=if($alreadyAdmin){'1'}else{'0'}
::$env:CP_ELEVATE_NON_INTERACTIVE_VALUE=if($tokens-contains'--non-interactive'){'1'}else{'0'}
::$environmentLength=1;foreach($entry in Get-ChildItem Env:){$environmentLength+=$entry.Name.Length+1+([string]$entry.Value).Length+1};if($environmentLength-ge30000){throw 'Elevated environment exceeds the safe Windows environment budget.'}
::$launcher='$ErrorActionPreference=''Stop'';try{$args=@(''-NoLogo'',''-NoProfile'',''-NonInteractive'',''-ExecutionPolicy'',''Bypass'',''-EncodedCommand'',$env:CP_ELEVATED_BOOTSTRAP);$p=Start-Process -FilePath $env:POWERSHELL_EXE -WorkingDirectory $env:SystemRoot -Verb RunAs -ArgumentList $args -WindowStyle Hidden -PassThru -ErrorAction Stop;$limit=[int]$env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS+60;if(-not$p.WaitForExit($limit*1000)){exit 124};exit [int]$p.ExitCode}catch{if($_.Exception.NativeErrorCode-eq1223-or$_.Exception.Message-match''canceled|cancelled|denied|1223''){exit 1223};exit 1}'
::$launcherEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($launcher));if($launcherEncoded.Length-ge30000){throw 'Elevation launcher exceeds the safe Windows command-line budget.'}
::if($alreadyAdmin){$childArgs=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-EncodedCommand',$encoded);$helper=Start-Process -FilePath $env:POWERSHELL_EXE -WorkingDirectory $env:SystemRoot -ArgumentList $childArgs -WindowStyle Hidden -PassThru -ErrorAction Stop}else{$helperArgs=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-EncodedCommand',$launcherEncoded);$helper=Start-Process -FilePath $env:POWERSHELL_EXE -WorkingDirectory $env:SystemRoot -ArgumentList $helperArgs -WindowStyle Hidden -PassThru -ErrorAction Stop}
::$esc=[char]27; $cr=[char]13; $clear=$esc+'[2K'; $green=$esc+'[38;5;114m'; $red=$esc+'[31m'; $reset=$esc+'[0m'
::$requestLabel='Requesting administrator rights...'; $installLabel='Administrator rights granted, installing...'
::$overallTimeout=$childTimeout+60;if(-not$alreadyAdmin){$overallTimeout+=$uacTimeout}
::$frames=@([char]92,'-','/','|'); $index=0; $clock=[Diagnostics.Stopwatch]::StartNew(); $timedOut=$false; $cleanupError=$null
::while (-not $helper.HasExited) {
::    $started = Test-Path -LiteralPath $startedFile
::    $label = if ($alreadyAdmin -or $started) { $installLabel } else { $requestLabel }
::    Write-Host -NoNewline ($cr+$clear+$frames[$index -band 3]+' '+$label)
::    [Console]::Out.Flush()
::    if ((-not $alreadyAdmin -and -not $started -and $clock.Elapsed.TotalSeconds -ge $uacTimeout) -or $clock.Elapsed.TotalSeconds -ge $overallTimeout) {
::        $timedOut=$true
::        if([IO.Directory]::Exists($transcriptDir)){try { $signal=[IO.FileStream]::new($cancelFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$bytes=[Text.Encoding]::ASCII.GetBytes('timeout');$signal.Write($bytes,0,$bytes.Length);$signal.Flush($true)}finally{$signal.Dispose()} } catch { $cleanupError=$_.Exception.Message }}
::        $grace=[Diagnostics.Stopwatch]::StartNew()
::        while (-not $helper.HasExited -and $grace.Elapsed.TotalSeconds -lt 15) { Start-Sleep -Milliseconds 100 }
::        if (-not $helper.HasExited) {
::            try { Stop-ElevatedTree $startedFile $markerNonce $orchestratorStarted } catch { $cleanupError=$_.Exception.Message }
::            try{$helper.Kill()}catch{if(-not$cleanupError){$cleanupError=$_.Exception.Message}};[void]$helper.WaitForExit(5000)
::        }
::        break
::    }
::    Start-Sleep -Milliseconds 100
::    $index++
::}
::$hadElevatedChild = Test-Path -LiteralPath $startedFile
::if ($timedOut) { $result=[pscustomobject]@{Ok=$true;ExitCode=124;Details='Administrator request or elevated installer timed out.'} }
::else { if(-not$helper.HasExited-and-not$helper.WaitForExit(5000)){$result=$null}else{$helperExit=[int]$helper.ExitCode;$result=if(-not$hadElevatedChild-and$helperExit-eq1223){[pscustomobject]@{Ok=$false;ExitCode=1;Details='UAC canceled or denied (1223).'}}else{[pscustomobject]@{Ok=$true;ExitCode=$helperExit;Details=''}}} }
::$helper.Dispose()
::if($hadElevatedChild-and($timedOut-or-not$result-or-not$result.Ok-or[int]$result.ExitCode-eq 124)){try{Stop-ElevatedTree $startedFile $markerNonce $orchestratorStarted}catch{if(-not$cleanupError){$cleanupError=$_.Exception.Message}}}
::try{$sourceLease.Dispose()}catch{if(-not$cleanupError){$cleanupError=$_.Exception.Message}}
::$copyError = $null
::$summary = @()
::$transcriptCopied = $false
::$transcriptSource = $null
::$fallbackLines = @()
::if ([IO.File]::Exists($transcript)) {
::    try{$endLines=@([IO.File]::ReadAllLines($transcript,[Text.Encoding]::Default)|Where-Object{$_-match'^\[CP-SETUP\] END '});if($endLines.Count-gt 1){throw 'Elevated installer transcript contains multiple END records.'};$summary=@(Get-TranscriptSummary $transcript);$transcriptSource=$transcript}catch{$copyError=$_.Exception.Message}
::}
::if(-not$transcriptSource){
::    $details=if($result){[string]$result.Details}else{''}
::    $event=if($timedOut){'Elevation timed out.'}elseif($details-match'canceled|cancelled|denied|1223'){'UAC canceled or denied.'}elseif($hadElevatedChild){'Elevated installer did not produce a transcript.'}else{'Elevation failed before child start.'}
::    $fallbackLines=@('[CP-SETUP] START timestamp='+[DateTimeOffset]::Now.ToString('o')+' runnerPid='+$PID+' targetSid='+$env:CP_SETUP_TARGET_SID+' elevatedSid=none','[CP-SETUP] ORCHESTRATOR '+$event)
::}
::try { Remove-ForcedRuntime $markerNonce $transcriptDir } catch { if (-not $cleanupError) { $cleanupError=$_.Exception.Message } }
::$authoritativeExit=if($timedOut-or($result-and[int]$result.ExitCode-eq124)){124}elseif(-not$result-or-not$result.Ok-or$copyError-or$cleanupError){1}else{[int]$result.ExitCode}
::try{Publish-Transcript $transcriptSource $destination $fallbackLines $authoritativeExit;$transcriptCopied=$true}catch{$copyError=$_.Exception.Message;$authoritativeExit=if($timedOut-or($result-and[int]$result.ExitCode-eq124)){124}else{1}}
::if($transcriptCopied-and-not$cleanupError){
::    try{Remove-ProtectedTranscript $transcriptDir}catch{$cleanupError=$_.Exception.Message;$authoritativeExit=if($timedOut-or($result-and[int]$result.ExitCode-eq124)){124}else{1};try{Publish-Transcript $transcriptSource $destination $fallbackLines $authoritativeExit}catch{$copyError=$_.Exception.Message;$transcriptCopied=$false}}
::}
::$linePrefix = $cr+$clear
::if ($summary.Count) {
::    Write-Host -NoNewline $linePrefix
::    foreach ($line in $summary) {
::        if ($line -match '^\[([A-Z ]+)\](.*)$') { Write-Host ('['+$green+$Matches[1]+$reset+']'+$Matches[2]) }
::    }
::    $linePrefix = ''
::}
::if (-not $result -or -not $result.Ok) {
::    $details=if($result){[string]$result.Details}else{''}
::    if($details -match 'canceled|cancelled|denied|1223'){Write-Host ($linePrefix+$red+'Install canceled by user.'+$reset);exit 1}
::    Write-Host ($linePrefix+$red+'Install failed while requesting administrator rights.'+$reset)
::    if($details){Write-Host $details}
::    exit 1
::}
::$childExit=[int]$result.ExitCode
::if ($copyError) { Write-Host ($linePrefix+$red+'Install failed while saving the installation transcript.'+$reset); Write-Host $copyError; exit 1 }
::if ($cleanupError) { if($authoritativeExit-eq124){Write-Host ($linePrefix+$red+'Install failed: elevated installer timed out.'+$reset)}else{Write-Host ($linePrefix+$red+'Install failed while cleaning up protected installer data.'+$reset)}; Write-Host $cleanupError; if($transcriptCopied){Write-Host ('Log: '+$destination)}; exit $authoritativeExit }
::if($childExit -eq 0){Write-Host ($linePrefix+$green+'Install completed (see README for more info)'+$reset);exit 0}
::if($childExit -eq 124){Write-Host ($linePrefix+$red+'Install failed: elevated installer timed out.'+$reset);if($transcriptCopied){Write-Host ('Log: '+$destination)};exit 124}
::Write-Host ($linePrefix+$red+('Install failed: elevated installer exited with code '+$childExit)+$reset)
::if($transcriptCopied){Write-Host ('Log: '+$destination)}
::exit $childExit
::__CP_ELEVATE_ORCHESTRATOR_END__

::__CP_ELEVATED_CHILD_BEGIN__
::$ErrorActionPreference = 'Stop'
::Set-StrictMode -Version 2
::function Q([string]$value) { [char]34 + $value.Replace([char]34,[char]34+[char]34) + [char]34 }
::$pathLockSource=@'
::using System;
::using System.Collections.Generic;
::using System.ComponentModel;
::using System.IO;
::using System.Runtime.InteropServices;
::using System.Text;
::using Microsoft.Win32.SafeHandles;
::public sealed class CpSetupChildSourceLease : IDisposable {
:: const uint GENERIC_READ=0x80000000,FILE_SHARE_READ=1,OPEN_EXISTING=3,FILE_ATTRIBUTE_DIRECTORY=0x10,FILE_ATTRIBUTE_REPARSE_POINT=0x400,FILE_FLAG_OPEN_REPARSE_POINT=0x00200000;
:: SafeFileHandle handle;
:: public byte[] Bytes { get; private set; }
:: public string FinalPathValue { get; private set; }
:: [StructLayout(LayoutKind.Sequential)]struct BY_HANDLE_FILE_INFORMATION{public uint Attributes,CreationLow,CreationHigh,AccessLow,AccessHigh,WriteLow,WriteHigh,VolumeSerial,FileSizeHigh,FileSizeLow,Links,FileIndexHigh,FileIndexLow;}
:: [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern SafeFileHandle CreateFileW(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
:: [DllImport("kernel32.dll",SetLastError=true)]static extern bool GetFileInformationByHandle(SafeFileHandle handle,out BY_HANDLE_FILE_INFORMATION info);
:: [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]static extern uint GetFinalPathNameByHandleW(SafeFileHandle handle,StringBuilder path,uint length,uint flags);
:: [DllImport("kernel32.dll",SetLastError=true)]static extern bool ReadFile(SafeFileHandle handle,IntPtr buffer,uint bytesToRead,out uint bytesRead,IntPtr overlapped);
:: static string Canonical(string value){string full=Path.GetFullPath(value).TrimEnd(Path.DirectorySeparatorChar);return full.Length==2&&full[1]==':'?full+Path.DirectorySeparatorChar:full;}
:: static string FinalPath(SafeFileHandle handle){var buffer=new StringBuilder(32768);uint count=GetFinalPathNameByHandleW(handle,buffer,(uint)buffer.Capacity,0);if(count==0||count>=buffer.Capacity)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not resolve locked source handle.");string value=buffer.ToString();if(value.StartsWith(@"\\?\UNC\",StringComparison.OrdinalIgnoreCase))value=@"\\"+value.Substring(8);else if(value.StartsWith(@"\\?\",StringComparison.OrdinalIgnoreCase))value=value.Substring(4);return Canonical(value);}
:: static byte[] ReadBytes(SafeFileHandle handle,BY_HANDLE_FILE_INFORMATION info){long length=((long)info.FileSizeHigh<<32)|info.FileSizeLow;if(length<1||length>16777216)throw new IOException("Installer source size is invalid.");byte[] bytes=new byte[(int)length];GCHandle pin=GCHandle.Alloc(bytes,GCHandleType.Pinned);try{int offset=0;while(offset<bytes.Length){uint read;if(!ReadFile(handle,IntPtr.Add(pin.AddrOfPinnedObject(),offset),(uint)(bytes.Length-offset),out read,IntPtr.Zero))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not read locked installer source.");if(read==0)throw new EndOfStreamException("Locked installer source ended early.");offset+=checked((int)read);}return bytes;}finally{pin.Free();}}
:: public static CpSetupChildSourceLease Acquire(string file){string full=Canonical(file);if(!Path.IsPathRooted(full))throw new IOException("Installer source is not rooted.");SafeFileHandle handle=CreateFileW(full,GENERIC_READ,FILE_SHARE_READ,IntPtr.Zero,OPEN_EXISTING,FILE_FLAG_OPEN_REPARSE_POINT,IntPtr.Zero);if(handle.IsInvalid)throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not lease installer source.");try{BY_HANDLE_FILE_INFORMATION info;if(!GetFileInformationByHandle(handle,out info))throw new Win32Exception(Marshal.GetLastWin32Error(),"Could not inspect installer source handle.");if((info.Attributes&(FILE_ATTRIBUTE_DIRECTORY|FILE_ATTRIBUTE_REPARSE_POINT))!=0)throw new IOException("Installer source is not a regular file.");string finalPath=FinalPath(handle);if(!String.Equals(finalPath,full,StringComparison.OrdinalIgnoreCase))throw new IOException("Installer source handle resolved to another path.");return new CpSetupChildSourceLease{handle=handle,FinalPathValue=finalPath,Bytes=ReadBytes(handle,info)};}catch{handle.Dispose();throw;}}
:: public void Dispose(){if(handle!=null){handle.Dispose();handle=null;}Bytes=null;}
::}
::'@
::Add-Type -TypeDefinition $pathLockSource -Language CSharp -ErrorAction Stop|Out-Null
::$treeSource=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:CP_PROCESS_TREE_NATIVE_BASE64))
::Add-Type -TypeDefinition $treeSource -Language CSharp -ErrorAction Stop|Out-Null
::function Assert-SourcePath([string]$path) {
::    $full=[IO.Path]::GetFullPath($path);$root=[IO.Path]::GetPathRoot($full);$current=$root
::    if($full-notmatch'^[A-Za-z]:\\'){throw 'Installer source is not local.'}
::    foreach($part in $full.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)){$current=[IO.Path]::Combine($current,$part);$item=Get-Item -LiteralPath $current -Force -ErrorAction Stop;if($item.Attributes-band[IO.FileAttributes]::ReparsePoint){throw ('Installer source contains a reparse point: '+$current)}}
::    if(-not[IO.File]::Exists($full)){throw 'Installer script is missing.'};$full
::}
::function Get-TreeMembers([int]$rootPid) {
::    $members=@{};for($pass=0;$pass-lt 3;$pass++){foreach($pidValue in [CpSetupProcessTree]::Snapshot($rootPid)){try{$candidate=[Diagnostics.Process]::GetProcessById($pidValue);$members[[string]$pidValue]=[pscustomobject]@{Process=$candidate;Started=$candidate.StartTime.ToUniversalTime().Ticks}}catch{}};if($pass-lt 2){Start-Sleep -Milliseconds 25}};$members
::}
::function Stop-Tree([Diagnostics.Process]$process,[string]$system32) {
::    if ($process.HasExited) { return }
::    $members=Get-TreeMembers $process.Id
::    $taskkill=[IO.Path]::Combine($system32,'taskkill.exe')
::    $killer=Start-Process -FilePath $taskkill -ArgumentList @('/PID',[string]$process.Id,'/T','/F') -WindowStyle Hidden -PassThru
::    if(-not$killer.WaitForExit(10000)){try{$killer.Kill()}catch{};[void]$killer.WaitForExit(1000)}
::    $deadline=[DateTime]::UtcNow.AddSeconds(10);foreach($entry in @($members.Values)){try{$candidate=$entry.Process;if(-not$candidate.HasExited-and$candidate.StartTime.ToUniversalTime().Ticks-eq[long]$entry.Started){$candidate.Kill()}}catch{}}
::    foreach($entry in @($members.Values)){try{$candidate=$entry.Process;if(-not$candidate.HasExited){$remaining=[Math]::Max(0,[int]$deadline.Subtract([DateTime]::UtcNow).TotalMilliseconds);if($remaining-gt 0){[void]$candidate.WaitForExit($remaining)}};if(-not$candidate.HasExited-and$candidate.StartTime.ToUniversalTime().Ticks-eq[long]$entry.Started){throw ('Elevated child process-tree survivor: '+$candidate.Id)}}finally{$entry.Process.Dispose()}}
::}
::try {
::    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
::    $principal=[Security.Principal.WindowsPrincipal]::new($identity)
::    if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Elevated runner has no administrator token.'}
::    [int]$timeoutSeconds=0
::    if(-not [int]::TryParse($env:CP_ELEVATE_CHILD_TIMEOUT_SECONDS,[ref]$timeoutSeconds)-or$timeoutSeconds-lt 1){$timeoutSeconds=7200}
::    $system32=[Environment]::SystemDirectory
::    $base=[IO.Path]::GetFullPath((Join-Path $env:SystemRoot 'Temp')).TrimEnd([char]92)
::    $dir=[IO.Path]::GetFullPath($env:CP_ELEVATE_TRANSCRIPT_DIR).TrimEnd([char]92)
::    $cancelFile=[IO.Path]::GetFullPath($env:CP_ELEVATE_CANCEL_FILE)
::    if($cancelFile-ine[IO.Path]::GetFullPath((Join-Path $dir 'cancel.marker'))){throw 'Unsafe elevation cancellation marker.'}
::    $cmd=[IO.Path]::GetFullPath($env:CMD_EXE)
::    if($cmd -ine [IO.Path]::Combine($system32,'cmd.exe')){throw 'Untrusted cmd.exe path.'}
::    $script=Assert-SourcePath $env:CP_INSTALL_SCRIPT
::    $sourceLease=[CpSetupChildSourceLease]::Acquire($script)
::    $sha=[Security.Cryptography.SHA256]::Create();try{$actualHash=([BitConverter]::ToString($sha.ComputeHash($sourceLease.Bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::    if($env:CP_INSTALL_SCRIPT_SHA256-notmatch'^[0-9a-f]{64}$'-or$actualHash-cne$env:CP_INSTALL_SCRIPT_SHA256){throw 'Installer source hash changed during elevation.'}
::    $originalRoot=[IO.Path]::GetFullPath($env:CP_SETUP_ORIGINAL_ROOT).TrimEnd([char]92);if($originalRoot-notmatch'^[A-Za-z]:\\'){throw 'Original setup root is not local.'};$expectedSource=[IO.Path]::GetFullPath((Join-Path $originalRoot 'scripts\install.bat'));if($sourceLease.FinalPathValue-ine$expectedSource){throw 'Installer source is outside the original setup root.'}
::    $tokens=@($env:CP_INSTALL_ARGS -split '\s+'|Where-Object{$_})
::    $allowed=@('--verbose','--non-interactive','--no-pause')
::    if(@($tokens|Where-Object{$allowed-notcontains$_}).Count){throw 'Unsafe elevated installer arguments.'}
::    if(-not $dir.StartsWith($base+[char]92,[StringComparison]::OrdinalIgnoreCase)-or[IO.Path]::GetFileName($dir)-notmatch'^cp-setup-transcript-[0-9a-f]{32}$'-or[IO.Directory]::Exists($dir)){throw 'Unsafe transcript directory.'}
::    $baseItem=Get-Item -LiteralPath $base -Force -ErrorAction Stop
::    if(-not $baseItem.PSIsContainer-or($baseItem.Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Unsafe Windows Temp root.'}
::    $acl=[Security.AccessControl.DirectorySecurity]::new()
::    $acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'))
::    $acl.SetAccessRuleProtection($true,$false)
::    $inherit=[Security.AccessControl.InheritanceFlags]::ContainerInherit-bor[Security.AccessControl.InheritanceFlags]::ObjectInherit
::    foreach($sid in @('S-1-5-18','S-1-5-32-544')){$rule=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid),[Security.AccessControl.FileSystemRights]::Modify,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow);[void]$acl.AddAccessRule($rule)}
::    $target=[Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)
::    $targetRights=[Security.AccessControl.FileSystemRights]::ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete
::    [void]$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($target,$targetRights,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow))
::    $created=[IO.Directory]::CreateDirectory($dir,$acl)
::    if($created.Attributes-band[IO.FileAttributes]::ReparsePoint-or@($created.EnumerateFileSystemInfos()).Count){throw 'Transcript directory is unsafe or not empty.'}
::    if($env:CP_ELEVATE_MARKER_NONCE-notmatch'^[0-9a-f]{32}$'){throw 'Invalid elevation marker nonce.'}
::    $self=[Diagnostics.Process]::GetCurrentProcess();$image=[IO.Path]::GetFullPath($self.MainModule.FileName);$expectedImage=[IO.Path]::GetFullPath($env:POWERSHELL_EXE)
::    if($image-ine$expectedImage){throw 'Elevated runner image is unexpected.'};$imageHash=(Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash.ToLowerInvariant();$imageBytes=[Text.Encoding]::UTF8.GetBytes($image);$sha=[Security.Cryptography.SHA256]::Create();try{$pathHash=([BitConverter]::ToString($sha.ComputeHash($imageBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::    $marker=$env:CP_ELEVATE_MARKER_NONCE+'|'+$PID+'|'+$self.StartTime.ToUniversalTime().Ticks+'|'+$self.SessionId+'|'+$imageHash+'|'+$pathHash+'|'+[Convert]::ToBase64String($imageBytes)
::    $markerPath=Join-Path $dir 'elevated.marker';$markerStream=[IO.FileStream]::new($markerPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$markerBytes=[Text.Encoding]::ASCII.GetBytes($marker);$markerStream.Write($markerBytes,0,$markerBytes.Length);$markerStream.Flush($true)}finally{$markerStream.Dispose()}
::    $protectedScript=Join-Path $dir 'install.bat';$copyStream=[IO.FileStream]::new($protectedScript,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::Read);$copyStream.Write($sourceLease.Bytes,0,$sourceLease.Bytes.Length);$copyStream.Flush($true);if($copyStream.Length-ne$sourceLease.Bytes.Length-or[IO.File]::GetAttributes($protectedScript)-band[IO.FileAttributes]::ReparsePoint){throw 'Protected installer copy did not verify.'};$copyStream.Position=0;$sha=[Security.Cryptography.SHA256]::Create();try{$copyHash=([BitConverter]::ToString($sha.ComputeHash($copyStream))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};if($copyHash-cne$actualHash){throw 'Protected installer copy hash did not verify.'};$copyStream.Position=0
::    $transcript=Join-Path $dir 'install.log';$wrapper=Join-Path $dir 'run.cmd'
::    $header='[CP-SETUP] START timestamp='+[DateTimeOffset]::Now.ToString('o')+' runnerPid='+$PID+' targetSid='+$env:CP_SETUP_TARGET_SID+' elevatedSid='+$identity.User.Value
::    $transcriptStream=[IO.FileStream]::new($transcript,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite);try{$headerBytes=[Text.Encoding]::Default.GetBytes($header+[Environment]::NewLine);$transcriptStream.Write($headerBytes,0,$headerBytes.Length);$transcriptStream.Flush($true)}finally{$transcriptStream.Dispose()}
::    $runLine='call '+(Q $protectedScript);if($tokens.Count){$runLine+=' '+($tokens-join' ')};$runLine+=' 1^>^>'+(Q $transcript)+' 2^>^&1'
::    $wrapperLines=@('@echo off','setlocal DisableDelayedExpansion',$runLine,'exit /b %ERRORLEVEL%');$wrapperBytes=[Text.Encoding]::ASCII.GetBytes(($wrapperLines-join[Environment]::NewLine)+[Environment]::NewLine);$wrapperStream=[IO.FileStream]::new($wrapper,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);try{$wrapperStream.Write($wrapperBytes,0,$wrapperBytes.Length);$wrapperStream.Flush($true)}finally{$wrapperStream.Dispose()}
::    $arguments='/d /s /c ""'+$wrapper+'""'
::    $process=Start-Process -FilePath $cmd -ArgumentList $arguments -WorkingDirectory $system32 -WindowStyle Hidden -PassThru
::    ('[CP-SETUP] CHILD pid='+$process.Id)|Add-Content -LiteralPath $transcript -Encoding Default
::    $shown=0
::    function Flush-Transcript { try{$text=Get-Content -LiteralPath $transcript -Raw -Encoding Default -ErrorAction Stop;if($text.Length-gt$shown){[Console]::Write($text.Substring($shown));$script:shown=$text.Length}}catch{} }
::    $clock=[Diagnostics.Stopwatch]::StartNew();$timedOut=$false
::    while(-not $process.HasExited){Flush-Transcript;if($clock.Elapsed.TotalSeconds-ge$timeoutSeconds-or[IO.File]::Exists($cancelFile)){$timedOut=$true;Stop-Tree $process $system32;break};Start-Sleep -Milliseconds 100}
::    if($timedOut){$exitCode=124}elseif(-not$process.WaitForExit(5000)){Stop-Tree $process $system32;$exitCode=124}else{$exitCode=[int]$process.ExitCode}
::    ('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit='+$exitCode)|Add-Content -LiteralPath $transcript -Encoding Default
::    Flush-Transcript
::    exit $exitCode
::}catch{
::    $failure=$_.Exception.Message
::    try{if((Get-Variable transcript -ErrorAction SilentlyContinue)-and[IO.File]::Exists($transcript)){if(@([IO.File]::ReadAllLines($transcript,[Text.Encoding]::Default)|Where-Object{$_-match'^\[CP-SETUP\] END '}).Count-eq 0){('[CP-SETUP] END timestamp='+[DateTimeOffset]::Now.ToString('o')+' exit=1')|Add-Content -LiteralPath $transcript -Encoding Default};if(Get-Command Flush-Transcript -ErrorAction SilentlyContinue){Flush-Transcript}}}catch{}
::    [Console]::Error.WriteLine('Elevated runner failed: '+$failure);exit 1
::}
::__CP_ELEVATED_CHILD_END__

::__CP_USER_REGISTRY_PLAN_BEGIN__
::param(
::    [ValidateSet('Path','Environment','AutoRun','VTL')][string]$Mode,
::    [Parameter(Mandatory=$true)][string]$WorkerScript,
::    [Parameter(Mandatory=$true)][string]$CommitScript,
::    [Parameter(Mandatory=$true)][string]$RollbackScript,
::    [switch]$Recover
::)
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::function Assert-Output([string]$path) {
::    $root=[IO.Path]::GetFullPath($env:EXEC_TEMP).TrimEnd([char]92)+[char]92
::    $full=[IO.Path]::GetFullPath($path)
::    if(-not$full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Registry transaction output escaped EXEC_TEMP.'}
::    if([IO.File]::Exists($full)-and([IO.File]::GetAttributes($full)-band[IO.FileAttributes]::ReparsePoint)){throw 'Registry transaction output is a reparse point.'}
::    $full
::}
::$WorkerScript=Assert-Output $WorkerScript
::$CommitScript=Assert-Output $CommitScript
::$RollbackScript=Assert-Output $RollbackScript
::$sid=([Security.Principal.SecurityIdentifier]::new($env:CP_SETUP_TARGET_SID)).Value
::$users=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users,[Microsoft.Win32.RegistryView]::Default)
::$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default)
::$hive=$users.OpenSubKey($sid)
::$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$sid,$true)
::if(-not$hive-or-not$state){throw 'Protected registry transaction state is missing.'}
::$stateNames=@($state.GetValueNames())
::if($stateNames-notcontains'Snapshot.Complete'-or[int]$state.GetValue('Snapshot.Complete',0,$option)-ne 1){throw 'Registry transaction snapshot is incomplete.'}
::function Read-Value($key,[string]$name) {
::    $exists=$key-and(@($key.GetValueNames())-contains$name)
::    if(-not$exists){return [ordered]@{Exists=$false;Value=$null;Kind=0}}
::    $kind=[int]$key.GetValueKind($name)
::    if($kind-notin@(1,2,4,7)){throw ('Unsupported target registry kind: '+$name)}
::    $value=$key.GetValue($name,$null,$option)
::    if($kind-in@(1,2)){$value=[string]$value}elseif($kind-eq 4){$value=[int]$value}else{$value=[string[]]@($value)}
::    [ordered]@{Exists=$true;Value=$value;Kind=$kind}
::}
::function Snapshot([string]$prefix) {
::    $hadName=$prefix+'.HadValue'
::    if($stateNames-notcontains$hadName-or$state.GetValueKind($hadName)-ne[Microsoft.Win32.RegistryValueKind]::DWord){throw ('Missing immutable snapshot: '+$prefix)}
::    $had=[int]$state.GetValue($hadName,0,$option)
::    if($had-eq 0){return [ordered]@{Exists=$false;Value=$null;Kind=0}}
::    if($had-ne 1-or$stateNames-notcontains($prefix+'.Before')-or$stateNames-notcontains($prefix+'.Before.Kind')){throw ('Incomplete immutable snapshot: '+$prefix)}
::    $kind=[int]$state.GetValue($prefix+'.Before.Kind',0,$option)
::    if($kind-notin@(1,2)){throw ('Unsupported snapshot kind: '+$prefix)}
::    [ordered]@{Exists=$true;Value=[string]$state.GetValue($prefix+'.Before',$null,$option);Kind=$kind}
::}
::function Same($left,$right) {
::    if([bool]$left.Exists-ne[bool]$right.Exists){return $false}
::    if(-not$left.Exists){return $true}
::    if([int]$left.Kind-ne[int]$right.Kind){return $false}
::    if([int]$right.Kind-eq 7){return Same-List @($left.Value) @($right.Value)}
::    if([int]$right.Kind-eq 4){return [int]$left.Value-eq[int]$right.Value}
::    [string]$left.Value-ceq[string]$right.Value
::}
::function Same-List($left,$right) {
::    $a=@($left);$b=@($right);if($a.Count-ne$b.Count){return $false}
::    for($i=0;$i-lt$a.Count;$i++){if([string]$a[$i]-ine[string]$b[$i]){return $false}}
::    $true
::}
::function Metadata([string]$name,[bool]$exists,$value,[int]$kind){[ordered]@{Name=$name;Exists=$exists;Value=$value;Kind=$kind}}
::function Mutation([string]$key,[string]$name,$expected,$desired){[ordered]@{Key=$key;Name=$name;Expected=$expected;Desired=$desired}}
::if($Recover){
::    $pendingName='Pending.Registry.Intent';if(@($state.GetValueNames())-notcontains$pendingName){throw 'Protected registry recovery intent is missing.'};if($state.GetValueKind($pendingName)-ne[Microsoft.Win32.RegistryValueKind]::String){throw 'Protected registry recovery intent has an unsafe kind.'}
::    $intent=[string]$state.GetValue($pendingName,$null,$option);$parts=$intent.Split(@('|'),5);if($parts.Count-ne 5-or$parts[0]-cne'v1'-or$parts[1]-notin@('Path','Environment','AutoRun','VTL')-or$parts[2]-notin@('prepared','committed')-or$parts[3]-notmatch'^[0-9a-f]{64}$'){throw 'Protected registry recovery intent is invalid.'}
::    try{$bytes=[Convert]::FromBase64String($parts[4])}catch{throw 'Protected registry recovery payload is invalid.'};$sha=[Security.Cryptography.SHA256]::Create();try{$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};if($hash-cne$parts[3]){throw 'Protected registry recovery hash mismatch.'}
::    $json=[Text.Encoding]::UTF8.GetString($bytes);$plan=$json|ConvertFrom-Json;if([int]$plan.Version-ne 1-or[string]$plan.Sid-ine$sid-or[string]$plan.Mode-cne$parts[1]){throw 'Protected registry recovery identity mismatch.'};if(($plan|ConvertTo-Json -Depth 12 -Compress)-cne$json){throw 'Protected registry recovery payload is not canonical.'}
::    $allowedKeys=@('Environment','Software\Microsoft\Command Processor','Console');$allowedNames=@('Path','XDG_CONFIG_HOME','CP_SETUP_ROOT','CP_PYTHON','CP_GPP','CP_JAVAC','CP_JAVA','AutoRun','VirtualTerminalLevel');foreach($mutation in @($plan.Mutations)){if([string]$mutation.Key-notin$allowedKeys-or[string]$mutation.Name-notin$allowedNames){throw 'Protected registry recovery mutation is outside the allowlist.'};foreach($spec in @($mutation.Expected,$mutation.Desired)){if([bool]$spec.Exists){if([int]$spec.Kind-notin@(1,2,4,7)){throw 'Protected registry recovery kind is invalid.'}}elseif([int]$spec.Kind-ne 0-or$null-ne$spec.Value){throw 'Protected registry recovery absence spec is invalid.'}}}
::    $metadataNames=@($plan.Metadata|ForEach-Object{[string]$_.Name});$beforeNames=@($plan.MetadataBefore|ForEach-Object{[string]$_.Name});if($metadataNames.Count-ne$beforeNames.Count-or@($metadataNames|Where-Object{$beforeNames-inotcontains$_}).Count){throw 'Protected registry recovery metadata is incomplete.'}
::    $workerTemplate=@'
::$ErrorActionPreference='Stop'
::$plan=ConvertFrom-Json ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__')))
::$stage='__STAGE__'
::$identity=[Security.Principal.WindowsIdentity]::GetCurrent();if($identity.User.Value-ine[Security.Principal.SecurityIdentifier]::new($plan.Sid).Value){throw 'Registry recovery worker SID mismatch.'};if(([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Registry recovery worker unexpectedly has an elevated token.'}
::$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::function Read($key,[string]$name){$exists=@($key.GetValueNames())-contains$name;if(-not$exists){return[pscustomobject]@{Exists=$false;Value=$null;Kind=0}};$kind=[int]$key.GetValueKind($name);$value=$key.GetValue($name,$null,$option);if($kind-in@(1,2)){$value=[string]$value}elseif($kind-eq 4){$value=[int]$value}elseif($kind-eq 7){$value=[string[]]@($value)}else{throw 'Unsupported recovery registry kind.'};[pscustomobject]@{Exists=$true;Value=$value;Kind=$kind}}
::function Same($a,$b){if([bool]$a.Exists-ne[bool]$b.Exists){return$false};if(-not$a.Exists){return$true};if([int]$a.Kind-ne[int]$b.Kind){return$false};if([int]$b.Kind-eq 7){$x=@($a.Value);$y=@($b.Value);if($x.Count-ne$y.Count){return$false};for($i=0;$i-lt$x.Count;$i++){if([string]$x[$i]-ine[string]$y[$i]){return$false}};return$true};if([int]$b.Kind-eq 4){return[int]$a.Value-eq[int]$b.Value};[string]$a.Value-ceq[string]$b.Value}
::function Value($s){if([int]$s.Kind-eq 7){return[string[]]@($s.Value)};if([int]$s.Kind-eq 4){return[int]$s.Value};[string]$s.Value}
::function Apply($m,$from,$to){$key=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey([string]$m.Key,$true);if(-not$key-and[string]$m.Key-ceq'Console'){$key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Console',[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)};if(-not$key){throw 'Registry recovery target key is missing.'};try{if(-not(Same (Read $key ([string]$m.Name)) $from)){throw ('Concurrent registry recovery change: '+$m.Name)};if($to.Exists){$key.SetValue([string]$m.Name,(Value $to),[Microsoft.Win32.RegistryValueKind][int]$to.Kind)}else{$key.DeleteValue([string]$m.Name,$false)};if(-not(Same (Read $key ([string]$m.Name)) $to)){throw ('Registry recovery write did not verify: '+$m.Name)}}finally{$key.Dispose()}}
::foreach($m in @($plan.Mutations)){$key=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey([string]$m.Key);if($key){try{$current=Read $key ([string]$m.Name)}finally{$key.Dispose()}}elseif([string]$m.Key-ceq'Console'){$current=[pscustomobject]@{Exists=$false;Value=$null;Kind=0}}else{throw 'Registry recovery target key is missing.'};if($stage-eq'prepared'){if(Same $current $m.Desired){Apply $m $m.Desired $m.Expected}elseif(-not(Same $current $m.Expected)){throw ('User-modified value blocks registry recovery: '+$m.Name)}}elseif(-not(Same $current $m.Desired)){throw ('Committed registry value changed: '+$m.Name)}}
::'@
::    $workerSource=$workerTemplate.Replace('__PAYLOAD__',$parts[4]).Replace('__STAGE__',$parts[2])
::    $finalTemplate=@'
::$ErrorActionPreference='Stop'
::$plan=ConvertFrom-Json ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__')));$intent='__INTENT__';$stage='__STAGE__';$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::$users=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users,[Microsoft.Win32.RegistryView]::Default);$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default);$hive=$users.OpenSubKey([string]$plan.Sid);$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$plan.Sid,$true);if(-not$hive-or-not$state){throw 'Registry recovery finalizer state is missing.'};$pendingName='Pending.Registry.Intent';if($state.GetValueKind($pendingName)-ne[Microsoft.Win32.RegistryValueKind]::String-or[string]$state.GetValue($pendingName,$null,$option)-cne$intent){throw 'Registry recovery intent changed.'}
::function Read($key,[string]$name){$exists=@($key.GetValueNames())-contains$name;if(-not$exists){return[pscustomobject]@{Exists=$false;Value=$null;Kind=0}};$kind=[int]$key.GetValueKind($name);$value=$key.GetValue($name,$null,$option);if($kind-in@(1,2)){$value=[string]$value}elseif($kind-eq 4){$value=[int]$value}elseif($kind-eq 7){$value=[string[]]@($value)}else{throw 'Unsupported recovery registry kind.'};[pscustomobject]@{Exists=$true;Value=$value;Kind=$kind}}
::function Same($a,$b){if([bool]$a.Exists-ne[bool]$b.Exists){return$false};if(-not$a.Exists){return$true};if([int]$a.Kind-ne[int]$b.Kind){return$false};if([int]$b.Kind-eq 7){$x=@($a.Value);$y=@($b.Value);if($x.Count-ne$y.Count){return$false};for($i=0;$i-lt$x.Count;$i++){if([string]$x[$i]-ine[string]$y[$i]){return$false}};return$true};if([int]$b.Kind-eq 4){return[int]$a.Value-eq[int]$b.Value};[string]$a.Value-ceq[string]$b.Value}
::function SetSpec($key,$s){if($s.Exists){$value=if([int]$s.Kind-eq 7){[string[]]@($s.Value)}elseif([int]$s.Kind-eq 4){[int]$s.Value}else{[string]$s.Value};$key.SetValue([string]$s.Name,$value,[Microsoft.Win32.RegistryValueKind][int]$s.Kind)}else{$key.DeleteValue([string]$s.Name,$false)}}
::try{foreach($m in @($plan.Mutations)){$key=$hive.OpenSubKey([string]$m.Key);$expected=if($stage-eq'prepared'){$m.Expected}else{$m.Desired};if($key){try{$actual=Read $key ([string]$m.Name)}finally{$key.Dispose()}}elseif([string]$m.Key-ceq'Console'){$actual=[pscustomobject]@{Exists=$false;Value=$null;Kind=0}}else{throw 'Registry recovery target key is missing.'};if(-not(Same $actual $expected)){throw ('Registry recovery target verification failed: '+$m.Name)}};if($stage-eq'prepared'){for($i=0;$i-lt@($plan.Metadata).Count;$i++){$desired=$plan.Metadata[$i];$before=$plan.MetadataBefore[$i];$current=Read $state ([string]$desired.Name);if(-not(Same $current $desired)-and-not(Same $current $before)){throw ('Registry recovery metadata changed: '+$desired.Name)};SetSpec $state $before;if(-not(Same (Read $state ([string]$before.Name)) $before)){throw ('Registry recovery metadata rollback failed: '+$before.Name)}}}else{foreach($desired in @($plan.Metadata)){if(-not(Same (Read $state ([string]$desired.Name)) $desired)){throw ('Committed registry metadata changed: '+$desired.Name)}}};$state.DeleteValue($pendingName,$false);if(@($state.GetValueNames())-contains$pendingName){throw 'Registry recovery intent could not be cleared.'}}finally{foreach($key in @($hive,$state,$users,$machine)){if($key){$key.Dispose()}}}
::'@
::    $finalSource=$finalTemplate.Replace('__PAYLOAD__',$parts[4]).Replace('__INTENT__',$intent).Replace('__STAGE__',$parts[2])
::    [IO.File]::WriteAllText($WorkerScript,$workerSource,[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($RollbackScript,$workerSource,[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($CommitScript,$finalSource,[Text.UTF8Encoding]::new($false));foreach($key in @($hive,$state,$users,$machine)){if($key){$key.Dispose()}};exit 0
::}
::$mutations=[Collections.Generic.List[object]]::new()
::$metadata=[Collections.Generic.List[object]]::new()
::if($Mode-eq'Path') {
::    $key=$hive.OpenSubKey('Environment');if(-not$key){throw 'Target Environment key is missing.'}
::    try{$current=Read-Value $key 'Path'}finally{$key.Dispose()}
::    $before=Snapshot 'Path'
::    function Normalize([object]$value){if($null-eq$value){return''};([string]$value).Trim().TrimEnd([char]92)}
::    $desiredEntries=[Collections.Generic.List[string]]::new()
::    function Add-Unique([string]$value){$value=Normalize $value;if($value-and-not@($desiredEntries|Where-Object{$_-ieq$value})){$desiredEntries.Add($value)}}
::    Add-Unique (Join-Path $env:ROOT 'scripts')
::    foreach($exe in @($env:FOUND_GIT_PATH,$env:FOUND_NVIM_PATH,$env:FOUND_NODE_PATH,$env:FOUND_NPM_PATH,$env:FOUND_JAVAC_PATH,$env:FOUND_JAVA_PATH,$env:CP_GPP,$env:CP_PYTHON,$env:FOUND_RUFF_PATH)){if($exe-and[IO.File]::Exists($exe)){Add-Unique (Split-Path -Parent $exe)}}
::    $beforeEntries=@($(if($before.Exists){[string]$before.Value}else{''})-split';'|ForEach-Object{Normalize $_}|Where-Object{$_})
::    $newOwned=@($desiredEntries|Where-Object{$beforeEntries-inotcontains$_})
::    $hasWritten=$stateNames-contains'Path.Written';$hasWrittenKind=$stateNames-contains'Path.Written.Kind'
::    if($hasWritten-xor$hasWrittenKind){throw 'Incomplete Path written state.'}
::    $hasEntries=$stateNames-contains'Path.Entries';if($hasEntries-xor$hasWritten){throw 'Incomplete Path ownership state.'}
::    $previousOwned=@();if($hasEntries){if($state.GetValueKind('Path.Entries')-ne[Microsoft.Win32.RegistryValueKind]::MultiString){throw 'Path ownership state has an unsafe kind.'};$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$previousOwned=@(foreach($raw in @($state.GetValue('Path.Entries',$null,$option))){$entry=Normalize $raw;if(-not$entry-or$entry-cne[string]$raw-or-not$seen.Add($entry)){throw ('Invalid Path ownership entry: '+$raw)};$entry})}
::    $baseText=if($hasWritten-and$current.Exists){[string]$current.Value}elseif($hasWritten){''}elseif($before.Exists){[string]$before.Value}else{''}
::    $clean=[Collections.Generic.List[string]]::new()
::    foreach($raw in @($baseText-split';')){$entry=Normalize $raw;if($entry-and$previousOwned-inotcontains$entry-and-not@($clean|Where-Object{$_-ieq$entry})){$clean.Add($entry)}}
::    foreach($entry in $desiredEntries){if(-not@($clean|Where-Object{$_-ieq$entry})){$clean.Add($entry)}}
::    if($env:FOUND_JAVAC_PATH-and[IO.File]::Exists($env:FOUND_JAVAC_PATH)){$priority=Normalize (Split-Path -Parent $env:FOUND_JAVAC_PATH);for($i=$clean.Count-1;$i-ge 0;$i--){if($clean[$i]-ieq$priority){$clean.RemoveAt($i)}};$clean.Insert(0,$priority)}
::    $after=$clean-join';';$kind=if($current.Exists){[int]$current.Kind}elseif($hasWritten){[int]$state.GetValue('Path.Written.Kind',0,$option)}elseif($before.Exists){[int]$before.Kind}else{2};if($kind-notin@(1,2)){throw 'Unsafe current Path kind.'};$desired=[ordered]@{Exists=$true;Value=$after;Kind=$kind}
::    if(-not$hasWritten-and-not(Same $current $before)-and-not(Same $current $desired)){throw 'Path changed after the immutable snapshot.'}
::    $mutations.Add((Mutation 'Environment' 'Path' $current $desired))
::    if($hasWritten){$oldWritten=[string]$state.GetValue('Path.Written',$null,$option);$oldWrittenKind=[int]$state.GetValue('Path.Written.Kind',0,$option);if($oldWrittenKind-notin@(1,2)){throw 'Path written state has an unsafe kind.'};$matchesOld=$current.Exists-and[int]$current.Kind-eq$oldWrittenKind-and[string]$current.Value-ceq$oldWritten;$recordedValue=if($matchesOld){$after}else{$oldWritten};$recordedKind=if($matchesOld){$kind}else{$oldWrittenKind}}else{$recordedValue=$after;$recordedKind=$kind}
::    $metadata.Add((Metadata 'Path.Written' $true $recordedValue 1));$metadata.Add((Metadata 'Path.Written.Kind' $true $recordedKind 4));$metadata.Add((Metadata 'Path.Entries' $true ([string[]]$newOwned) 7))
::} elseif($Mode-eq'Environment') {
::    $key=$hive.OpenSubKey('Environment');if(-not$key){throw 'Target Environment key is missing.'}
::    $writes=[ordered]@{XDG_CONFIG_HOME=$env:ROOT;CP_SETUP_ROOT=$env:ROOT;CP_PYTHON=$env:CP_PYTHON;CP_GPP=$env:CP_GPP;CP_JAVAC=$env:CP_JAVAC;CP_JAVA=$env:CP_JAVA}
::    try {
::        foreach($name in $writes.Keys){
::            $value=[string]$writes[$name];if([string]::IsNullOrWhiteSpace($value)){throw ('Missing intended environment value: '+$name)}
::            $current=Read-Value $key $name;$before=Snapshot ('Env.'+$name);$desired=[ordered]@{Exists=$true;Value=$value;Kind=1}
::            $written='Env.'+$name+'.Written';$writtenKind=$written+'.Kind';$hasWritten=$stateNames-contains$written;$hasKind=$stateNames-contains$writtenKind
::            if($hasWritten-xor$hasKind){throw ('Incomplete written state: '+$name)}
::            if($hasWritten){$oldValue=[string]$state.GetValue($written,$null,$option);$oldKind=[int]$state.GetValue($writtenKind,0,$option);if($oldKind-ne 1){throw ('Written state has an unsafe kind: '+$name)};$oldDesired=[ordered]@{Exists=$true;Value=$oldValue;Kind=$oldKind};if(-not(Same $current $oldDesired)-and-not(Same $current $desired)){throw ('User-modified environment value: '+$name)}}
::            elseif(-not(Same $current $before)-and-not(Same $current $desired)){throw ('Environment changed after snapshot: '+$name)}
::            $mutations.Add((Mutation 'Environment' $name $current $desired));$metadata.Add((Metadata $written $true $value 1));$metadata.Add((Metadata $writtenKind $true 1 4))
::        }
::    } finally {$key.Dispose()}
::} elseif($Mode-eq'VTL') {
::    $key=$hive.OpenSubKey('Console');if($key){try{$current=Read-Value $key 'VirtualTerminalLevel'}finally{$key.Dispose()}}else{$current=[ordered]@{Exists=$false;Value=$null;Kind=0}}
::    $hadName='Console.VirtualTerminal.HadValue';if($stateNames-notcontains$hadName-or$state.GetValueKind($hadName)-ne[Microsoft.Win32.RegistryValueKind]::DWord){throw 'Missing immutable VTL snapshot.'}
::    $had=[int]$state.GetValue($hadName,0,$option);if($had-eq 0){$before=[ordered]@{Exists=$false;Value=$null;Kind=0}}elseif($had-eq 1-and$stateNames-contains'Console.VirtualTerminal.Before'-and$stateNames-contains'Console.VirtualTerminal.Before.Kind'){$before=[ordered]@{Exists=$true;Value=[int]$state.GetValue('Console.VirtualTerminal.Before',0,$option);Kind=[int]$state.GetValue('Console.VirtualTerminal.Before.Kind',0,$option)}}else{throw 'Incomplete immutable VTL snapshot.'}
::    if($before.Exists-and[int]$before.Kind-ne 4){throw 'Unsupported immutable VTL kind.'}
::    $desired=[ordered]@{Exists=$true;Value=1;Kind=4};$hasWritten=$stateNames-contains'Console.VirtualTerminal.Written';$hasKind=$stateNames-contains'Console.VirtualTerminal.Written.Kind'
::    if($hasWritten-xor$hasKind){throw 'Incomplete VTL ownership state.'}
::    $safe=$true;if($hasWritten){$old=[ordered]@{Exists=$true;Value=[int]$state.GetValue('Console.VirtualTerminal.Written',0,$option);Kind=[int]$state.GetValue('Console.VirtualTerminal.Written.Kind',0,$option)};if(-not(Same $current $old)-and-not(Same $current $desired)){$safe=$false}}elseif(-not(Same $current $before)-and-not(Same $current $desired)){$safe=$false}
::    if($safe){$mutations.Add((Mutation 'Console' 'VirtualTerminalLevel' $current $desired));$metadata.Add((Metadata 'Console.VirtualTerminal.Written' $true 1 4));$metadata.Add((Metadata 'Console.VirtualTerminal.Written.Kind' $true 4 4))}
::} else {
::    $key=$hive.OpenSubKey('Software\Microsoft\Command Processor');if(-not$key){throw 'Target Command Processor key is missing.'}
::    try{$current=Read-Value $key 'AutoRun'}finally{$key.Dispose()}
::    $before=Snapshot 'AutoRun';$command='doskey /macrofile="'+$env:MACROS+'"';$beforeText=if($before.Exists){[string]$before.Value}else{''}
::    if($beforeText.IndexOf($command,[StringComparison]::OrdinalIgnoreCase)-lt 0){
::        $hasEntry=$stateNames-contains'AutoRun.Entry';$hasWritten=$stateNames-contains'AutoRun.Written';$hasKind=$stateNames-contains'AutoRun.Written.Kind'
::        if(($hasEntry-or$hasWritten-or$hasKind)-and-not($hasEntry-and$hasWritten-and$hasKind)){throw 'Incomplete AutoRun ownership state.'}
::        if($hasEntry-and[string]$state.GetValue('AutoRun.Entry',$null,$option)-cne$command){throw 'AutoRun entry state is inconsistent.'}
::        $baseText=if($hasEntry-and$current.Exists){[string]$current.Value}elseif($hasEntry){''}else{$beforeText}
::        $kept=$baseText
::        while($true){$offset=0;$found=-1;while($offset-le$kept.Length-$command.Length){$candidate=$kept.IndexOf($command,$offset,[StringComparison]::OrdinalIgnoreCase);if($candidate-lt 0){break};$leftOk=$candidate-eq 0-or($candidate-ge 3-and$kept.Substring($candidate-3,3)-ceq' & ');$right=$candidate+$command.Length;$rightOk=$right-eq$kept.Length-or($right+3-le$kept.Length-and$kept.Substring($right,3)-ceq' & ');if($leftOk-and$rightOk){$found=$candidate;break};$offset=$candidate+1};if($found-lt 0){break};$right=$found+$command.Length;if($found-ge 3-and$kept.Substring($found-3,3)-ceq' & '){$kept=$kept.Remove($found-3,$command.Length+3)}elseif($right+3-le$kept.Length-and$kept.Substring($right,3)-ceq' & '){$kept=$kept.Remove($found,$command.Length+3)}else{$kept=''}}
::        $after=if([string]::IsNullOrWhiteSpace($kept)){$command}else{$kept.TrimEnd()+' & '+$command};$kind=if($current.Exists){[int]$current.Kind}elseif($hasEntry){[int]$state.GetValue('AutoRun.Written.Kind',0,$option)}elseif($before.Exists){[int]$before.Kind}else{1};if($kind-notin@(1,2)){throw 'Unsafe current AutoRun kind.'};$desired=[ordered]@{Exists=$true;Value=$after;Kind=$kind}
::        if(-not$hasEntry-and-not(Same $current $before)-and-not(Same $current $desired)){throw 'AutoRun changed after the immutable snapshot.'}
::        $recordedValue=if($hasEntry){[string]$state.GetValue('AutoRun.Written',$null,$option)}else{$after};$recordedKind=if($hasEntry){[int]$state.GetValue('AutoRun.Written.Kind',0,$option)}else{$kind}
::        $mutations.Add((Mutation 'Software\Microsoft\Command Processor' 'AutoRun' $current $desired));$metadata.Add((Metadata 'AutoRun.Entry' $true $command 1));$metadata.Add((Metadata 'AutoRun.Written' $true $recordedValue 1));$metadata.Add((Metadata 'AutoRun.Written.Kind' $true $recordedKind 4))
::    }
::}
::$metadataBefore=[Collections.Generic.List[object]]::new()
::foreach($item in $metadata){$before=Read-Value $state ([string]$item.Name);$metadataBefore.Add([ordered]@{Name=[string]$item.Name;Exists=[bool]$before.Exists;Value=$before.Value;Kind=[int]$before.Kind})}
::$plan=[ordered]@{Version=1;Sid=$sid;Mode=$Mode;Mutations=@($mutations);Metadata=@($metadata);MetadataBefore=@($metadataBefore)}
::function Encode($value){$json=$value|ConvertTo-Json -Depth 12 -Compress;[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))}
::$planJson=$plan|ConvertTo-Json -Depth 12 -Compress
::$planBytes=[Text.Encoding]::UTF8.GetBytes($planJson)
::$planEncoded=[Convert]::ToBase64String($planBytes)
::$sha=[Security.Cryptography.SHA256]::Create();try{$planHash=([BitConverter]::ToString($sha.ComputeHash($planBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::$preparedIntent='v1|'+$Mode+'|prepared|'+$planHash+'|'+$planEncoded
::$committedIntent='v1|'+$Mode+'|committed|'+$planHash+'|'+$planEncoded
::$workerTemplate=@'
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::$plan=ConvertFrom-Json ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__')))
::$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
::if($identity.User.Value-ine[Security.Principal.SecurityIdentifier]::new($plan.Sid).Value){throw 'Registry worker SID mismatch.'}
::if(([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Registry worker unexpectedly has an elevated token.'}
::$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::function Read-Value($key,[string]$name){$exists=@($key.GetValueNames())-contains$name;if(-not$exists){return [pscustomobject]@{Exists=$false;Value=$null;Kind=0}};$kind=[int]$key.GetValueKind($name);$value=$key.GetValue($name,$null,$option);if($kind-in@(1,2)){$value=[string]$value}elseif($kind-eq 4){$value=[int]$value}elseif($kind-eq 7){$value=[string[]]@($value)}else{throw ('Unsupported registry kind: '+$name)};[pscustomobject]@{Exists=$true;Value=$value;Kind=$kind}}
::function Same($left,$right){if([bool]$left.Exists-ne[bool]$right.Exists){return $false};if(-not$left.Exists){return $true};if([int]$left.Kind-ne[int]$right.Kind){return $false};if([int]$right.Kind-eq 7){$a=@($left.Value);$b=@($right.Value);if($a.Count-ne$b.Count){return $false};for($i=0;$i-lt$a.Count;$i++){if([string]$a[$i]-ine[string]$b[$i]){return $false}};return $true};if([int]$right.Kind-eq 4){return [int]$left.Value-eq[int]$right.Value};[string]$left.Value-ceq[string]$right.Value}
::function Value($spec){if([int]$spec.Kind-eq 7){return [string[]]@($spec.Value)};if([int]$spec.Kind-eq 4){return [int]$spec.Value};[string]$spec.Value}
::function Apply($mutation,$expected,$desired){$key=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey([string]$mutation.Key,$true);if(-not$key-and[string]$mutation.Key-ceq'Console'){$key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Console',[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)};if(-not$key){throw ('Target registry key is missing: '+$mutation.Key)};try{$current=Read-Value $key ([string]$mutation.Name);if(-not(Same $current $expected)){throw ('Concurrent target registry change: '+$mutation.Name)};if($desired.Exists){$key.SetValue([string]$mutation.Name,(Value $desired),[Microsoft.Win32.RegistryValueKind][int]$desired.Kind)}else{$key.DeleteValue([string]$mutation.Name,$false)};if(-not(Same (Read-Value $key ([string]$mutation.Name)) $desired)){throw ('Target registry write did not verify: '+$mutation.Name)}}finally{$key.Dispose()}}
::$changed=[Collections.Generic.List[object]]::new()
::try{foreach($mutation in @($plan.Mutations)){$changed.Add($mutation);Apply $mutation $mutation.Expected $mutation.Desired}}
::catch{$failure=$_;for($i=$changed.Count-1;$i-ge 0;$i--){$mutation=$changed[$i];try{Apply $mutation $mutation.Desired $mutation.Expected}catch{}};throw $failure}
::'@
::$workerSource=$workerTemplate.Replace('__PAYLOAD__',$planEncoded)
::$rollbackMutations=@(foreach($mutation in $mutations){[ordered]@{Key=$mutation.Key;Name=$mutation.Name;Expected=$mutation.Desired;Desired=$mutation.Expected}})
::$rollback=[ordered]@{Version=1;Sid=$sid;Mode=$Mode;Mutations=$rollbackMutations;Metadata=@();MetadataBefore=@()}
::$rollbackSource=$workerTemplate.Replace('__PAYLOAD__',(Encode $rollback))
::$commitTemplate=@'
::$ErrorActionPreference='Stop'
::Set-StrictMode -Version 2
::$plan=ConvertFrom-Json ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__')))
::$option=[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
::$users=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users,[Microsoft.Win32.RegistryView]::Default)
::$machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default)
::$hive=$users.OpenSubKey([string]$plan.Sid);$state=$machine.OpenSubKey('Software\my-cp-setup\Users\'+$plan.Sid,$true)
::if(-not$hive-or-not$state){throw 'Registry commit state is missing.'}
::$pendingName='Pending.Registry.Intent';if(@($state.GetValueNames())-notcontains$pendingName-or$state.GetValueKind($pendingName)-ne[Microsoft.Win32.RegistryValueKind]::String-or[string]$state.GetValue($pendingName,$null,$option)-cne'__PREPARED__'){throw 'Protected registry intent changed before commit.'}
::function Read-Spec($key,[string]$name){$exists=@($key.GetValueNames())-contains$name;if(-not$exists){return [pscustomobject]@{Exists=$false;Value=$null;Kind=0}};$kind=[int]$key.GetValueKind($name);$value=$key.GetValue($name,$null,$option);[pscustomobject]@{Exists=$true;Value=$value;Kind=$kind}}
::function Same($left,$right){if([bool]$left.Exists-ne[bool]$right.Exists){return $false};if(-not$left.Exists){return $true};if([int]$left.Kind-ne[int]$right.Kind){return $false};if([int]$right.Kind-eq 7){$a=@($left.Value);$b=@($right.Value);if($a.Count-ne$b.Count){return $false};for($i=0;$i-lt$a.Count;$i++){if([string]$a[$i]-ine[string]$b[$i]){return $false}};return $true};[string]$left.Value-ceq[string]$right.Value}
::function Set-Spec($key,$spec){if($spec.Exists){$value=if([int]$spec.Kind-eq 7){[string[]]@($spec.Value)}elseif([int]$spec.Kind-eq 4){[int]$spec.Value}else{[string]$spec.Value};$key.SetValue([string]$spec.Name,$value,[Microsoft.Win32.RegistryValueKind][int]$spec.Kind)}else{$key.DeleteValue([string]$spec.Name,$false)}}
::$saved=[Collections.Generic.List[object]]::new();$committed=$false
::try{
::    foreach($mutation in @($plan.Mutations)){$key=$hive.OpenSubKey([string]$mutation.Key);if(-not$key){throw ('Target registry key vanished: '+$mutation.Key)};try{if(-not(Same (Read-Spec $key ([string]$mutation.Name)) $mutation.Desired)){throw ('Target registry verification failed: '+$mutation.Name)}}finally{$key.Dispose()}}
::    foreach($item in @($plan.Metadata)){$before=Read-Spec $state ([string]$item.Name);$before|Add-Member -NotePropertyName Name -NotePropertyValue ([string]$item.Name);$saved.Add($before);Set-Spec $state $item;if(-not(Same (Read-Spec $state ([string]$item.Name)) $item)){throw ('Protected registry metadata did not verify: '+$item.Name)}}
::    $state.SetValue($pendingName,'__COMMITTED__',[Microsoft.Win32.RegistryValueKind]::String);if([string]$state.GetValue($pendingName,$null,$option)-cne'__COMMITTED__'){throw 'Protected registry commit marker did not verify.'};$committed=$true
::    $state.DeleteValue($pendingName,$false);if(@($state.GetValueNames())-contains$pendingName){throw 'Protected registry intent could not be cleared.'}
::}catch{$failure=$_;if(-not$committed){for($i=$saved.Count-1;$i-ge 0;$i--){try{Set-Spec $state $saved[$i]}catch{}}};throw $failure}
::finally{foreach($key in @($hive,$state,$users,$machine)){if($key){$key.Dispose()}}}
::'@
::$commitSource=$commitTemplate.Replace('__PAYLOAD__',$planEncoded).Replace('__PREPARED__',$preparedIntent).Replace('__COMMITTED__',$committedIntent)
::[IO.File]::WriteAllText($WorkerScript,$workerSource,[Text.UTF8Encoding]::new($false))
::[IO.File]::WriteAllText($RollbackScript,$rollbackSource,[Text.UTF8Encoding]::new($false))
::[IO.File]::WriteAllText($CommitScript,$commitSource,[Text.UTF8Encoding]::new($false))
::if(@($state.GetValueNames())-contains'Pending.Registry.Intent'){throw 'Another registry transaction is pending.'}
::$state.SetValue('Pending.Registry.Intent',$preparedIntent,[Microsoft.Win32.RegistryValueKind]::String)
::if($state.GetValueKind('Pending.Registry.Intent')-ne[Microsoft.Win32.RegistryValueKind]::String-or[string]$state.GetValue('Pending.Registry.Intent',$null,$option)-cne$preparedIntent){throw 'Protected registry intent did not verify.'}
::foreach($key in @($hive,$state,$users,$machine)){if($key){$key.Dispose()}}
::__CP_USER_REGISTRY_PLAN_END__

::__CP_MEDIUM_LAUNCHER_BEGIN__
::param(
::    [Parameter(Mandatory=$true)][string]$WorkerScript,
::    [Parameter(Mandatory=$true)][string]$TargetSid,
::    [Parameter(Mandatory=$true)][string]$System32,
::    [Parameter(Mandatory=$true)][string]$ExecTemp,
::    [Parameter(Mandatory=$true)][string]$NativeSource,
::    [ValidateRange(1,3600)][int]$TimeoutSeconds,
::    [ValidateSet('None','Lazy','Mason')][string]$OperationKind='None'
::)
::$ErrorActionPreference = 'Stop'
::Set-StrictMode -Version 2
::function Full([string]$path) { [IO.Path]::GetFullPath($path).TrimEnd([char]92) }
::function Assert-NoReparse([string]$path) {
::    $full = Full $path
::    $root = [IO.Path]::GetPathRoot($full)
::    $current = $root
::    foreach ($part in $full.Substring($root.Length).Split([char[]]@([char]92),[StringSplitOptions]::RemoveEmptyEntries)) {
::        $current = [IO.Path]::Combine($current,$part)
::        if ([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) { throw ('Reparse point rejected: ' + $current) }
::    }
::    $full
::}
::try {
::    $execRoot = Assert-NoReparse $ExecTemp
::    $prefix = $execRoot + [char]92
::    $worker = Assert-NoReparse $WorkerScript
::    $native = Assert-NoReparse $NativeSource
::    foreach ($path in @($worker,$native)) {
::        if (-not $path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists($path)) { throw 'Medium-worker source is outside protected EXEC_TEMP.' }
::    }
::    $system32Full = Assert-NoReparse $System32
::    $windows = Full ([IO.Directory]::GetParent($system32Full).FullName)
::    $powershell = Assert-NoReparse ([IO.Path]::Combine($system32Full,'WindowsPowerShell\v1.0\powershell.exe'))
::    $explorer = Assert-NoReparse ([IO.Path]::Combine($windows,'explorer.exe'))
::    $sid = ([Security.Principal.SecurityIdentifier]::new($TargetSid)).Value
::    $source = [IO.File]::ReadAllText($worker)
::    if ([string]::IsNullOrWhiteSpace($source)) { throw 'Medium-worker payload is empty.' }
::    $bootstrap=[Collections.Generic.List[string]]::new()
::    $sid64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sid));$bootstrap.Add('$env:CP_SETUP_TARGET_SID=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('''+$sid64+'''))')
::    foreach($name in @('CP_SETUP_TARGET_TEMP','CP_SETUP_LOG_SOURCE','CP_SETUP_LOG_EXEC_ROOT')){if([Environment]::GetEnvironmentVariable($name)){ $value=[IO.Path]::GetFullPath([Environment]::GetEnvironmentVariable($name));$value64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($value));$bootstrap.Add('$env:'+$name+'=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('''+$value64+'''))') }}
::    if($env:CP_SETUP_LOG_NAME){$name64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($env:CP_SETUP_LOG_NAME));$bootstrap.Add('$env:CP_SETUP_LOG_NAME=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('''+$name64+'''))')}
::    $source=($bootstrap-join[Environment]::NewLine)+[Environment]::NewLine+$source
::    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($source))
::    Add-Type -Path $native -ErrorAction Stop
::    $intent=$null
::    if($OperationKind-ne'None'){
::        $statePath='Software\my-cp-setup\Users\'+$sid
::        $machine=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default)
::        $state=$machine.OpenSubKey($statePath,$true)
::        if(-not$state){throw 'Protected active-operation state is missing.'}
::        $sha=[Security.Cryptography.SHA256]::Create()
::        try{$workerHash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($source)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::        $imageBytes=[Text.Encoding]::UTF8.GetBytes($powershell)
::        $sha=[Security.Cryptography.SHA256]::Create()
::        try{$pathHash=([BitConverter]::ToString($sha.ComputeHash($imageBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
::        $imageHash=(Get-FileHash -LiteralPath $powershell -Algorithm SHA256).Hash.ToLowerInvariant()
::        $current=[Diagnostics.Process]::GetCurrentProcess();$nonce=[guid]::NewGuid().ToString('N')
::        $intent='v1|'+$nonce+'|'+$OperationKind+'|'+$PID+'|'+$current.StartTime.ToUniversalTime().Ticks+'|'+$current.SessionId+'|'+$sid+'|'+$imageHash+'|'+$workerHash+'|'+$pathHash+'|'+[Convert]::ToBase64String($imageBytes)
::        if(@($state.GetValueNames())-contains'Active.Operation.Intent'){throw 'Another setup-managed Neovim operation is active.'}
::        $state.SetValue('Active.Operation.Intent',$intent,[Microsoft.Win32.RegistryValueKind]::String)
::        if([string]$state.GetValue('Active.Operation.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$intent){throw 'Active-operation marker did not verify.'}
::    }
::    try {
::        $code = [CpSetup.Native.MediumTokenRunner]::Run($sid,$explorer,$powershell,$system32Full,$encoded,$TimeoutSeconds)
::    } finally {
::        if($intent){
::            try{if([string]$state.GetValue('Active.Operation.Intent',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)-cne$intent){throw 'Active-operation marker changed.'};$state.DeleteValue('Active.Operation.Intent',$false);if(@($state.GetValueNames())-contains'Active.Operation.Intent'){throw 'Active-operation marker cleanup failed.'}}finally{$state.Dispose();$machine.Dispose()}
::        }
::    }
::    exit $code
::} catch {
::    [Console]::Error.WriteLine('Target-user worker could not start: ' + $_.Exception.Message)
::    exit 125
::}
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
::if(timeoutSeconds<1||timeoutSeconds>3600)throw new ArgumentOutOfRangeException("timeoutSeconds");
::string commandText="\""+powershell+"\" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand "+payload;
::if(commandText.Length>=32760)throw new InvalidOperationException("Encoded worker payload exceeds the Windows command-line limit.");
::StringBuilder command=new StringBuilder(commandText,32768);int session=Process.GetCurrentProcess().SessionId;
::IntPtr userToken=IntPtr.Zero,environment=IntPtr.Zero,job=IntPtr.Zero,input=IntPtr.Zero,output=IntPtr.Zero,error=IntPtr.Zero,attributes=IntPtr.Zero,handleArray=IntPtr.Zero;
::PROCESS_INFORMATION child=new PROCESS_INFORMATION();bool created=false,assigned=false,exited=false;
::try{
::if(!EnablePrivilege("SeImpersonatePrivilege"))throw new InvalidOperationException("SeImpersonatePrivilege is unavailable.");
::userToken=ExplorerToken(sid,Path.GetFullPath(explorer),session);if(!CreateEnvironmentBlock(out environment,userToken,false))Fail("CreateEnvironmentBlock");
::input=StandardHandle(-10);output=StandardHandle(-11);error=StandardHandle(-12);
::IntPtr attributeSize=IntPtr.Zero;InitializeProcThreadAttributeList(IntPtr.Zero,1,0,ref attributeSize);if(attributeSize==IntPtr.Zero)Fail("InitializeProcThreadAttributeList(size)");
::attributes=Marshal.AllocHGlobal(attributeSize);if(!InitializeProcThreadAttributeList(attributes,1,0,ref attributeSize))Fail("InitializeProcThreadAttributeList");
::handleArray=Marshal.AllocHGlobal(IntPtr.Size*3);Marshal.WriteIntPtr(handleArray,0,input);Marshal.WriteIntPtr(handleArray,IntPtr.Size,output);Marshal.WriteIntPtr(handleArray,IntPtr.Size*2,error);
::if(!UpdateProcThreadAttribute(attributes,0,HandleListAttribute,handleArray,new IntPtr(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero))Fail("UpdateProcThreadAttribute");
::STARTUPINFOEX startup=new STARTUPINFOEX();startup.StartupInfo.cb=Marshal.SizeOf(typeof(STARTUPINFOEX));startup.StartupInfo.lpDesktop="winsta0\\default";startup.StartupInfo.dwFlags=STARTF_USESTDHANDLES;startup.StartupInfo.hStdInput=input;startup.StartupInfo.hStdOutput=output;startup.StartupInfo.hStdError=error;startup.lpAttributeList=attributes;
::job=CreateJobObject(IntPtr.Zero,null);if(job==IntPtr.Zero)Fail("CreateJobObject");JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits=new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();limits.BasicLimitInformation.LimitFlags=JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;if(!SetInformationJobObject(job,JobObjectExtendedLimitInformation,ref limits,(uint)Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION))))Fail("SetInformationJobObject");
::uint flags=CREATE_SUSPENDED|CREATE_UNICODE_ENVIRONMENT|EXTENDED_STARTUPINFO_PRESENT|CREATE_NO_WINDOW;if(!CreateProcessWithTokenW(userToken,0,powershell,command,flags,environment,systemDirectory,ref startup,out child))Fail("CreateProcessWithTokenW");created=true;
::if(!AssignProcessToJobObject(job,child.hProcess))Fail("AssignProcessToJobObject");assigned=true;if(ResumeThread(child.hThread)==0xffffffff)Fail("ResumeThread");Close(ref child.hThread);
::uint wait=WaitForSingleObject(child.hProcess,checked((uint)timeoutSeconds*1000));if(wait==WAIT_TIMEOUT){Console.Error.WriteLine("Target-user worker timed out after "+timeoutSeconds+" seconds.");TerminateJobObject(job,124);WaitForSingleObject(child.hProcess,5000);return 124;}if(wait==WAIT_FAILED)Fail("WaitForSingleObject");if(wait!=WAIT_OBJECT_0)throw new InvalidOperationException("Unexpected worker wait result.");exited=true;uint code;if(!GetExitCodeProcess(child.hProcess,out code))Fail("GetExitCodeProcess");return unchecked((int)code);
::}finally{if(created&&!exited){if(assigned&&job!=IntPtr.Zero)TerminateJobObject(job,125);else if(child.hProcess!=IntPtr.Zero)TerminateProcess(child.hProcess,125);if(child.hProcess!=IntPtr.Zero)WaitForSingleObject(child.hProcess,5000);}Close(ref child.hThread);Close(ref child.hProcess);Close(ref job);if(attributes!=IntPtr.Zero){DeleteProcThreadAttributeList(attributes);Marshal.FreeHGlobal(attributes);}if(handleArray!=IntPtr.Zero)Marshal.FreeHGlobal(handleArray);Close(ref input);Close(ref output);Close(ref error);if(environment!=IntPtr.Zero)DestroyEnvironmentBlock(environment);Close(ref userToken);}
::}
::}
::}
::__CP_MEDIUM_NATIVE_END__
