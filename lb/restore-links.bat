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


@CALL :symlink ".\bin\z.cmd" "..\..\Scoop\apps\z.lua\current\z.cmd"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :symlink  ".\bin\z.lua" "..\..\Scoop\apps\z.lua\current\z.lua"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :symlink ".\clink_modules\z.cmd" "..\..\Scoop\apps\z.lua\current\z.cmd"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :symlink ".\clink_modules\z.lua" "..\..\Scoop\apps\z.lua\current\z.lua"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :hardlink ".\bin\uncrustify.exe" "..\Scoop\apps\uncrustify\current\bin\uncrustify.exe"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchDir "clink.*" . 2 4
@SET "CLINK=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "clink" "%CLINK%"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchMatchDir "Apps\chaiNNer-windows-x64-*" - 4 . 1 3
@SET "CHAINNER=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\chaiNNER" "%CHAINNER%"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchMatchDir "Apps\ipe-*" - 2 . 1 3
@SET "IPE=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\ipe" "%IPE%"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchMatchDir "Apps\octave-*" - 2 . 1 3
@SET "OCTAVE=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\octave" "%OCTAVE%"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchMatchDir "Apps\tcltk86-*" - 2 . 1 4
@SET "TCLTK=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\tcl" "%TCLTK%4"
@IF ERRORLEVEL 1 GOTO :exit

@CALL :matchDir "Apps\groff\dist-*" - 2 4
@SET "GROFF=%LATEST%"
@IF ERRORLEVEL 1 GOTO :exit
@CALL :junction "Apps\groff\dist" "%GROFF%"
@IF ERRORLEVEL 1 GOTO :exit


@:: Pause if not interactive
@:exit
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
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
  @CALL :errorlevel 128
  @GOTO :EOF
)
MKLINK /J "%~dpf1" "%~dpf2"
@IF ERRORLEVEL 1 @EXIT /B %ERRORLEVEL%
@GOTO :EOF

REM Find latest version for a folder
REM Version can be extracted with one separator
REM Maximum version string after split is 4 elements
REM Output:
REM   - VERSION: version string, always split by dots
REM   - LATEST: pathname of latest version

:matchDir
@SET VERSION=notfound
@SET LATEST=
@SETLOCAL EnableExtensions EnableDelayedExpansion
@SET /A "N=1+%~4-%~3"
@FOR /D %%p IN ("%~1") DO @(
  @CALL :_match%N% "%~2" "%~3" "%~4" "%%p"
)
@GOTO :_endMatch

REM Find latest version for a folder
REM Version need two passes to be extracted
REM One pass for version string isolation, another pass to split version string
REM Maximum version string after split is 4 elements
REM Output:
REM   - VERSION: version string, always split by dots
REM   - LATEST: pathname of latest version

:matchMatchDir
@SET VERSION=notfound
@SET LATEST=
@SETLOCAL EnableExtensions EnableDelayedExpansion
@SET /A "N=1+%~6-%~5"
@FOR /D %%p IN ("%~1") DO @(
  @FOR /F "delims=%~2 tokens=%~3" %%s IN ("%%~p") DO @(
    @CALL :_match%N% "%~4" "%~5" "%~6" "%%s"
  )
)
@GOTO :_endMatch

:_endMatch
@ENDLOCAL & SET "LATEST=%LATEST%" & SET "VERSION=%VERSION%"
@IF %VERSION%==notfound @(
  @ECHO ** ERROR, %~1 not found
  @CALL :errorlevel 64
)
@GOTO :EOF

:_match2
@FOR /F "delims=%~1 tokens=%~2-%~3" %%i IN ("%~4") DO @CALL :version "%%i" "%%j" "" "" "%%p"
@GOTO :EOF

:_match3
@FOR /F "delims=%~1 tokens=%~2-%~3" %%i IN ("%~4") DO @CALL :version "%%i" "%%j" "%%k" "" "%%p"
@GOTO :EOF

:_match4
@FOR /F "delims=%~1 tokens=%~2-%~3" %%i IN ("%~4") DO @CALL :version "%%i" "%%j" "%%k" "%%l" "%%p"
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
@IF NOT "%~4"=="" @(
  @SET "VERSION=%~1.%~2.%~3.%~4"
) ELSE @(
  @IF NOT "%~3"=="" @(
    @SET "VERSION=%~1.%~2.%~3"
  ) ELSE @(
    @IF NOT "%~2"=="" @(
      @SET "VERSION=%~1.%~2"
    ) ELSE @(
      @SET "VERSION=%~1"
    )
  )
)
@SET "LATEST=%~5"
@GOTO :EOF

:errorlevel
@EXIT /B %~1
