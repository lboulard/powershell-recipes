@SETLOCAL
@SET "_N=%~n0"
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dp0%_N:-dev=%.ps1" -DevOnly
) ELSE (
  PowerShell.exe -noprofile "%~dpn0%_N:-dev=%.ps1" -DevOnly
)
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
