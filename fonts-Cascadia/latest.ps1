$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "(?<tag>v(?<version>\d+(\.\d+)+))$"
$project = "microsoft/cascadia-code"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName fonts-cascadia -FileSelection {
  @(
    "CascadiaCode-${version}.zip"
  )
}
