@SETLOCAL
@CHCP 65001
@CD /D "%~dp0"

@CALL "%~dp0..\..\bin\getfetchlocation.bat" vscode
@IF NOT EXIST "%LOCATION%\installer\." MD "%LOCATION%\installer"
CD /D "%LOCATION%\installer"

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)

@SET "LOG=%~n0.log"
IF NOT ERRORLEVEL 1 "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"^
  /I"%LOCATION%\installer"^
  /O"%LOCATION%"^
  "%~dpn0.iss" >"%LOG%"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in (%LOG%) DO @(
    SET /A LINES=LINES+1
)

:: Print the last 3 lines
@SET /A LINES=LINES-3
@MORE +%LINES% < "%LOG%"

@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
