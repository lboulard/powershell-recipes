@SETLOCAL ENABLEEXTENSIONS
@SET "PROJECT=%~1"

@SET LOCATION=
@FOR /F "usebackq tokens=*" %%i IN (`PowerShell -NoProfile -Command "(Get-RecipesConfig).GetFetchLocation('%PROJECT%')"`) DO @SET "LOCATION=%%~i"
@IF NOT DEFINED LOCATION SET LOCATION=.

@ENDLOCAL&SET "LOCATION=%LOCATION:/=\%"
