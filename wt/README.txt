
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.23.12371.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.23.12371.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.23.12371.0_8wekyb3d8bbwe.msixbundle
SHA256 394AA631EC9B0EA1C5B24399B37408C2F0B3459CE029410A5B76A4E2DF791355

Microsoft.WindowsTerminal_1.23.12371.0_x64.zip
SHA256 EDAD49378E33812947A3FA3AA6CA165F90F1A55F9DA04F098773150B115F8596
