$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$repo = "https://frippery.org/files/busybox/"

# w32, w64, w64u (unicode), w64a (arm)
$versionRegex = "^busybox-(w\d+[au]?)-FRP-(?<version>\d+-g[0-9a-f]+)\.exe"

Import-Module lboulard-Recipes

$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
try {
  $html = Invoke-WebRequest -Uri $repo -UseBasicParsing -UserAgent $userAgent
} catch {
  Write-Error "Error: $($_.Exception.Message)"
  exit 1
}
$links = $html.Links

$releases = $links.href | Where-Object {
  try {
    $_ -match $versionRegex
  } catch {
  }
} | Sort-Object -Descending -Property {
  if ($_ -match $versionRegex) {
    $parts = $Matches.version -split "-"
    [int]$parts[0]
  }
}

if (-not $releases) {
  [Console]::Error.WriteLine(($links | Select-Object -ExpandProperty href) -join "`n")
  throw "no releases found"
}


if ($releases[0] -match $versionRegex) {
  $version = $Matches.version
} else {
  throw "No release found"
}

#$files =,"busybox-w32-FRP-$version.exe"
#$files += "busybox-w32-FRP-$version.exe.sig"
#$files += "busybox-w64-FRP-$version.exe"
#$files += "busybox-w64-FRP-$version.exe.sig"
#$files += "busybox-w64u-FRP-$version.exe"
#$files += "busybox-w64u-FRP-$version.exe.sig"

$binaries = "^busybox-(w\d+u?)-FRP-$([regex]::escape($version))\.exe(\.sig)?$"
$files = $releases | Where-Object { $_ -match $binaries }
$files = $files | ForEach-Object { "$_#$version/$_" }
$files += "busybox.1.gz#man1/busybox-$version.1.gz"
$files = $files | ForEach-Object { "$repo/$_" }

Get-Url $files -Headers @{ 'User-Agent' = $userAgent }

if (-not (Test-Path "man1/busybox-$version.1" )) {
  Expand-GZip "man1/busybox-$version.1.gz"
}

if (!$error) {
  @(
    ("busybox.exe", "$version/busybox-w32-FRP-$version.exe"),
    ("busybox64.exe", "$version/busybox-w64u-FRP-$version.exe")
  ) | ForEach-Object {
    try {
      $link = $_[0]
      $path = $_[1]
      $updated = (Update-HardLink $path $link -CreateIfAbsent).Updated
      Write-Host "hardlink: $link -> $path" -NoNewline
      Write-Host $(if ($updated) { "" } else { " (nochange)" })
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
