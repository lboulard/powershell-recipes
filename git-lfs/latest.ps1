$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

#  https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-windows-v3.5.1.exe
#  https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-windows-amd64-v3.5.1.zip
#  https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-linux-amd64-v3.5.1.tar.gz

$tagPattern = "v(?<version>\d+\.\d+(\.\d+)+)"
$project = "git-lfs/git-lfs"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "git-lfs-windows-v$version.exe",
    "git-lfs-windows-amd64-v$version.zip",
    "git-lfs-linux-amd64-v$version.tar.gz"
  )
}
