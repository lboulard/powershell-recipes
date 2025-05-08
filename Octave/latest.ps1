# Find latest release of Windows Python installer for a version

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$ErrorActionPreference = "Stop"

# octave-9.2.0-w64-installer.exe
$IndexURL = "https://octave.org/download"
$filePattern = "/octave-(?<version>\d+\.\d+\.\d+)-w64(-installer\.exe|\.7z)(\.sig)?$"

$html = Invoke-HtmlRequest -Uri $IndexURL

# Find latest version at page root

$url = [System.Uri]$IndexURL

$files = $html.links | ForEach-Object {
  $_.href
} | Where-Object {
  try {
    $_ -match $filePattern
  } catch {
    $False
  }
} | Sort-Object -Descending -Property {
  if ($_ -match $filePattern) {
    $Matches.version -as [version]
  }
}, { $_ } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
}

if ($files) {
  $files[0] -match $filePattern | Out-Null
  $version = $Matches.version -as [version]
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

$files

Get-Url $files
