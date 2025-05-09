$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$tagPattern = "v(?<version>\d+(\.\d+)+)(-(alpha|beta|rc)\.\d)?"
$project = "be5invis/Iosevka"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName fonts-iosevka -FileSelection {
  # only fetch a subset of all fonts available (ttf, ttf-fixed, ttf-term, ttc)
  $releaseName = $tag.TrimStart('v')
  @(
    "PkgTTF-Iosevka-$releaseName.zip"
    "PkgTTF-IosevkaFixed-$releaseName.zip"
    "PkgTTF-IosevkaTerm-$releaseName.zip"
    "SuperTTC-Iosevka-$releaseName.zip"
  )
}
