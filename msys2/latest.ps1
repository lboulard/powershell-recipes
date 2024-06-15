$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# date YYYY-M-DD based project
$project = "msys2/msys2-installer"
$tagPattern = "^(?<tag>(?<version>\d+-\d+-\d+))$"

$installer = "msys2-x86_64-.+\.exe(\.sha256|\.sig)?"
$archiveBase = "msys2-base-x86_64-.+(\.tar\.(xz|zst)|\.sfx\.exe)(\.sha256|\.sig)?"
$packageList = "msys2-base-x86_64-.+\.packages\.txt"
$wanted = "^(${installer}|${archiveBase}|${packageList})$"

$nameMangle = {
  "msys2-${version}/${name}"
}

Import-Module lboulard-Recipes

$githubToken = Get-GitHubToken

$releaseScript = {
  param($release)
  Write-Host "Release tag: $($release.tag_name)"
}

$files = Find-GitHubReleaseFromAsset $project $tagPattern -AssetPattern $wanted -Token $githubToken -NameMangle $nameMangle -ReleaseScript $releaseScript

$headers = @{
  'Accept'               = 'application/vnd.github+json'
  "X-GitHub-Api-Version" = "2022-11-28"
}
if ($githubToken) {
  $headers['Authorization'] = 'token ' + $githubToken
}

if ($files) {
  Get-Url $files -Headers $headers
}
