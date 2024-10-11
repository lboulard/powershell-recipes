@SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
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

:: script folder location, without final backslash
@SET "HERE=%~dp0"
@IF "%HERE:~-1%"=="\" SET "HERE=!HERE:~0,-1!"

:: do not use dosbatch, our script is killed
clink_x64.exe uninstallscripts --all
clink_x64.exe installscripts "%HERE%"
clink_x64.exe installscripts "%HERE%\clink-completions"
clink_x64.exe installscripts "%HERE%\clink-flex-prompt"
clink_x64.exe installscripts "%HERE%\clink-gizmos"


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:absolute
@SET "RETVAL=%~f1"
@IF "%RETVAL:~-1%"=="\" SET "RETVAL=!RETVAL:~0,-1!"
@GOTO :EOF
