## Scripts and extras for Windows

Purposes:

- Fetch latest version of software using PowerShell (via CMD.EXE/BAT launchers)
- Custom installation for a few software
- Silent installation for a few software
- Registry files to restore defaults install parameters for Vim and MSYS2
- Registry files to configure windows behaviors

### Usages

Running scripts requires installation of PowerShell modules inside `modules`
folder.

### Install repository PowerShell modules

You can copy `modules` to `Documents\WindowsPowerShell\Modules` of user.

Or modify environment variable `PSModulePath` by adding `modules` path of this
repository.

If variable is not defined for user, a quick solution is to use `SETX` inside
a CMD prompt as user.

```dosbatch
REM I suppose you are in repository root
SETX PSModulePath ^%PSModulePath^%;"%CD%\modules"
```
