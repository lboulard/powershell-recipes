@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

@ECHO.

@CALL :python ..\Python3.13 3.13
@IF ERRORLEVEL 1 GOTO :exit
@CALL :python ..\Python3.12 3.12
@IF ERRORLEVEL 1 GOTO :exit
@CALL :python ..\Python3.11 3.11
@IF ERRORLEVEL 1 GOTO :exit
@CALL :python ..\Python3.10 3.10
@IF ERRORLEVEL 1 GOTO :exit
@CALL :python ..\Python3.9 3.9
@IF ERRORLEVEL 1 GOTO :exit
@CALL :python ..\Python3.8 3.8
@IF ERRORLEVEL 1 GOTO :exit

@CALL :python ..\Python2.7 2.7
@IF ERRORLEVEL 1 GOTO :exit

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF DEFINED _ELEV GOTO :_elev
@SET ERRORLEVEL=0
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@:_elev
@ENDLOCAL&EXIT /B %ERR%

:python
@CALL :symlink "%~1\latest.ps1" "%~dp0latest.ps1"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :hardlink "%~1\latest-%~2.bat" latest-3.x.bat
@IF ERRORLEVEL 1 GOTO :exit
@GOTO :EOF

:symlink
@IF EXIST "%~1" @DEL "%~1"
MKLINK "%~1" "%~2"
@IF ERRORLEVEL 1 @EXIT /B %ERRORLEVEL%
@GOTO :EOF

:hardlink
@IF EXIST "%~1" @DEL "%~1"
MKLINK /H "%~1" "%~2"
@IF ERRORLEVEL 1 @EXIT /B %ERRORLEVEL%
@GOTO :EOF

:junction
@IF EXIST "%~1\." @RD "%~1"
@IF EXIST "%~1" @(
  @ECHO Refuse to delete file "%~1"
  @SET ERRORLEVEL=128
  @GOTO :EOF
)
MKLINK /J "%~dpf1" "%~dpf2"
@IF ERRORLEVEL 1 @EXIT /B %ERRORLEVEL%
@GOTO :EOF
