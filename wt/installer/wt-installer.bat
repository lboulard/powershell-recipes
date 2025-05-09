@SETLOCAL
@CHCP 65001

@CALL "%~dp0..\..\bin\getfetchlocation.bat" "microsoft-terminal"
@IF NOT EXIST "%LOCATION%\installer\." MD "%LOCATION%\installer"
CD /D "%LOCATION%\installer"

@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)

@SET "LOG=%~n0.log"
IF NOT ERRORLEVEL 1 "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"^
  /I"%LOCATION%\installer"^
  /O"%LOCATION%\installer\installers"^
  "%~dpn0.iss" >"%LOG%"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in (%LOG%) DO @(
    SET /A LINES=LINES+1
)

:: Print the last 2 lines
@SET /A LINES=LINES-2
@MORE +%LINES% < "%LOG%"

@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
