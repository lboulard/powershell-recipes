@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "zig"
CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit
@ECHO OFF

@SET "_N=%~n0"
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dp0%_N:-dev=%.ps1" -DevOnly
) ELSE (
  PowerShell.exe -noprofile "%~dpn0%_N:-dev=%.ps1" -DevOnly
)

:exit
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
