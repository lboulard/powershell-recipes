
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.21.2911.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.21.2911.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.21.2911.0_8wekyb3d8bbwe.msixbundle
SHA256 345F31DCE7FE9912C7A980CA70D16BEFBF08B50A53243F0272D9084526D03DB8

Microsoft.WindowsTerminal_1.21.2911.0_x64.zip
SHA256 513AE47B4352FD0B28FEFF3D159A195CC620F8AA692EC4D06053276FDD654B28
