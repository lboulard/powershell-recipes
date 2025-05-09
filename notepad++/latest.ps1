$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "(?<tag>v(?<version>\d+\.\d+(?:\.\d+)?))$"
$project = "notepad-plus-plus/notepad-plus-plus"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName notepad++8 -FileSelection {
  @(
    "npp.$version.Installer.exe",
    "npp.$version.Installer.exe.sig",
    "npp.$version.Installer.x64.exe",
    "npp.$version.Installer.x64.exe.sig"
  )
}
