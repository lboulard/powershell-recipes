$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "/(?<tag>(?<version>\d+\.\d+(\.\d+){0,2}))$"
$project = "jgm/pandoc"

$pandoc = "pandoc-(\d+\.\d+(?:\.\d+(?:\.\d+)?)?)"
$wanted_x86 = "${pandoc}-windows-i386\.(?:exe|msi|zip)"
$wanted_x64 = "${pandoc}-windows-x86_64\.(?:exe|msi|zip)"
$wanted_deb = "${pandoc}-(?:\d+)-(amd64|arm64)\.deb"
$wanted_linux = "${pandoc}-linux-(?:amd64|arm64)\.(?:tar\..+)"
$wanted = "^(${wanted_x64})|(${wanted_x86})|($wanted_deb)|($wanted_linux)$"

$nameMangle = {
  "pandoc-${version}/${name}"
}

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

$files = Find-GitHubAssets $project $tag $version -AssetPattern $wanted -Token $githubToken -NameMangle $nameMangle

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
