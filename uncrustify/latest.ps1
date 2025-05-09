$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "uncrustify/uncrustify"
$tagPattern = "uncrustify-(?<version>\d+\.\d+\.\d+)"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName uncrustify -FileSelection {
  # uncrustify-0.79.0_f-win64.zip
  @(
    "uncrustify-${version}_f-win64.zip"
    # "uncrustify-${version}_f-win32.zip"
  )
}
