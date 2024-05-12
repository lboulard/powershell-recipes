@SETLOCAL ENABLEEXTENSIONS
@CD /D "%~dp0"

@SET SH=c:\msys64\usr\bin\sh.exe
@IF EXIST c:\dev\msys64\usr\bin\sh.exe @SET SH=c:\dev\msys64\usr\bin\sh.exe

:: Save modified files
%SH% -c^
 "/usr/bin/tar -cf - $(/usr/bin/pacman -Qii|/usr/bin/awk '/^MODIFIED/ {print $2}')|zstd -f -o msys64-backup.tar.zst.tmp"
@CALL :update msys64-backup.tar.zst
@IF ERRORLEVEL 1 EXIT /B %ERRORLEVEL%

:: Save list of non dependent packages
:: Restore with "pacman -S --needed - <msys64-packages.txt"
%SH% -c "/usr/bin/pacman -Qqtne >msys64-packages.txt.tmp"
@CALL :update msys64-packages.txt
@IF ERRORLEVEL 1 EXIT /B %ERRORLEVEL%

:: Save home
%SH% -l -c "tar -cf $(cygpath -u '%CD%\msys64-home.tar.zst.tmp') -I 'zstd --progress -9' --totals -C /home ."
@CALL :update msys64-home.tar.zst

:: Restore with:
:: %SH% -c "/usr/bin/pacman -S --noconfirm msys/tar msys/zstd"
:: %SH% -c "zstd -cd msys64-home.tar.zst | /usr/bin/tar xvf - -C /home"

@ENDLOCAL&EXIT /B %ERRORLEVEL%

:update
@IF NOT EXIST "%~1." (
  CALL :comp1 "%~1"
) ELSE (
  type NUL
  COMP /M "%~1.tmp" "%~1"
  IF ERRORLEVEL 2 GOTO :comp2 "%~1"
  IF ERRORLEVEL 1 GOTO :comp1 "%~1"
  CALL :comp0 "%~1"
)
@GOTO :EOF

:comp0
DEL "%~1.tmp"
@GOTO :EOF

:comp1
MOVE /Y "%~1.tmp" "%~1"
@type nul
@GOTO :EOF

:comp2
@ECHO Failed to access "%~1.tmp" or "%~1"
@EXIT /B 2
