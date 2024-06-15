@SETLOCAL
@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile -Command "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile -Command "%~dpn0.ps1"
)
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
