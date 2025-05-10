@SETLOCAL
@CHCP 65001 >NUL

@CALL "%~dp0..\bin\getfetchlocation.bat" "fonts-cascadia"
@IF ERRORLEVEL 1 GOTO :exit

@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)
@IF ERRORLEVEL 1 GOTO :exit

:: installer for main font

@SET "LOG=%LOCATION%\%~n0.log"

"%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"^
 /I"%LOCATION%"^
 /O"%LOCATION%\installers"^
 "%~dpn0.iss" >"%LOG%"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in ("%LOG%") DO @(
    SET /A LINES=LINES+1
)
:: Print the last 2 lines
@SET /A LINES=LINES-2
@MORE +%LINES% < "%LOG%"
@IF ERRORLEVEL 1 GOTO :exit

:: installer for font variants

@SET "LOG=%LOCATION%\%~n0.variants.log"

"%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"^
 /I"%LOCATION%"^
 /O"%LOCATION%\installers"^
 "%~dpn0.variants.iss" >"%LOG%"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in ("%LOG%") DO @(
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
