$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

#  https://github.com/git-for-windows/git/releases/tag/v2.45.0.windows.1
$tagPattern = "v(?<version>\d+\.\d+(\.\d+)+)\.windows\.(?<build>\d+)"
$project = "git-for-windows/git"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  if ([int]$build -gt 1) {
    $build = ".$build"
  } else {
    $build = ""
  }
  @(
    "Git-$version$build-64-bit.exe"
  )
}
