$ErrorActionPreference = "Stop"

$location = (Get-RecipesConfig).GetFetchLocation('vscode')
if ($location) {
  Write-Host "Moving to $location"
  Set-Location $location
}

$nameRegex = "^VSCode-win32-x64-(?<version>\d+\.\d+\.\d+)\.zip$"

$folderRegex = "^(?<version>\d+\.\d+\.\d+)$"
$lbHome = $Env:LBHOME
$installDir = Join-Path $lbHome "Apps"
$root = $PSScriptRoot

if (-not $lbHome) {
  throw "lbHome not defined. Is LBHOME environment variable defined?"
}

if (-not (Test-Path $installDir -PathType Container)) {
  New-Item $installDir -ItemType Container -Force | Out-Null
}

# folders ordered by version string
$folders = Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name | Where-Object {
  $_ -match $folderRegex
} | Sort-Object -Unique -Descending -Property {
  if ($_ -match $folderRegex) {
    $Matches.version -as [version]
  }
}

if (-not $folders) {
  throw "no folder versions found"
}

$lastVersion = $folders[0]

# sort again, but from filename pattern
$files = $folders | Get-ChildItem -File | Where-Object {
  if ($_.Name -match $nameRegex) {
      $_
  }
}

if (-not $files) {
  throw "no file versions found"
}

$archive = $files[0]
if ($archive.Name -match $nameRegex) {
  $archiveVersion = [version]$Matches.version
  if (-not ($archiveVersion -eq $lastVersion)) {
    Write-Warning "${archive}: does not match last version ${lastVersion} (found $($Matches.version))"
  }
}

$name = $archive.Name
$basename = $archive.BaseName
$dest = Join-Path $installDir $basename
$workDir = Join-Path $installDir "${basename}_$PID_$(Get-Random -Maximum 100000)"

try {

  # expand and after verification of top folder name, install in final destination
  if (-not (Test-Path $dest)) {
    if (-not (Test-Path $workDir)) {
      New-Item $workDir -ItemType directory -Force | Out-Null
    }

    Write-Host ":: " -NoNewline
    Write-Host "Expand ${name} to ${installDir}\" -ForegroundColor Yellow
    Expand-Archive -DestinationPath $workDir -LiteralPath $archive.FullName -Force
    Move-Item -Path $workDir -Destination $dest -Force
  } else {
    Write-Host ":: " -NoNewline
    Write-Host "${basename}: already found in ${installDir}\" -ForegroundColor Green
  }

  # create symbolic link
  $symlink = Join-Path $installDir "VSCode"
  $target = $basename

  Push-Location $installDir
  try {
    Write-Host ":: " -NoNewline
    Write-Host "symLink '${symlink}' -> '$target'" -ForegroundColor Yellow -NoNewline

    if (Test-Path $symlink) {
      $item = Get-Item -Path $symlink
      if ($item) {
        $update = -not ($item.target -eq $dest)
        if ($update) {
          $item.Delete()
        }
      } else {
        $update = $true
      }
    } else {
      $update = $true
    }

    if ($update) {
      New-Item -ItemType SymbolicLink -Path $symlink -Target ".\$target" | Out-Null
    } else {
      Write-Host " (no change)" -ForegroundColor DarkYellow -NoNewLine
    }
  } finally {
    Write-Host
    Pop-Location
  }

} finally {
  if (Test-Path $workDir) {
    Remove-Item $workDir
  }
}
