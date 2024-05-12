
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.20.11271.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.20.11271_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.20.11271.0_8wekyb3d8bbwe.msixbundle
SHA256 67216C17DDAB0BAF93E1BE16A851C8D904351DA497FB3C1CD2B71DF849B37931

Microsoft.WindowsTerminal_1.20.11271.0_x64.zip
SHA256 F480F65A7874E7055C51EC67E0E4F98011A4EF63DD43C6B882458DAE36A83286
