## Instructions for ZIP

- Download OpenSSH-WIN64.zip from https://github.com/PowerShell/Win32-OpenSSH/releases
- Extract ZIP file into same folder
- Run `install-sshd.ps1` from this place (not the one from ZIP file). Only SSH agent will be installed, not the SSH server.
- (Optional) run windows-git-openssh.bat to have Git using system SSH

## Install from MSI distribution

Reference: <https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH-Using-MSI>

### Install OpenSSH Client

Install client only : `msiexec /i OpenSSH-Win64.msi ADDLOCAL=Client`

### Add OpenSSH to System `PATH`

Open PowerShell as Administrator to install OpenSSH executables path to System `PATH`:

```ps1
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::Machine) + ';' + ${Env:ProgramFiles} + '\OpenSSH', [System.EnvironmentVariableTarget]::Machine)
```

### Verify OpenSSH Install

Check the status of the SSH Service. In PowerShell, run:

```ps1
Get-Service -Name ssh*
```
