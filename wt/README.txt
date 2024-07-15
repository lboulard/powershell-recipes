
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.20.11781.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.20.11781.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.20.11781.0_8wekyb3d8bbwe.msixbundle
SHA256 5EF95B5D0E6BD530A985E7C59E8E9CE12195D9E18C1657D2FA0BD58C102FA419

Microsoft.WindowsTerminal_1.20.11781.0_x64.zip
SHA256 B7A6046903CE33D75250DA7E40AD2929E51703AB66E9C3A0B02A839C2E868FEC
