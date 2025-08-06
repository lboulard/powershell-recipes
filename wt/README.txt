
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.22.12111.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.22.12111.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.22.12111.0_8wekyb3d8bbwe.msixbundle
SHA256 A95C7018EDA467AB8747B4F1AABE789A0270332FE5802BB548D65879D333B006

Microsoft.WindowsTerminal_1.22.12111.0_x64.zip
SHA256 551D8A7AE129DAE63453B687361A75D925C6B2941342C09AEA94BC16F95CC288
