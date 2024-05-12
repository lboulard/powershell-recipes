@SETLOCAL
@CD /D "%~dp0"
@SET PYVER=
@FOR %%f IN ("python-3.*-amd64.exe") DO @SET "PYVER=%%~nf"
@ECHO SET PYVER=%PYVER%
@IF NOT DEFINED PYVER (
ECHO ** ERROR: No Python installation program found
GOTO :EOF
)
".\%PYVER%.exe" /passive /layout "%PYVER%"