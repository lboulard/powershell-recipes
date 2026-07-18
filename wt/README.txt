
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.24.11911.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.24.11911.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.24.11911.0_8wekyb3d8bbwe.msixbundle
SHA256 54EF0C69A912DE511475DF02E57E5193E69193A4CF95A19D508D2705FD602E42

Microsoft.WindowsTerminal_1.24.11911.0_x64.zip
SHA256 7691EFEB71C8DD0B95536C84E366FA4CF809A42C534912F9CEFA1056534383BD
