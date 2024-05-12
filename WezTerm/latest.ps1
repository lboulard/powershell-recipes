$ErrorActionPreference = "Stop"

# Example: .../tag/20240203-110809-5046fc22
$versionPattern = '/(?<version>\d{8}-\d+-[0-9a-f]+)$'
$project = "wez/wezterm"

$feedURL = "https://github.com/$project/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$lastVersionURL = $atomFeed.link.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  $_ -match $versionPattern | Out-Null
  $Matches.version -split "-"
}

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  Write-Host "# last Version" $atomFeed.link.href -Separator "`n"
  throw "no release found at $feedURL"
}
($lastVersionURL[0] -match $versionPattern) | Out-Null
$release = $Matches.version
$version = $Matches.version

$repo = "https://github.com/$project/releases/download/$release"

$files =,"WezTerm-windows-$version.zip"
$files += "WezTerm-windows-$version.zip.sha256"
$files += "WezTerm-$version-setup.exe"
$files += "WezTerm-$version-setup.exe.sha256"

$files | ForEach-Object {
  $parts = $_.Split('#',2)
  $src = "$repo/" + $parts[0]
  if ($parts.Length -eq 2) {
    $dest = $parts[1]
  } else {
    $dest = $parts[0]
  }

  Write-Host "# $dest"
  if (-not (Test-Path $dest)) {
    try {
      Write-Host "  -> $src"
      $tmpFile = "$dest.tmp"
      Invoke-WebRequest -Uri "$src" -OutFile $tmpFile
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
