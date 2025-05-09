
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.22.11141.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.22.11141.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.22.11141.0_8wekyb3d8bbwe.msixbundle
SHA256 81F1E3EBFEA991875C6515173590CAC64B40EB628DBFA4EA8B969010AA7646C0

Microsoft.WindowsTerminal_1.22.11141.0_x64.zip
SHA256 8531822D3BF87625874DBFFEE632260D2390CA3B8CF67B0D2176957376C794CF
