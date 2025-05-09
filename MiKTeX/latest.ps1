# Find latest release of Windows Python installer for a version

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$ErrorActionPreference = "Stop"

# Find latest versions at page root

$IndexURL = "https://miktex.org/download"
$html = Invoke-HtmlRequest -Uri $IndexURL
$links = $html.links.href | % { [System.Net.WebUtility]::HtmlDecode($_) }

$url = [System.Uri]$IndexURL

#####

Write-Host  "# Basic MikTeX"

# Example: basic-miktex-24.1-x64.exe
$fileRegex = "/basic-miktex-(?<version>\d+\.\d+(\.\d+){0,2})-x64\.exe$"

$files = $links | ForEach-Object {
  if ($_ -match $fileRegex) {
    @{version = [version]$Matches.version; target = $_ }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } | % { $_.target } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
} | Select-Object -First 1 -Unique

$files
if ($files -match $fileRegex) {
  $version = [version]$Matches.version
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

Get-Url $files -ProjectName miktex

#####

Write-Host  "# MikTeX CLI setup"

# example: miktexsetup-5.5.0+1763023-x64.zip
$fileRegex = "/miktexsetup-(?<version>\d+\.\d+(\.\d+){0,2})\+\d+-x64\.zip$"

$files = $links | ForEach-Object {
  if ($_ -match $fileRegex) {
    @{version = [version]$Matches.version; target = $_ }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } | % { $_.target } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
} | Select-Object -First 1 -Unique

$files

if ($files -match $fileRegex) {
  $version = [version]$Matches.version
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

Get-Url $files -ProjectName miktex

