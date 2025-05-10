@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "java-azul"
@CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)

:exit
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
