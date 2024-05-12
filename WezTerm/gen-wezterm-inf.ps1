# Create registry file from $LBHOME/Scoop installation variable

$destFile = ".\OpenWezTermHere.inf"
$scoopRoot = $ENV:LBHOME + "\Scoop"

$cmdPath = $scoopRoot + "\apps\wezterm\current\wezterm-gui.exe"
$cmd = "`"`"{0}`"`"  start --domain local --attach --no-auto-connect --cwd `"`"%V`"`"" -f $cmdPath

# args <display name>, <short name for inf>, <command>
$infTemplate = @"
;
; Open {0} Here
;

[version]
signature="`$CHICAGO`$"

[{1}HereInstall]
CopyFiles = {1}Here.Files.Inf
AddReg    = {1}Here.Reg

[DefaultInstall]
CopyFiles = {1}Here.Files.Inf
AddReg    = {1}Here.Reg

[DefaultUnInstall]
DelFiles  = {1}Here.Files.Inf
DelReg    = {1}Here.Reg

[SourceDisksNames]
55="Open {0} Here","",1

[SourceDisksFiles]
{1}Here.INF=55

[DestinationDirs]
{1}Here.Files.Inf = 17

[{1}Here.Files.Inf]
Open{1}Here.INF

[{1}Here.Reg]
HKLM,%UWTHERE%
HKLM,%UWTHERE%,DisplayName,,"%{0}Name%"
HKLM,%UWTHERE%,UninstallString,,"rundll32.exe syssetup.dll,SetupInfObjectInstallAction DefaultUninstall 132 %17%\Open{1}Here.inf"
HKCR,Directory\shell\{1}Here,,,"%{0}Accel%"
HKCR,Directory\shell\{1}Here,Icon,,"{2}"
HKCR,Directory\shell\{1}Here\command,,,"{3}"
HKCR,Drive\shell\{1}Here,,,"%{0}Accel%"
HKCR,Drive\shell\{1}Here,Icon,,"{2}"
HKCR,Drive\shell\{1}Here\command,,,"{3}"
HKCR,Directory\background\shell\{1}Here,,,"%{0}Accel%"
HKCR,Directory\background\shell\{1}Here,Icon,,"{2}"
HKCR,Directory\background\shell\{1}Here\command,,,"{3}"

[Strings]
{1}Name="Open {0} Here"
{1}Accel="Open {0} Here"
UWTHERE="Software\Microsoft\Windows\CurrentVersion\Uninstall\{1}Here"
"@

$fileContent = $infTemplate -f "WezTerm", "WezTerm", $cmdPath, $cmd

$fileContent | Out-File -FilePath $destFile -Encoding ASCII

Write-Host "Registry file created at: $destFile"

