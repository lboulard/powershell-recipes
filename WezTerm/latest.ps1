$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# Example: .../tag/20240203-110809-5046fc22
$tagPattern = '(?<version>\d{8}-\d+-[0-9a-f]+)'
$project = "wez/wezterm"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName wezterm -FileSelection {
  @(
    "WezTerm-windows-$version.zip"
    "WezTerm-windows-$version.zip.sha256"
    "WezTerm-$version-setup.exe"
    "WezTerm-$version-setup.exe.sha256"
  )
} -NameMangle {
  "${version}/${name}"
}
