
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.22.10731.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.22.10731.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.22.10731.0_8wekyb3d8bbwe.msixbundle
SHA256 B2A5D96AFED0E2F187AB46C71F10006E462FA71D75E43D87DC87C7C6552E236B

Microsoft.WindowsTerminal_1.22.10731.0_x64.zip
SHA256 1D15F5ED4E81324226D24390FA3CD9F5D9C4BC6639F81992B2E38B99881F6A6B
