$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "(?<tag>v(?<version>\d+\.\d+(\.\d+)+))"
$project = "activescott/lessmsi"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName lessmsi -FileSelection {
  @(
    "lessmsi-${tag}.zip"
    "lessmsi.${version}.nupkg"
  )
} -NameMangle {
  "lessmsi-${version}/${name}"
}
