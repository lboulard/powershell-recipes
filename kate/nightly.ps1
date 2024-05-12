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
},{ $_ }

if (-not $releases) {
  [Console]::Error.WriteLine($releases -join "`n")
  throw "Installer HREF not found: $installer"
}

$version = $matches.version

$files =,"kate-master-$version-windows-cl-msvc2022-x86_64.exe"
$files += "kate-master-$version-windows-cl-msvc2022-x86_64.exe.sha256"
$files += "kate-master-$version-windows-cl-msvc2022-x86_64-sideload.appx"

$nightly = "nightly-$version"
New-Item -ItemType Directory -Path "$nightly" -Force | Out-Null

$files | ForEach-Object {
  $src = "$repo/$_"
  $dest = "$nightly/$_"

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
