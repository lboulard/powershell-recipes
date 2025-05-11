@SETLOCAL

@SET "NAME=%~n0"
@SET "VERSION=%~1"
@IF "%VERSION%"=="" SET "VERSION=%NAME:latest-=%"
@IF "%VERSION%"=="" @(
  @ECHO.No VERSION found>&2
  @GOTO :exit
)

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile -Command "%~dp0latest.ps1" -Version "%VERSION%" -GetDevRelease
) ELSE (
  PowerShell.exe -noprofile -Command "%~dp0latest.ps1" -Version "%VERSION%" -GetDevRelease
)

:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~dp0latest-3." >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
