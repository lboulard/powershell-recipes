:: https://community.perforce.com/s/article/17304
@SETLOCAL

@CALL "%~dp0\..\bin\getfetchlocation.bat" p4merge
CD /D "%LOCATION%"

@SET DIR=p4-2024.4

@IF NOT EXIST %DIR% CD /D %~dp0
@IF "%1"=="uninstall" GOTO :Uninstall

START /WAIT %DIR%\p4vinst64.exe /passive /l p4v.log /norestart^
 REMOVEAPPS=P4V,P4ADMIN,P4 NOINTERNETSHORCUTS

@ENDLOCAL
@GOTO :EOF

@:Uninstall
START /WAIT %DIR%\p4vinst64.exe /uninstall /passive^
 DELETESETTINGS
@ENDLOCAL
