param(
  [Parameter(HelpMessage = "process development version, not stable version")]
  [switch]$DevOnly = $false
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot

$versionRegex = "^otp_win64_(?<version>\d+(?:\.\d+)+)\.zip$"

$folderRegex = "^erlang-(?<version>\d+\.\d+(?:\.\d+){0,2})$"
$lbPrograms = $Env:LBPROGRAMS
$prefix = $lbPrograms
$dest = Join-Path $prefix "Apps"

if (-not $prefix) {
  throw "prefix not defined. Is LBPROGRAMS environment variable defined?"
}
if (-not (Test-Path $prefix -PathType Container)) {
  throw "${prefix}: directory not found"
}



# ordered by version string
$folders = Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name | Where-Object {
  if ($_ -match $folderRegex) {
    # only deploy dev in dev only mode, else, only non dev version only
    $isDev = [boolean]$Matches.dev
    # (-not ($DevOnly -or $isDev)) -or ($DevOnly -and $isDev)
    if ($DevOnly) { $isDev } else { -not $isDev }
  }
} | Sort-Object -Unique -Descending -Property {
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
  ($s -replace [Regex]::Escape($prefix), '').Trim('\\')
}

Write-Host ":::: " -NoNewline
Write-Host "Will install:" (
  ($toDeploy | ForEach-Object {
    $_.Name -match $versionRegex | Out-Null
    "$($Matches.version)"
  }) -join ", "
) -ForegroundColor Yellow
Write-Host

function New-Symboliclink {
  param(
    [string]$Path,
    [string]$Value
  )

  $upToDate = $False
  if (Test-Path $Path) {
    # check is already defined
    $fileInfo = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($fileInfo.LinkType -eq "SymbolicLink") {
      $upToDate = ($fileInfo.LinkTarget -eq $Value)
    }
    if (-not $upToDate) {
      Remove-Item $Path -Force | Out-Null
    }
  }

  Write-Host ":: " -NoNewline
  Write-Host "symLink $(relative $Path)' -> $(relative $Value)" -ForegroundColor Yellow -NoNewline
  if (-not $upToDate) {
    $parent = Split-Path $Path -Parent
    $name = Split-Path $Path -Leaf
    $cwd = Get-Location
    try {
      Set-Location $parent
      New-Item -ItemType symboliclink -Path $name -Value $Value | Out-Null
    } finally {
      Set-Location -Path $cwd | Out-Null
    }
  } else {
    Write-Host " (no change)" -ForegroundColor DarkYellow -NoNewLine
  }
  Write-Host
}

try {
  $toDeploy | ForEach-Object {
    $archive = $_.FullName
    $name = $_.Name

    $name -match $versionRegex | Out-Null
    $version = $Matches.Version
    $basename = "erlang-$version"

    $installDir = Join-Path $dest $basename
    $workDir = "${installDir}-temp.${PID}"

    New-Item $workDir -ItemType directory -Force | Out-Null

    Write-Host ":: " -NoNewline
    Write-Host "Expand $(relative $name) to ${installDir}" -ForegroundColor Yellow
    Expand-Archive -DestinationPath $workDir -LiteralPath $archive -Force
    if (Test-Path $installDir) {
      $backupDir = "${installDir}~"
      Write-Host ":: Saving previous folder as $backupDir" -ForegroundColor Yellow
      if (Test-Path $backupDir) {
        Write-Host ":: ${backupDir}: present, erasing existing before backup" -ForegroundColor Red
        Remove-Item -Path $backupDir -Recurse -Force
      }
      Move-Item -Path $installDir -Destination $backupDir -Force
    }
    Move-Item -Path $workDir -Destination $installDir -Force

    # create symbolic link
    New-Symboliclink -Path "$dest/erl" -Value ".\$basename"
  }
} finally {
  if ($workDir -and (Test-Path $workDir)) {
    Remove-Item $workDir -Recurse -Force
  }
}
