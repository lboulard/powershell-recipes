# Find latest release of Windows Python installer for a version

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$ErrorActionPreference = "Stop"

$IndexURL = "https://vivaldi.com/download/"
$fileRegex = "/Vivaldi\.(?<version>\d+\.\d+\.\d+\.\d+)\.x64\.exe$"

$html = Invoke-HtmlRequest -Uri $IndexURL

# Find latest version at page root

$url = [System.Uri]$IndexURL

$links = $html.links

$files = $links.href | ForEach-Object {
  if ($_ -match $fileRegex) {
    @{version = [version]$Matches.version; target = $_ }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } | % { $_.target } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
} | Select-Object -First 1

$files

if ($files -match $fileRegex) {
  $version = [version]$Matches.version
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

Get-Url $files -ProjectName vivaldi
