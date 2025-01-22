$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "wez/wezterm"

Import-Module lboulard-Recipes

$token = Get-GitHubToken
$files = Find-GitHubAssets $project `
 -Tag "nightly" `
 -Version "nightly" `
 -Token $token `
 -AssetPattern '(-windows-nightly\.zip|nightly-setup\.exe)(\.sha256)?$' `
 -NameMangle { "${tag}/${name}" }

if ($files) {
  Get-Url $files
}
