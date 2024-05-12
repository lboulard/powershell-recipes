@SETLOCAL
IF x%GIT_SSH%==x SETX GIT_SSH "C:\Programs\OpenSSH\ssh.exe"

@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
