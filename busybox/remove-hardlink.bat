@SETLOCAL ENABLEDELAYEDEXPANSION
@CD /D "%~dp0"

@SET "ALIAS="
@SET "ALIAS=%ALIAS% ascii"
@SET "ALIAS=%ALIAS% awk"
@SET "ALIAS=%ALIAS% base64"
@SET "ALIAS=%ALIAS% bc"
@SET "ALIAS=%ALIAS% busybox"
@SET "ALIAS=%ALIAS% bzcat"
@SET "ALIAS=%ALIAS% bzip2"
@SET "ALIAS=%ALIAS% cal"
@SET "ALIAS=%ALIAS% cat"
@SET "ALIAS=%ALIAS% diff"
@SET "ALIAS=%ALIAS% dos2unix"
@SET "ALIAS=%ALIAS% egrep"
@SET "ALIAS=%ALIAS% fgrep"
@SET "ALIAS=%ALIAS% grep"
@SET "ALIAS=%ALIAS% hd"
@SET "ALIAS=%ALIAS% head"
@SET "ALIAS=%ALIAS% hexdump"
@SET "ALIAS=%ALIAS% httpd"
@SET "ALIAS=%ALIAS% iconv"
@SET "ALIAS=%ALIAS% inotifyd"
@SET "ALIAS=%ALIAS% install"
@SET "ALIAS=%ALIAS% ls"
@SET "ALIAS=%ALIAS% mv"
@SET "ALIAS=%ALIAS% nl"
@SET "ALIAS=%ALIAS% nproc"
@SET "ALIAS=%ALIAS% patch"
@SET "ALIAS=%ALIAS% printenv"
@SET "ALIAS=%ALIAS% printf"
@SET "ALIAS=%ALIAS% rm"
@SET "ALIAS=%ALIAS% shred"
@SET "ALIAS=%ALIAS% sort"
@SET "ALIAS=%ALIAS% stat"
@SET "ALIAS=%ALIAS% tail"
@SET "ALIAS=%ALIAS% tar"
@SET "ALIAS=%ALIAS% touch"
@SET "ALIAS=%ALIAS% unix2dos"
@SET "ALIAS=%ALIAS% unzip"
@SET "ALIAS=%ALIAS% uptime"
@SET "ALIAS=%ALIAS% watch"
@SET "ALIAS=%ALIAS% wc"

@FOR %%a IN (%ALIAS%) DO @CALL :rmlink "%LBPROGRAMS%\bin\%%a.exe"
@IF ERRORLEVEL 1 @GOTO :error

@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B 0

:error
@SET ERR=%ERRORLEVEL%
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

:rmlink
@IF EXIST "%~1" ECHO. removing %~1
@IF EXIST "%~1" DEL "%~1"
@IF ERRORLEVEL 1 @GOTO :error
