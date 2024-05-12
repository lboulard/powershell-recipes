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
},{ $_ }

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

New-Item -ItemType Directory -Path "$version" -Force | Out-Null

$files | ForEach-Object {
  $src = "$releaseURL/$_"
  $dest = "$version/$_"

  Write-Host "# $dest"
  if (-not (Test-Path $dest)) {
    try {
      Write-Host "  -> $src"
      $tmpFile = "$dest.tmp"
      Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -UseBasicParsing
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
