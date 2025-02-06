
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.22.10352.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.22.10352.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.22.10352.0_8wekyb3d8bbwe.msixbundle
SHA256 FA08F1E5C41F7003BBE659444C6FE5E3F59F77730AB482DB44DEA8087C999225

Microsoft.WindowsTerminal_1.22.10352.0_x64.zip
SHA256 C2CF549A567F60DAF291DC87D06F69E74935426E96A5ED0F04845D8ABE5504DD
