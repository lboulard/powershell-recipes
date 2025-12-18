
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.23.13503.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.23.13503.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.23.13503.0_8wekyb3d8bbwe.msixbundle
SHA256 11C4F64907AC16FDA90C9BCAE9B8E7584866F4CAB0A64C163C5236365BE34E72

Microsoft.WindowsTerminal_1.23.13503.0_x64.zip
SHA256 920B92D1CDDC3A02FC6BA720B1F270CFFAE18EB114016C331835834917553C63
