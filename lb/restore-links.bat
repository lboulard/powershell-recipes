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


@CALL :symlink ".\bin\z.cmd" "..\..\Scoop\apps\z.lua\current\z.cmd"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :symlink  ".\bin\z.lua" "..\..\Scoop\apps\z.lua\current\z.lua"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :symlink ".\clink_modules\z.cmd" "..\..\Scoop\apps\z.lua\current\z.cmd"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :symlink ".\clink_modules\z.lua" "..\..\Scoop\apps\z.lua\current\z.lua"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :hardlink ".\bin\uncrustify.exe" "%SCOOP%\apps\uncrustify\current\bin\uncrustify.exe"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :junction "clink" "%CD%\clink.1.6.3"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :junction "Apps\chaiNNER" "Apps\chaiNNer-windows-x64-0.20.2"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\ipe" "Apps\ipe-7.2.28"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\tcl" "Apps\tcltk86-8.6.13.1.tcl86.Win10.x86_64"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :junction "Apps\groff\dist" "Apps\groff\dist-2023-03-31"
@IF ERRORLEVEL 1 GOTO :exit


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF DEFINED _ELEV GOTO :_elev
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@:_elev
@ENDLOCAL&EXIT /B %ERR%

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

