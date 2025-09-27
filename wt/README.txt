
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.23.12681.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.23.12681.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.23.12681.0_8wekyb3d8bbwe.msixbundle
SHA256 AB1FD95A01A3B9236EB7088FFA8B843159E7FA825B255D0E0E031F8183F02CBE

Microsoft.WindowsTerminal_1.23.12681.0_x64.zip
SHA256 54829FE9EC07CA35E40B80A1AEFDA582D1A16619A4197CAD13142D656075BB2B
