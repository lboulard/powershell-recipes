
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.24.11321.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.24.11321.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.24.11321.0_8wekyb3d8bbwe.msixbundle
SHA256 8C162040B3E96C6DBD558FB991E79BC2ADFF7281EF431ED694554AC6FBE50887

Microsoft.WindowsTerminal_1.24.11321.0_x64.zip
SHA256 7CAEF554147E5498ED1BECDCA73CDEDB79FBC81F89032E46AE9B095C53433812
