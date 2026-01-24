
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.23.20211.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.23.20211.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.23.20211.0_8wekyb3d8bbwe.msixbundle
SHA256 A5B4B6BD5375227945396529D0023167942B5ED0B9E9516004B30E3648C21E52

Microsoft.WindowsTerminal_1.23.20211.0_x64.zip
SHA256 83EFE4572599479E9DF38317A7BE7FEB1E2E86430432FC8D84F76DF19DE6CD11
