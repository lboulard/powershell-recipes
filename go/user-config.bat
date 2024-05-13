@IF "%GOPATH%"=="" SET "GOPATH=%USERPROFILE%\go"

@ECHO SET GOPATH=%GOPATH%
@CALL :absolute ROOT "%LBHOME%"
SET "APPS=%ROOT%\Apps"
SET "GOSDK=%ROOT%\Apps\sdk\"

@GOTO :EOF

@:absolute
SET "%~1=%~dpf2"
@GOTO :EOF
