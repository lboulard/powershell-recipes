$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot 'MultiVersion.ps1')

$archiveRegex = "^zulu(?<release>\d+(?:\.\d+)+)-ca(?<openfx>-fx)?-(?<usage>jre|jdk)(?<version>\d+(?:\.\d+)+)-(?<platform>win|linux)_(?<arch>i.86|x64|arm64|aarch64|amd64)\.(?<ext>zip|msi|deb|tar\.gz|tar\.xz)$"

$discardFolder = "_t"

$allArchives = Get-ChildItem -Directory | ForEach-Object {
  if ($_.Name -ne $discardFolder) {
    Get-ChildItem $_ -File -Recurse
  }
} | Select-Object DirectoryName, Name, FullName | Where-Object {
  $_.Name -match $archiveRegex
} | ForEach-Object {
  if ($_.Name -match $archiveRegex) {
    # Build number if Update number in Java
    $version = $Matches.version -as [MultiVersion]

    $javaVersion = $version
    $id = @($Matches.usage, $javaVersion) -join ""
    $javaUpdate = $null

    [pscustomobject]@{
      Id            = $id
      DirectoryName = $_.DirectoryName
      Name          = $_.Name
      FullName      = $_.FullName
      ZuluRelease   = $Matches.release -as [MultiVersion]
      OpenFX        = [bool]$Matches.openfx
      Usage         = $Matches.usage.ToUpper()
      Version       = $version
      Platform      = $Matches.platform
      Architecture  = $Matches.arch
      Packaging     = $Matches.ext

      JavaVersion   = $version.Major
    }
  }
}

$archives = $allArchives | Group-Object -Property Platform, Usage, JavaVersion, Architecture, OpenFx, Packaging
$archives = $archives | ForEach-Object {
  $_.Group | Sort-Object -Property ZuluRelease -Descending | Select-Object -Skip 1
}

if (-not $archives) {
  Write-Output "No archives to delete"
}

if ($archives -and (-not (Test-Path $discardFolder))) {
  New-Item -Path $discardFolder -ItemType Directory -Force | Out-Null
}

foreach ($archive in $archives) {
  $directoryPath = Resolve-Path -Path $archive.DirectoryName -Relative
  if ($directoryPath.StartsWith(".\")) {
    $directoryPath = $directoryPath.Substring(2) # remove ".\" prefix
  }
  Write-Host (" ● {0,-11}: {1}" -f $directoryPath, $archive.Name)
  $dest = Join-Path $discardFolder $directoryPath
  if (-not (Test-Path $dest)) {
    New-Item -Path $dest -ItemType Directory -Force | Out-Null
  }
  $fullDest = Join-Path $dest $archive.Name
  Move-Item -Path $archive.FullName -Destination $fullDest -Force
}