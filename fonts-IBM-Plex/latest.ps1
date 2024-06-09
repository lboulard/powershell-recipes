# PowerShell 5 and 7
# find Ruby 2.7 installer using GitHub API only walking releases

$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+(\.\d+)+)$"
$project = "IBM/plex"
$wanted = "TrueType\.Zip" # "#IBM-Plex-${version}.zip"

$nameMangle = {
  # manipulate $name, $version and $tag are accessible from tag pattern parsing
  Write-Verbose "`$name='$name', `$version='$version'"
  $name -replace "^.*(\.[^\.]+)$", "IBM-plex-${version}`$1"
}

Import-Module lboulard-Recipes

# filenames are not enough to find release files
# use GitHub API

$githubToken = Get-GitHubToken
if (-not $githubToken) {
  Write-Warning "GitHub token missing, failure or long delay can be expected"
}

# parse all request until we find a release that match wanted files

$files = Find-GitHubReleaseFromAsset $project $tagPattern $wanted -Token $githubToken -ReleaseScript {
  param($release)
  Write-Host "Release tag: $($release.tag_name)"
} -NameMangle $nameMangle

if (-not $files) {
  Write-Error "no files found"
  exit 1
}

$headers = @{
  'Accept'        = 'application/octet-stream'
  'Authorization' = 'token ' + $githubToken
}

Get-Url $files -Headers $headers
