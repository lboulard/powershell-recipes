@SETLOCAL
@CHCP 65001
@CD /D "%~dp0"

@SET PYVER=
@FOR %%f IN ("python-3.*-amd64.exe") DO @SET "PYVER=%%~f"
@ECHO SET PYVER=%PYVER%
@IF NOT DEFINED PYVER (
  @ECHO>&2 ** ERROR: No Python installation program found
  @GOTO :exit
)

cosign verify-blob "%PYVER%"^
 --certificate "%PYVER%.crt"^
 --signature "%PYVER%.sig"^
 --cert-identity hugo@python.org^
 --cert-oidc-issuer "https://github.com/login/oauth"

:exit
@:: Pause if not interactive
@SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FINDSTR /L /I "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%
