@SETLOCAL ENABLEEXTENSIONS
@CD /D "%~dp0"

@FOR /D %%i IN (LLVM-*) DO @(
 @FOR %%j IN (%%~i\*.jsonl) DO @CALL :verify "%%~i\%%~nj"
)

@IF NOT DEFINED ERR SET ERR=%ERRORLEVEL%
@TYPE NUL>NUL
@ECHO %cmdcmdline% | FIND /I %0 >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL&EXIT /B %ERR%

:verify
gh attestation verify --repo llvm/llvm-project "%~1" --bundle "%~1.jsonl"
