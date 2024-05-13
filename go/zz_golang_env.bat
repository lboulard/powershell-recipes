@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 @GOTO :exit

@IF "%LBHOME%"=="" @(
  @ECHO/**ERROR Missing LBHOME environment variable
  @SET ERRORLEVEL=64
  @GOTO :exit
)

@CALL "%~dp0user-config.bat"

@IF NOT EXIST "%ROOT%\go\."            @MD "%ROOT%\go

@IF NOT EXIST "%APPS%\."          @MD "%APPS%"

@IF NOT EXIST "%ROOT%\temp\."          @MD "%ROOT%\temp"
@IF NOT EXIST "%ROOT%\temp\go-cache\." @MD "%ROOT%\temp\go-cache"
@IF NOT EXIST "%ROOT%\temp\go-env\."   @MD "%ROOT%\temp\go-env"

@IF ERRORLEVEL 1 @GOTO :exit

SETX GOPATH  "%ROOT%\go"
SETX GOCACHE "%ROOT%\temp\go-cache"
SETX GOENV   "%ROOT%\temp\go-env"

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@SET ERRORLEVEL=0
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
