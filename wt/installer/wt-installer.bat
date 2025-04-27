@SETLOCAL
@CHCP 65001
@where /q pwsh.exe
@IF %ERRORLEVEL% EQU 0 (
  pwsh.exe -noprofile "%~dpn0.ps1"
) ELSE (
  PowerShell.exe -noprofile "%~dpn0.ps1"
)
IF NOT ERRORLEVEL 1 "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" "%~n0.iss" >"%~n0.log"

:: Get the number of lines in the file
@SET LINES=0
@FOR /F "delims==" %%I in (%~n0.log) DO @(
    SET /A LINES=LINES+1
)

:: Print the last 2 lines
@SET /A LINES=LINES-2
@MORE +%LINES% < "%~n0.log"

@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
