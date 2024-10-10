@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
@CD /D "%~dp0"

@SET "V=24.3"
@SET "DEST=p4-20%V%"

@IF NOT EXIST "%DEST%\." @MD "%DEST%"
@CD ".\%DEST%"

curl -# -f -JLR --remote-name-all --parallel --parallel-max 4^
 https://cdist2.perforce.com/perforce/r%V%/bin.ntx64/p4vinst64.exe^
 https://cdist2.perforce.com/perforce/r%V%/bin.macosx12u/P4V.dmg^
 https://cdist2.perforce.com/perforce/r%V%/bin.linux26x86_64/p4v.tgz 
 
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL & EXIT /B %ERR%
