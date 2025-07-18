
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.22.11751.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.22.11751.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.22.11751.0_8wekyb3d8bbwe.msixbundle
SHA256 DCEE05C52D5732D0459614EAA449AA054A3EA9D9D148863E7DA3F0A02CCC8022

Microsoft.WindowsTerminal_1.22.11751.0_x64.zip
SHA256 F8C4AA0802B0A8C2FA2ACD260FBC437CEAE05BB9BE4EFC0D1DA4D013B74B35C9
