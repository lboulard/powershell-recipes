
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.23.12811.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.23.12811.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.23.12811.0_8wekyb3d8bbwe.msixbundle
SHA256 4D9C831600A16F4F85C08098DC20B927716F78B01ADA01A5B0B1A9E7560F09CF

Microsoft.WindowsTerminal_1.23.12811.0_x64.zip
SHA256 686A2C37E80481ED101FBFF6289A302F93627009DD66C3A9FB6AD86E94C5B7F8
