$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+\.\d+)"
$project = "Predelnik/DSpellCheck"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName notepad++plugins -FileSelection {
  @(
    "DSpellCheck_x64.zip#DSpellCheck_x64_$version.zip"
    "DSpellCheck_x86.zip#DSpellCheck_x86_$version.zip"
  )
}
