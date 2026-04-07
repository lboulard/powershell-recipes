
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.24.10921.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.24.10921.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.24.10921.0_8wekyb3d8bbwe.msixbundle
SHA256 AC602407A7853E4AD4AAFA220FA480E74CCD3F08A5D403735C632C8EC5063552

Microsoft.WindowsTerminal_1.24.10921.0_x64.zip
SHA256 4F64736DA2F075A517E0F40ECAC2A8ACC9CD22076E6A7EDDF84A86A3917B725E
