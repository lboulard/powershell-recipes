$ErrorActionPreference = "Stop"

# Find latest "release-.*" folder

$repo = "https://cdn.kde.org/ci-builds/utilities/kate/"
$versionPattern = "^release-(?<version>\d+\.\d+)"

$links = (Invoke-WebRequest $repo).Links

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

$links = (Invoke-WebRequest $releaseURL).Links

#$files =,"kate-release_$version-windows-cl-msvc2022-x86_64.exe"
#$files += "kate-release_$version-windows-cl-msvc2022-x86_64.exe.sha256"
#$files += "kate-release_$version-windows-cl-msvc2022-x86_64-sideload.appx"

$installers = "kate-release_(?<revision>(?<version>\d+\.\d+)-\d+)-windows-cl-msvc2022-x86_64(\.exe|\.exe\.sha256|-sideload\.appx)"
$files = ($links | Where-Object { $_.href -match $installers }).href
$revision = $Matches.revision
$version = $Matches.version

$files = $files | ForEach-Object { "${releaseURL}/$_#${version}/$_" }

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
      if ($lastModified) {
        try {
          $lastModifiedDate = Get-Date $lastModified[0]
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
