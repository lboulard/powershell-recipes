CD /D "%~dp0"
@IF "%1"=="uninstall" GOTO :Uninstall
@SET NAME=
@FOR %%f IN ("go1.21.*.windows-amd64.msi") DO @SET "NAME=%%~nf"
@ECHO SET NAME=%NAME%
@IF NOT DEFINED NAME (
ECHO ** ERROR: go language installation program not found
GOTO :EOF
)
@SET LOG=%LOCALAPPDATA%\lboulard\logs\golang-install.log
@IF NOT EXIST "%LOCALAPPDATA%\lboulard" MD "%LOCALAPPDATA%\lboulard"
@IF NOT EXIST "%LOCALAPPDATA%\lboulard\logs" MD "%LOCALAPPDATA%\lboulard\logs"
msiexec /i "%NAME%.msi"^
 /QB /L*V "%LOG%"^
 /passive /norestart
@GOTO :EOF
@GOTO :EOF
@:Uninstall
msiexec /x "%NAME%.msi"