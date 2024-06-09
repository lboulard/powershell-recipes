$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+)"
$project = "d0vgan/nppexec"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    # Notepad 7.6+
    "NppExec_$($version)_dll_x64_PA.zip"
    "NppExec_$($version)_dll_PA.zip"
    # Notepad 7.5 and before
    # "NppExec_$($version)_dll_x64.zip"
    # "NppExec_$($version)_dll.zip"
  )
}
