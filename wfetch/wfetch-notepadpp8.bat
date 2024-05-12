@REM Pause when started from explorer
@CD /D "%~dp0"
wfetch -p notepad++8
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
