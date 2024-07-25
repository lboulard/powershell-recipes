$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "lz4/lz4"
$tagPattern = "/(?<tag>v(?<version>\d+\.\d+(\.\d+){0,2}))$"
$wanted = @(
  "lz4_win(32|64)_v(\d+(_\d+)+)\.zip"
  "lz4-${version}"
) -join '|'

Import-Module lboulard-Recipes

$lastVersionUrl = Get-GitHubLatestReleaseUrl $project

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  throw "no release found for ${project}"
}

if ($lastVersionURL -match $tagPattern) {
  $tag = $Matches.tag
  $version = $Matches.version
} else {
  throw "no tag match at ${lastVersionUrl}"
}

# filenames are not enough to find release files
# use GitHub API

$githubToken = Get-GitHubToken

$files = Find-GitHubAssets $project $tag $version -AssetPattern $wanted -Token $githubToken -NameMangle {
  "lz4-${version}/${name}"
}

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
