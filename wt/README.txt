
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.21.2701.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.21.2701.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.21.2701.0_8wekyb3d8bbwe.msixbundle
SHA256 ED7538F84002AE0C9C2B8D201FE4DE0CD6C3BAC56BF4D6CA9301B75DC4450A0F

Microsoft.WindowsTerminal_1.21.2701.0_x64.zip
SHA256 2F712872ED7F552763F3776EA7A823C9E7413CFD5EC65B88E95162E93ACEF899
