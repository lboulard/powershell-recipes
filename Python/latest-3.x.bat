@SETLOCAL
@CD /D "%~dp0"
@SET "NAME=%~n0"
@SET "VERSION=%NAME:latest-=%"

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile -Command "%~dp0latest.ps1" -Version "%VERSION%" -GetDevRelease
) ELSE (
  PowerShell.exe -noprofile -Command "%~dp0latest.ps1" -Version "%VERSION%" -GetDevRelease
)
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
