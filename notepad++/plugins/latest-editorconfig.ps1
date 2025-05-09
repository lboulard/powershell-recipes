$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+\.\d+(\.\d+)?)"
$project = "editorconfig/editorconfig-notepad-plus-plus"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName notepad++plugins -FileSelection {
  $flatVersion = $version -replace '\.', ''
  @(
    "NppEditorConfig-${flatVersion}-x64.zip"
    "NppEditorConfig-${flatVersion}-x86.zip"
  )
}
