# Create registry file from $LBHOME/Scoop installation variable

$registryFilePath = ".\OpenWezTermHere.reg"
$scoopRoot = $ENV:LBHOME + "\Scoop"

$shellTemplate = @"
[HKEY_CLASSES_ROOT\{0}\shell\WezTermHere]
@="Open WezTerm Here"
"Icon"="{1}"

[HKEY_CLASSES_ROOT\{0}\shell\WezTermHere\command]
@="\"{1}\" start --domain local --attach --no-auto-connect --cwd \"%V\""
"@

$template = @"
Windows Registry Editor Version 5.00

{0}
"@

$cmdPath = $scoopRoot + "\apps\wezterm\current\wezterm-gui.exe"

$reg = @(
 ($shellTemplate -f "Drive", ($cmdPath -replace '\\', '\\')),
 ($shellTemplate -f "directory", ($cmdPath -replace '\\', '\\')),
 ($shellTemplate -f "directory\background", ($cmdPath -replace '\\', '\\'))
) -join "`r`n`r`n"

$registryFileContent = $template -f $reg

$registryFileContent | Out-File -FilePath $registryFilePath -Encoding UTF-16LE

Write-Host "Registry file created at: $registryFilePath"
