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


@CALL :symlink z.lua ..\..\Scoop\apps\z.lua\current\z.lua
@CALL :symlink z.cmd ..\..\Scoop\apps\z.lua\current\z.cmd


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:symlink
@IF EXIST "%~1" @DEL /Q /F "%~1"
mklink "%~1" "%~2"
@GOTO :EOF
