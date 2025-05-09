$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+(\.\d+)+)"
$project = "microsoft/terminal"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName microsoft-terminal -FileSelection {
  @(
    "Microsoft.WindowsTerminal_$($version)_8wekyb3d8bbwe.msixbundle"
    "Microsoft.WindowsTerminal_$($version)_x64.zip"
  )
}
