$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# https://github.com/mcmilk/7-Zip-zstd/releases/tag/v22.01-v1.5.5-R3

$project = "mcmilk/7-Zip-zstd"
$tagPattern = "(?<tag>v(?<version>\d+\.\d+(\.\d+)?)-(?<subversion>v\d+\.\d+(\.\d+)?)(-R\d)?)"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName '7zip-zstd' -FileSelection {
  @(
    "7z${version}-zstd-x64.exe"
    "Codecs-x64.7z"
  )
} -NameMangle {
  $name = $name -replace "^(Codecs-.+)\.(.+)$", "`$1_${subversion}.`$2"
  "7z${tag}/${name}"
}
