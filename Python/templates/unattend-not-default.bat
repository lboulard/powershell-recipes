@SETLOCAL
@CD "%~dp0"
@IF EXIST unattend.xml DEL unattend.xml
mklink unattend.xml unattend-not-defaultpy.xml
@IF NOT ERRORLEVEL 1 GOTO :EOF
@:NagUser
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
