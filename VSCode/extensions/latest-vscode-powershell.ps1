$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+(\.\d+)+)(?:-preview)?"
$project = "PowerShell/vscode-powershell"

Import-Module lboulard-Recipes

# filenames are not enough to find release files
# use GitHub API

$githubToken = Get-GitHubToken
if (-not $githubToken) {
  Write-Warning "GitHub token missing, failure or long delay can be expected"
}

$files = Find-GitHubReleaseFromAsset $project `
  -TagPattern $tagPattern -AssetPattern "powershell-.*\.vsix" `
  -Token $githubToken -PreRelease $true

if ($files) {
  Get-Url $files -ProjectName vscode-extensions
} else {
  Write-Host "no files found"
}
