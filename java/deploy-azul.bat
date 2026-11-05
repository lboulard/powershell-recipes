@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
CHCP 65001 >NUL

@CALL "%~dp0..\bin\getfetchlocation.bat" "java-azul"
@CD /D "%LOCATION%"
@IF ERRORLEVEL 1 GOTO :exit

SET PWSH=PowerShell.exe
where /Q pwsh.exe
IF %ERRORLEVEL% EQU 0 (
  SET PWSH=pwsh.exe
)

IF EXIST .\config-azul.bat CALL .\config-azul.bat

IF "%INSTALL_PATH%"=="" (
  ECHO>&2.Missing INSTALL_PATH for deployments
  CALL :seterrorlevel 2
  GOTO :exit
)
IF NOT EXIST "%INSTALL_PATH%\." MD "%INSTALL_PATH%"

IF NOT DEFINED ARGSi386  SET "ARGSi386=-FromPath jre8 -JRE -OpenFX"
IF NOT DEFINED ARGSmad64 SET "ARGSamd64=-FromPath jdk8,jdk11,jdk17 -JDK -OpenFX"

ECHO ON

"%PWSH%" -NoProfile -Command^
 "& '%~dpn0.ps1' -InstallPath "%INSTALL_PATH%" %ARGSi386% -Arch x86"
@IF ERRORLEVEL 1 GOTO :exit

"%PWSH%" -NoProfile -Command^
 "& '%~dpn0.ps1' -InstallPath "%INSTALL_PATH%" %ARGSamd64% -Arch amd64"
@IF ERRORLEVEL 1 GOTO :exit

:exit
@ECHO OFF

@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 ECHO ** ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

:seterrorlevel
EXIT /B %~1
