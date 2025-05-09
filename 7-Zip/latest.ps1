$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "ip7z/7zip"
$tagPattern = "(?<version>\d+\.\d+(\.\d+)?)"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName '7zip' -FileSelection {
  $release = $version -replace '\.', ''
  @(
    "7z${release}-x64.exe"
    "7z${release}-x64.msi"
    "7z${release}-extra.7z"
    "7z${release}-src.7z"
    "7zr.exe"
  )
} -NameMangle {
  "7z${version}/${name}"
}
