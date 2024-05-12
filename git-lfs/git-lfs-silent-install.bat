CD /D "%~dp0"
@IF "%1"=="uninstall" GOTO :Uninstall
@SET PRG=
@FOR %%f IN ("git-lfs-windows-.exe") DO @SET "PRG=%%f"
@ECHO SET PRG=%PRG%
@IF NOT DEFINED PRG (
ECHO ** ERROR: No installation program found
GOTO :EOF
)
START /WAIT %PRG% ^
 /SP- ^
 /VERYSILENT ^
 /NORESTART ^
 /FORCECLOSEAPPLICATIONS ^
 /LOADINF=git-lfs-silent-install.inf ^
 /LOG=git-lfs-install.log
@GOTO :EOF
@:Uninstall
"%PROGRAMFILES%\Git LFS\unins000.exe" ^
 /SP- ^
 /VERYSILENT ^
 /SUPPRESSMSGBOXES ^
 /NORESTART ^
 /FORCECLOSEAPPLICATIONS