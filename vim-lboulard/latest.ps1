$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+\.\d+(-\d+)?)"
$project = "lboulard/vim-win32-build"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName vim -FileSelection {
  @(
    "gvim-$version-amd64.exe"
    # "gvim-$version-amd64.zip"
  )
}
