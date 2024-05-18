@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @GOTO :exit
)
@TYPE NUL>NUL

@CALL :absolute "%~dp0..\clink"
@PATH %RETVAL%;%PATH%

:: do not use dosbatch, our script is killed
clink_x64.exe installscripts "%~dp0"
clink_x64.exe installscripts "%~dp0clink-completions"
clink_x64.exe installscripts "%~dp0clink-flex-prompt"
clink_x64.exe installscripts "%~dp0clink-fzf"


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:absolute
@SET "RETVAL=%~dpf1"
@GOTO :EOF
