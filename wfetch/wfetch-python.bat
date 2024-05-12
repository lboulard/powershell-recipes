@REM Pause when started from explorer
@CD /D "%~dp0"
::PUSHD ..\Python3.10
::wfetch -p python3.10
::POPD
PUSHD ..\Python3.11
wfetch -p python3.11
POPD
PUSHD ..\Python3.12
wfetch -p python3.12
POPD
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
