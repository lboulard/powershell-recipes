function Get-ScriptDirectory {
    Split-Path -Parent $PSCommandPath
}

$PSCommandPath | Split-Path | Push-Location

$TD = Get-Date -Format "yyyyMMdd"

Copy-Item `
 -Path "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
 -Destination "settings-${TD}.json"
Compress-Archive `
 -Force `
 -Path $Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\* `
 -DestinationPath "roaming-${TD}.zip"

Pop-Location

# @:: Pause if not interactive
# @ECHO %cmdcmdline% | FIND /i "%~0" >NUL
# IF NOT ERRORLEVEL 1 PAUSE
