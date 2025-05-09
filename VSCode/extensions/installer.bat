@SETLOCAL
@CHCP 65001

@CALL "%~dp0..\..\bin\getfetchlocation.bat" "vscode-extensions"
@IF ERRORLEVEL 1 GOTO :exit

echo.[Setup]>"%LOCATION%\sourcedir.inc.iss"
echo.SourceDir=%LOCATION%>>"%LOCATION%\sourcedir.inc.iss"

@SET "LOG=%LOCATION%\%~n0.log"
IF NOT ERRORLEVEL 1 "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"^
  /J"%LOCATION%\sourcedir.inc.iss"^
  /O"%LOCATION%\installers"^
  "%~dpn0.iss" >"%LOG%"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in (%LOG%) DO @(
    SET /A LINES=LINES+1
)

:: Print the last 2 lines
@SET /A LINES=LINES-2
@MORE +%LINES% < "%LOG%"

:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
