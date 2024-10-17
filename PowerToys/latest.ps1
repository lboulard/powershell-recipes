$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+\.\d+)"
$project = "microsoft/PowerToys"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "PowerToysUserSetup-$version-x64.exe"
    "PowerToysSetup-$version-x64.exe"
  ) | ForEach-Object { "$($_)#$version/$($_)" }
}
