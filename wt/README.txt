
Source: <https://docs.microsoft.com/en-us/powershell/module/appx/?view=win10-ps>
        <https://github.com/microsoft/terminal/releases>

Run inside a vanilly CMD.EXE/Powershell instance.

Install:
  Powershell -noprofile -Command Add-AppxPackage -Path "Microsoft.WindowsTerminal_1.21.3231.0_8wekyb3d8bbwe.msixbundle"

Remove:
  Powershell -noprofile -Command Remove-AppxPackage -Package Microsoft.WindowsTerminal_1.21.3231.0_8wekyb3d8bbwe

Information:
  Powershell -noprofile -Command Get-AppPackage -name "Microsoft.WindowsTerminal"

Microsoft.WindowsTerminal_1.21.3231.0_8wekyb3d8bbwe.msixbundle
SHA256 C80BC461B22A17650A58BC5CAD743E1AD97E0A4EA92CCDCB514EE7D7AA134243

Microsoft.WindowsTerminal_1.21.3231.0_x64.zip
SHA256 8FB268B93C9B99D6CF553709C2C58BF1B2FF4B364199152E09221DFB2A44BBF5
