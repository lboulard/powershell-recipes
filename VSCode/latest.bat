@TYPE NUL>NUL
@SETLOCAL
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile -Command "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile -Command "%~dpn0.ps1"
)

:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
