param(
  [Parameter(Position = 0, mandatory = $true, HelpMessage = "Install prefix path")]
  [String]$Prefix,
  [Parameter(HelpMessage = "erlang version string")]
  [String]$erlangVersion = "29"
)

$ErrorActionPreference = "Stop"

$root = Get-Location

$versionRegex = "^elixir-otp-${erlangVersion}-(?<version>\d+(?:\.\d+)+)\.zip$"

$folderRegex = "^(?<version>\d+\.\d+(?:\.\d+){0,2})$"

if (-not (Test-Path $prefix -PathType Container)) {
  throw "${prefix}: directory not found"
}


# ordered by version string
$folders = Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name | Sort-Object -Unique -Descending -Property {
  if ($_ -match $folderRegex) {
    $Matches.version -as [version]
  }
}

if (-not $folders) {
  [Console]::Error.WriteLine($json)
  throw "no folder versions found"
}

# sort again, but from filename pattern
$selected = $folders | Get-ChildItem -File | Where-Object {
  $_.Name -match $versionRegex
} | Sort-Object -Unique -Descending -Property {
  if ($_.Name -match $versionRegex) {
    $Matches.version -as [version]
  }
}

if (-not $selected) {
  [Console]::Error.WriteLine(($files | Select-Object -ExpandProperty FullName) -join "`n")
  throw "no files to install"
}


$toDeploy = $selected | Select-Object -First 1

# $toDeploy | Select-Object FullName

function relative([string]$s) {
  ($s -replace [Regex]::Escape($Prefix), '').Trim('\\')
}

Write-Host ":::: " -NoNewline
Write-Host "Will install:" (
  ($toDeploy | ForEach-Object {
    $_.Name -match $versionRegex | Out-Null
    "$($Matches.version)"
  }) -join ", "
) -ForegroundColor Yellow
Write-Host

$toDeploy | ForEach-Object {
  $archive = $_.FullName
  $name = $_.Name

  $name -match $versionRegex | Out-Null
  $version = $Matches.Version

  Write-Host ":: " -NoNewline
  Write-Host "Expand $(relative $name) to ${Prefix}" -ForegroundColor Yellow
  Expand-Archive -DestinationPath $Prefix -LiteralPath $archive -Force }
