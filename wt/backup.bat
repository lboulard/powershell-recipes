WHERE /Q pwsh.exe
IF ERRORLEVEL 1 (
 powershell.exe -noprofile -ex unrestricted -file "%~dpn0.ps1" %*
) ELSE (
 pwsh.exe -noprofile -ex unrestricted -file "%~dpn0.ps1" %*
)
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
