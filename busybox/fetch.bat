@SETLOCAL

@:: Always use Powershell 5 to support hardlink usage
PowerShell.exe -noprofile "%~dpn0.ps1"

@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
