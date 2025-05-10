@SETLOCAL

@CALL "%~dp0..\bin\getfetchlocation.bat" "vim-lboulard"
CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit

WHERE /Q pwsh.exe
IF ERRORLEVEL 1 (
 powershell.exe -noprofile -ex unrestricted -file "%~dpn0.ps1" %*
) ELSE (
 pwsh.exe -noprofile -ex unrestricted -file "%~dpn0.ps1" %*
)

:exit
:: Pause if not interactive
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL & EXIT /B %ERR%
