@SETLOCAL
@CHCP 65001 >NUL:
@CD /D "%~dp0"
@IF ERRORLEVEL 1 GOTO :exit

:: check if not admin
@fsutil dirty query %SYSTEMDRIVE% >nul 2>&1
@IF %ERRORLEVEL% EQU 0 (
  @ECHO This script shall run as current user.
  @CALL :errorlevel 128
  @GOTO :exit
)


@PATH C:\msys64\mingw64\bin;%PATH%
@IF NOT EXIST out\. @MD out

gcc -Wall -O3 -DWINDOWS -DWIN32 -D_WIN32 -DUNICODE -D_UNICODE^
 -m64 -oout/aspell.exe aspell.c^
 -lShlwapi
@IF ERRORLEVEL 1 GOTO :exit

strip --strip-unneeded --keep-symbol=main out/aspell.exe
@IF ERRORLEVEL 1 GOTO :exit

COPY /Y "out\aspell.exe" "%LBHOME%\Programs\bin\aspell.exe"


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@IF ERRORLEVEL 1 @ECHO Failure ERRORLEVEL=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR

:errorlevel
@EXIT /B %~1
