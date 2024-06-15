$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# caddy_2.8.4_windows_amd64.zip

$tagPattern = "v(?<version>\d+\.\d+(\.\d+)+)"
$project = "caddyserver/caddy"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -FileSelection {
  @(
    "caddy_${version}_windows_amd64.zip"
    "caddy_${version}_windows_amd64.zip.sig"
    "caddy_${version}_windows_arm64.zip"
    "caddy_${version}_windows_arm64.zip.sig"
    "caddy_${version}_linux_amd64.deb"
    "caddy_${version}_linux_amd64.deb.sig"
    "caddy_${version}_linux_arm64.deb"
    "caddy_${version}_linux_arm64.deb.sig"
    "caddy_${version}_linux_amd64.tar.gz"
    "caddy_${version}_linux_amd64.tar.gz.sig"
    "caddy_${version}_linux_arm64.tar.gz"
    "caddy_${version}_linux_arm64.tar.gz.sig"
  )
} -NameMangle {
    "caddy-${version}/${name}"
}
