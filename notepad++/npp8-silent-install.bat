@SETLOCAL
@CHCP 65001 >NUL:

@CALL "%~dp0..\bin\getfetchlocation.bat" "notepad++8"
CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit
@ECHO OFF

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @GOTO :exit
)

@IF "%1"=="uninstall" GOTO :Uninstall

@SET INSTALLER=
@SET VERSION=notfound
@FOR %%f IN ("npp.8.*.installer.x64.exe") DO @(
  FOR /F "tokens=2-4 delims=." %%i IN ("%%f") DO @CALL :version "%%i" "%%j" "%%k" "%%f"
)
@ECHO/INSTALLER=%INSTALLER%
@ECHO/VERSION=%VERSION%
@IF %VERSION%==notfound @(
  @ECHO ** ERROR: installer not found
  @CALL :errorlevel 64
  @GOTO :exit
)

@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"

"%INSTALLER%" /S /noUpdater

@GOTO :exit

@REM Uninstall (not tested yet) BEWARE all scratch files are lost !!!

@:Uninstall
@ECHO/** ERROR: NOT DOING UNINSTALL: User data are lost

@SET "KEY=HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Notepad++"
@SET UNINSTALLER=notfound
@FOR /F "usebackq tokens=2*" %%a IN (`reg query "%KEY%" /v UninstallString 2^>NUL ^| FINDSTR REG_SZ`) DO @SET "UNINSTALLER=%%~b"
@IF "%UNINSTALLER%"=="notfound" @(
  @ECHO ** ERROR: uninstaller not found ^(is Notepad++ installed?^)
  @CALL :errorlevel 64
  @GOTO :exit
)

::FOR /F "usebackq tokens=2*" %a IN (`reg query "%KEY%" /v UninstallString 2^>NUL ^| FINDSTR REG_SZ`) DO @ECHO %b

@ECHO/** WARNING not running `"%UNINSTALLER%" /S`
@CALL :errorlevel -1
:: Uncomment next line to run uninstaller
::"%UNINSTALLER%" /S

@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@type nul>nul
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

@:version
@SET "X=000000000%~1"
@SET "Y=000000000%~2"
@SET "Z=000000000%~3"
@IF "%~3"=="Installer" SET Z=00000000
@SET "__VERSION=%X:~-8%.%Y:~-8%.%Z:~-8%"
@IF %VERSION%==notfound GOTO :update
@IF %__VERSION% GTR %_VERSION% GOTO :update
@GOTO :EOF

@:update
@SET "_VERSION=%__VERSION%"
@SET "VERSION=%~1.%~2.%~3"
@SET "INSTALLER=%~4"
@GOTO :EOF

:errorlevel
@EXIT /B %~1
