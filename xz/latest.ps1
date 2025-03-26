$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# Example: https://github.com/tukaani-project/xz/releases/download/v5.8.0/xz-5.8.0-windows.zip.sig
$tagPattern = 'v(?<version>\d+\.\d+\.\d+)'
$project = "tukaani-project/xz"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "xz-$version-windows.zip"
    "xz-$version-windows.zip.sig"
  )
} -NameMangle {
  "xz-${version}/${name}"
}
