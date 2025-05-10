@SETLOCAL EnableExtensions EnableDelayedExpansion
@CHCP 65001 >NUL:

@CALL "%~dp0..\bin\getfetchlocation.bat" "msys2"
CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit
@ECHO OFF

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @CALL :errorlevel 128
  @GOTO :exit
)
@TYPE NUL>NUL

@SET VERSION=notfound
@SET PRG=
@FOR /D %%d IN ("msys2-*") DO @(
  @FOR %%f IN ("%%d\msys2-base-x86_64-*.sfx.exe") DO @(
    @FOR /F "tokens=4 delims=-" %%s IN ("%%~nf") DO @(
      @REM date is YYYYMMDD, without any seperators
      @SET "V=%%s"
      @CALL :version "!V:~0,4!" "!V:~4,2!" "!V:~6,2!" "" "%%f" "-"
    )
  )
)
@ECHO/VERSION=%VERSION%
@ECHO/PRG=%PRG%
@IF "%VERSION%"=="notfound" @(
 @ECHO ** ERROR: No msys2 installation program found
 @CALL :errorlevel 64
 @GOTO :exit
)

@SET DEST=C:/msys64
@IF EXIST C:\DEV\. @SET DEST=C:/DEV/msys64

".\%PRG%" -y -o%DEST%

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

:version
@SET "X=000000000%~1"
@SET "Y=000000000%~2"
@SET "Z=000000000%~3"
@SET "P=000000000%~4"
@SET "_VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%.%P:~-8%"
@IF %VERSION%==notfound GOTO :update
@IF %_VERSION% GTR %__VERSION% GOTO :update
@GOTO :EOF

:update
@SET "__VERSION=%_VERSION%"
@SET "SEP=%~6"
@IF "%SEP%"=="" @SET SEP=.
@IF NOT "%~4"=="" @(
  @SET "VERSION=%~1%SEP%%~2%SEP%%~3%SEP%%~4"
) ELSE @(
  @IF NOT "%~3"=="" @(
    @SET "VERSION=%~1%SEP%%~2%SEP%%~3"
  ) ELSE @(
    @IF NOT "%~2"=="" @(
      @SET "VERSION=%~1%SEP%%~2"
    ) ELSE @(
      @SET "VERSION=%~1"
    )
  )
)
@SET "PRG=%~5"
@GOTO :EOF

:errorlevel
@EXIT /B %~1