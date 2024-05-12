@SETLOCAL
@CD /D "%~dp0"

:: check if admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1

@IF %ERRORLEVEL% NEQ 0 (
  @SET _ELEV=1
  @Powershell.exe "start cmd.exe -arg '/c """%~0"""' -verb runas" && GOTO :exit
  @ECHO This script needs admin rights.
  @ECHO To do so, right click on this script and select 'Run as administrator'.
  @GOTO :exit
)


@SET "PLUGINS=%PROGRAMFILES%\Notepad++\plugins"

@CALL :mkdir "%PLUGINS%"
@CALL :install "%PLUGINS%\DSpellCheck" DSpellCheck.dll
@CALL :install "%PLUGINS%\NppExec" NppExec\NppExec.dll
@CALL :install "%PLUGINS%\doc" doc\

@IF ERRORLEVEL 1 @ECHO ** FAILURE detected


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF DEFINED _ELEV GOTO :_elev
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@:_elev
@ENDLOCAL&EXIT /B %ERR%

:install
@SETLOCAL
@SET "DEST=%~1"
@CALL :mkdir "%DEST%"
@FOR %%F IN (%2 %3 %4 %5 %6 %7 %8 %9) DO @(
CALL :copy "x86\%%~F" "%DEST%\"
IF ERRORLEVEL 1 @GOTO :return
)
:return
@ENDLOCAL&GOTO :EOF

:copy
xcopy /Z /H /J /Y /V /S "%~1" "%~2"
@GOTO :EOF

:mkdir
@IF NOT EXIST "%~1\." MD "%~1"
@GOTO :EOF
