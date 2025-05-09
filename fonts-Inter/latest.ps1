$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+(\.\d+)+)"
$project = "rsms/inter"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName fonts-inter -FileSelection {
  @(
    "Inter-${version}.zip"
  )
}
