0<0# : ^
"""
:: Keep a python script inside a bat file
:: Source https://stackoverflow.com/a/41651933
@SETLOCAL
@py -3.12 -x -B "%~f0" %*
@SET ERR=%ERRORLEVEL%
@:: Pause if not interactive
@ECHO %cmdcmdline% | FIND /i "%~0" >NUL
@IF NOT ERRORLEVEL 1 PAUSE
@ENDLOCAL & EXIT /B %ERR%
"""

from _iosevka import clean_up

clean_up()

# Local Variables:
# mode: python
# coding: utf-8-dos
# End:
# vim: set ff=dos ft=python:
