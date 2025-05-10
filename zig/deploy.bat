@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "zig"
CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit
@ECHO OFF

@where /Q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)

:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
