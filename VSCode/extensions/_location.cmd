@CALL "%~dp0..\..\bin\getfetchlocation.bat" vscode-extensions
START explorer.exe "%LOCATION%\."
@IF ERRORLEVEL 1 ECHO ERRORLEVEL=%ERRORLEVEL%
@IF ERRORLEVEL 1 PAUSE
