
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.20.11381.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.20.11381_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.20.11381.0_8wekyb3d8bbwe.msixbundle
SHA256 D71A4AA3751CC636EBD2283B2ED90E7A92160F5780BDD0B0EEEF3F5E4A4A6C04

Microsoft.WindowsTerminal_1.20.11381.0_x64.zip
SHA256 B417393110F805835CEAF2EAC56A6274762CEBACEFEABFD915C51441042FB59F
