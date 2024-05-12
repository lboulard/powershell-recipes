@where /Q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh -noprofile -ex unrestricted -command "%~dpn0.ps1"
) else @(
  powershell -noprofile -ex unrestricted -command "%~dpn0.ps1"
)
:: Pause if not interactive
@ECHO %cmdcmdline% | @FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@EXIT /B
