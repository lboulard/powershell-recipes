@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
@CD /D "%~dp0"
@CALL "%~dp0\..\bin\getfetchlocation.bat" p4merge

@SET "V=24.4"
@SET "DEST=p4-20%V%"

@IF NOT EXIST "%LOCATION%\%DEST%\." @MD "%LOCATION%\%DEST%"
CD /D "%LOCATION%\%DEST%"

curl -# -f -JLR --remote-name-all --parallel --parallel-max 4^
 https://cdist2.perforce.com/perforce/r%V%/bin.ntx64/p4vinst64.exe^
 https://cdist2.perforce.com/perforce/r%V%/bin.macosx12u/P4V.dmg^
 https://cdist2.perforce.com/perforce/r%V%/bin.linux26x86_64/p4v.tgz 
 
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL & EXIT /B %ERR%
