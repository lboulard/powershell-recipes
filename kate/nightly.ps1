$ErrorActionPreference = "Stop"

$repo = "https://cdn.kde.org/ci-builds/utilities/kate/master/windows/"
$versionPattern = "^kate-master-(?<version>\d+)-windows-cl-msvc2022-x86_64\.exe$"

$links = (Invoke-WebRequest $repo).Links

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

# and download all

$folders = @{}  # remember created folder to create only once

$files | ForEach-Object {
  $url = [System.Uri]($_)
  $src = $url.AbsoluteUri
  if ($url.Fragment -and ($url.Fragment.Length -gt 1)) {
    $dest = [Uri]::UnescapeDataString($url.Fragment.Substring(1))
  } else {
    $dest = [Uri]::UnescapeDataString($url.Segments[-1])
  }

  Write-Host "# $dest"
  if (-not (Test-Path $dest)) {
    try {
      Write-Host "  -> $src"
      $parent = Split-Path -Parent -Path $dest
      if ($parent -and -not $folders.Contains($parent)) {
        if (-not (Test-Path $parent -PathType Container)) {
          New-Item -Path $parent -ItemType Container | Out-Null
        }
        $folders.Add($parent, $True)
      }
      $tmpFile = "$dest.tmp"
      $result = Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -UseBasicParsing -PassThru
      $lastModified = $result.Headers['Last-Modified']
      # PS7 returns array, PS5 returns string
      if ($lastModified -is [array]) { $lastModified = $lastModified[0] }
      if ($lastModified) {
        try {
          $lastModifiedDate = Get-Date $lastModified
          (Get-Item $tmpFile).LastWriteTimeUtc = $lastModifiedDate
        } catch {
          Write-Error "Error: $($_.Exception.Message)"
          Write-Error "Date: $lastModified"
        }
      }
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
