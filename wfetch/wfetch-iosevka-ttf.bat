@REM Pause when started from explorer
@CD /D "%~dp0"
wfetch -p fonts-ttf-iosevka,fonts-ttf-iosevka-term,fonts-ttf-iosevka-fixed
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
