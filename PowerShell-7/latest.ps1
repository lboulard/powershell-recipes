$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "PowerShell/PowerShell"
$tagPattern = "v(?<version>\d+\.\d+\.\d+)"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "PowerShell-$version-win-x64.msi"
    "PowerShell-$version-win-x64.zip"
    # "PowerShell-$version-win.msixbundle"
  )
}
