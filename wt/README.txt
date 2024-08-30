
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.21.2361.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.21.2361.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.21.2361.0_8wekyb3d8bbwe.msixbundle
SHA256 19CBE2E77CC814A5AB68E346B0D3D928F44F1EC5A78FB9B53A793D46B1CE3D27

Microsoft.WindowsTerminal_1.21.2361.0_x64.zip
SHA256 AC2D324EA1AF30CB97D6FB40EF83EBC82E92FBBB516CD274E4ED9CB8FD22FE4E
