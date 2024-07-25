$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# zstd-v1.5.6-win64.zip

$tagPattern = "(?<tag>v(?<version>\d+\.\d+(\.\d+)+))"
$project = "facebook/zstd"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "zstd-${tag}-win64.zip"
    "zstd-${version}.tar.gz"
    "zstd-${version}.tar.gz.sha256"
    "zstd-${version}.tar.gz.sig"
  )
} -NameMangle {
  "zstd-${version}/${name}"
}
