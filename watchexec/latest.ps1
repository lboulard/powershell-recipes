$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "watchexec/watchexec"
$tagPattern = "v(?<version>\d+\.\d+\.\d+)"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
  "watchexec-$version-x86_64-pc-windows-msvc.zip"
  "watchexec-$version-x86_64-pc-windows-msvc.zip.sha256"
  "watchexec-$version-x86_64-pc-windows-msvc.zip.b3"
  ) | ForEach-Object { "$($_)#_broken_$($_)" }
}

$goodVersion = "2.0.0"
Write-Warning "`n::: Also using v$goodVersion, because v2.1.x builds broken on windows`n"
$files = @(
  "watchexec-$goodVersion-x86_64-pc-windows-msvc.zip"
  "watchexec-$goodVersion-x86_64-pc-windows-msvc.zip.sha256"
  "watchexec-$goodVersion-x86_64-pc-windows-msvc.zip.b3"
) | ForEach-Object { "https://github.com/$project/releases/download/v$goodVersion/$_" }

Get-Url $files
