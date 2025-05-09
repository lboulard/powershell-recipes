# PowerShell 5 and 7
# find Ruby 3.3 installer using GitHub API only walking releases

$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$branch = "3.3"

$tagPattern = "RubyInstaller-(?<version>$([regex]::escape($branch))\.\d+)(\-\d+)?$"
$wanted = "^rubyinstaller-$([regex]::escape($branch))\.\d+.+?-x64\.(exe|7z)(\.asc)?$"
$project = "oneclick/rubyinstaller2"

$nameMangle = {
  # manipulate $name, $version and $tag are accessible from tag pattern parsing
  Write-Verbose "`$name='$name', `$version='$version'"
  "${branch}/${name}"
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

Get-Url $files -Headers $headers -ProjectName ruby3.3
