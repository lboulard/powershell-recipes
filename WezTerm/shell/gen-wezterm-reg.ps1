# Create registry file from $LBHOME/Scoop installation variable

$registryFilePath = ".\OpenWezTermHere.reg"
$scoopInstallPath = $ENV:LBHOME + "\Scoop\apps\wezterm\current"
$lbProgramInstallPath = $ENV:LBPROGRAMS + "\Apps\Wezterm"
if (Test-Path $scoopInstallPath) {
  $installPath = $scoopInstallPath
} elseif (Test-Path $lbProgramInstallPath) {
  $installPath = $lbProgramInstallPath
} else {
  throw "WezTerm install not found"
}
$cmdPath = $installPath + "\wezterm-gui.exe"

$shellTemplate = @"
[HKEY_CURRENT_USER\Software\Classes\{0}\shell\WezTermHere]
@="Open WezTerm Here"
"Icon"="{1}"

[HKEY_CURRENT_USER\Software\Classes\{0}\shell\WezTermHere\command]
@="\"{1}\" start --domain local --attach --no-auto-connect --cwd \"%V\""
"@

$template = @"
Windows Registry Editor Version 5.00

{0}
"@

$reg = @(
 ($shellTemplate -f "Drive", ($cmdPath -replace '\\', '\\')),
 ($shellTemplate -f "directory", ($cmdPath -replace '\\', '\\')),
 ($shellTemplate -f "directory\background", ($cmdPath -replace '\\', '\\'))
) -join "`r`n`r`n"

$registryFileContent = $template -f $reg

$registryFileContent | Out-File -FilePath $registryFilePath -Encoding UTF-16LE

Write-Host "Registry file created at: $registryFilePath"
