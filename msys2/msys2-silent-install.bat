@SETLOCAL EnableExtensions EnableDelayedExpansion
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

@SET VERSION=notfound
@SET PRG=
@FOR /D %%d IN ("msys2-*") DO @(
  @FOR %%f IN ("%%d\msys2-x86_64-*.exe") DO @(
    @FOR /F "tokens=3 delims=-" %%s IN ("%%~nf") DO @(
      @REM date is YYYYMMDD, without any seperators
      @SET "V=%%s"
      @CALL :version "!V:~0,4!" "!V:~4,2!" "!V:~6,2!" "" "%%f" "-"
    )
  )
)
@ECHO/VERSION=%VERSION%
@ECHO/PRG=%PRG%
@IF "%VERSION%"=="notfound" @(
 @ECHO ** ERROR: No pandoc installation program found
 @CALL :errorlevel 64
 @GOTO :exit
)

@SET DEST=C:/msys64
@IF EXIST C:\DEV\. @SET DEST=C:/DEV/msys64

@IF "%1"=="uninstall" @GOTO :uninstall

".\%PRG%" in --confirm-command --accept-messages --root %DEST%

:exit
:: Pause if not interactive
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:uninstall
@%DEST:/=\%\uninstall.exe pr --confirm-command
@GOTO :EOF

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
