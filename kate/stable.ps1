$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# Find latest "release-.*" folder

$repo = "https://cdn.kde.org/ci-builds/utilities/kate/"
$versionPattern = "^release-(?<version>\d+\.\d+)"

Import-Module lboulard-Recipes

$links = (Invoke-HtmlRequest $repo).Links

$releases = $links.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  if ($_ -match $versionPattern) {
    [version]$Matches.version
  }
}, { $_ }

if (-not $releases) {
  [Console]::Error.WriteLine($releases -join "`n")
  throw "no releases found"
}

$releaseURL = "$repo$($releases[0])windows"

# find version identifier in windows folder

$links = (Invoke-HtmlRequest $releaseURL).Links

#$files =,"kate-release_$version-windows-cl-msvc2022-x86_64.exe"
#$files += "kate-release_$version-windows-cl-msvc2022-x86_64.exe.sha256"
#$files += "kate-release_$version-windows-cl-msvc2022-x86_64-sideload.appx"

$installers = "kate-release_(?<revision>(?<version>\d+\.\d+)-\d+)-windows-cl-msvc2022-x86_64(\.exe|\.exe\.sha256|-sideload\.appx)"
$files = ($links | Where-Object { $_.href -match $installers }).href
$version = $Matches.version

$files = $files | ForEach-Object { "${releaseURL}/$_#${version}/$_" }

if ($files) {
  Get-Url $files -ProjectName kate
}
