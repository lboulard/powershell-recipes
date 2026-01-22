$ErrorActionPreference = "Stop"

$archiveRegex = "^zulu(?<release>\d+(\.\d+){2,3})-ca(?<openfx>-fx)?-(?<usage>jre|jdk)(?<version>\d+(\.\d+){1,2})-(win|linux)_(?<arch>i.86|x64|aarch64|amd64)\.(?<ext>zip|msi|deb)$"

$discardFolder = "_t"

$archives = Get-ChildItem -Directory | ForEach-Object {
  if ($_.Name -ne $discardFolder) {
    Get-ChildItem $_ -File -Recurse
  }
} | Select-Object DirectoryName, Name, FullName | Where-Object {
  $_.Name -match $archiveRegex
} | ForEach-Object {
  if ($_.Name -match $archiveRegex) {
    # Build number if Update number in Java
    $version = $Matches.version -as [Version]

    if ($version.Major -le 8) {
      $javaVersion = [Version]::new(1, $version.Major, $version.Minor)
      $javaUpdate = $version.Build
      $id = @($Matches.usage, $javaVersion, "_", $javaUpdate) -Join ""
    } else {
      $javaVersion = $version
      $id = @($Matches.usage, $javaVersion) -Join ""
      $javaUpdate = $null
    }

    [pscustomobject]@{
      Id            = $id
      DirectoryName = $_.DirectoryName
      Name          = $_.Name
      FullName      = $_.FullName
      ZuluRelease   = $Matches.release -as [Version]
      OpenFX        = [bool]$Matches.openfx
      Usage         = $Matches.usage.ToUpper()
      Version       = $version
      Architecture  = $Matches.arch
      Packaging     = $Matches.ext

      JavaVersion   = $version.Major
      JavaUpdate    = $javaUpdate
    }
  }
} | Group-Object -Property Usage, JavaVersion, Architecture, OpenFx, Packaging | ForEach-Object {
  $_.Group | Sort-Object -Property ZuluRelease -Descending | Select-Object -Skip 1
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