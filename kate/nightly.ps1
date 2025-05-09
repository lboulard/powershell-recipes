$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$repo = "https://cdn.kde.org/ci-builds/utilities/kate/master/windows/"
$versionPattern = "^kate-master-(?<version>\d+)-windows-cl-msvc2022-x86_64\.exe$"

Import-Module lboulard-Recipes

$links = (Invoke-HtmlRequest $repo).Links

$releases = $links.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  if ($_ -match $versionPattern) {
    [int]$Matches.version
  }
}, { $_ }

if (-not $releases) {
  [Console]::Error.WriteLine($releases -join "`n")
  throw "Installer HREF not found: $installer"
}

$version = $matches.version

$nightly = "nightly-$version"
$files = @(
  "kate-master-$version-windows-cl-msvc2022-x86_64.exe"
  "kate-master-$version-windows-cl-msvc2022-x86_64.exe.sha256"
  "kate-master-$version-windows-cl-msvc2022-x86_64-sideload.appx"
) | ForEach-Object { "${repo}/$_#${nightly}/$_" }

if ($files) {
  Get-Url $files -ProjectName kate
}
