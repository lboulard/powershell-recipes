@CALL "%~dp0..\bin\getfetchlocation.bat" hashcat
START explorer.exe "%LOCATION%\."
@IF ERRORLEVEL 1 ECHO ERRORLEVEL=%ERRORLEVEL%
@IF ERRORLEVEL 1 PAUSE
