@CALL "%~dp0..\bin\getfetchlocation.bat" fonts-iosevka
START explorer.exe "%LOCATION%\."
@IF ERRORLEVEL 1 ECHO ERRORLEVEL=%ERRORLEVEL%
@IF ERRORLEVEL 1 PAUSE
