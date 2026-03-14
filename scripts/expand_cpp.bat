@echo off
setlocal

REM source file
set "SRC=%~1"
set "DIR=%~dp1"

REM repo root
set "ROOT=%~dp0.."

REM libraries
set "CPLIB=%ROOT%\my_libraries\cp.hpp"
set "ACL=%ROOT%\ac-library"

REM temp + output
set "TMP=%DIR%solve_expand.cpp"
set "OUT=%DIR%submit.cpp"

REM concat header + source
type "%CPLIB%" "%SRC%" > "%TMP%"

REM remove include + pragma once
findstr /v "my_libraries/cp.hpp" "%TMP%" | findstr /v "#pragma once" > "%TMP%.clean"
move /y "%TMP%.clean" "%TMP%" >nul

REM run ACL expander
cd /d "%ACL%"
python expander.py -c "%TMP%" > "%OUT%" 2>nul

REM copy result to clipboard
type "%OUT%" | clip

REM cleanup
del "%TMP%" >nul

endlocal