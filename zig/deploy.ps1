param(
  [Parameter(HelpMessage = "process development version, not stable version")]
  [switch]$DevOnly = $false
)

$ErrorActionPreference = "Stop"

$versionRegex = "^zig-(?:windows-x86_64|x86_64-windows)-(?<version>(?<branch>\d+\.\d+)(?:\.\d+){0,2})(?<dev>-dev.+\+[0-9a-f]+)?.*\.zip$"

$folderRegex = "^(?<version>\d+\.\d+(?:\.\d+){0,2})(?<dev>-dev\.(?<devNumber>\d+))?"
$lbPrograms = $Env:LBPROGRAMS
$prefix = Join-Path $lbPrograms "local"
$root = Get-Location

if (-not $prefix) {
  throw "prefix not defined. Is LBPROGRAMS environment variable defined?"
}
if (-not (Test-Path $prefix -PathType Container)) {
  throw "${prefix}: directory not found"
}

if ($DevOnly) {
  Write-Output "# Doing only development version install"
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
    $version = $Matches.version
    $version += if ($Matches.dev) { "." + $Matches.devNumber } else { ".0" }
    $version = $version -as [version]
  }
  $version
}

if (-not $folders) {
  [Console]::Error.WriteLine($json)
  throw "no folder versions found"
}

# if we have branches '0.3-dev', '0.2', '0.2-dev', '0.1', '0.1-dev'
# we want to keep '0.3-dev', '0.2', '0.1' for installation candicates
# last development branch shall be installed, once released, shall be ignored

# For testing next statement
if ($false) {
  $files = @(
    [pscustomobject]@{
      Name      = 'zig-windows-x86_64-0.13.0-dev.100+facbncbn.zip'
      FullName  = '.\0.13-dev\zig-windows-x86_64-0.13.0-dev.100+facbncbn.zip'
      Directory = [pscustomobject]@{
        Name = '0.13-dev'
      }
    }
    [pscustomobject]@{
      Name      = 'zig-windows-x86_64-0.12.0.zip'
      FullName  = '.\0.12\zig-windows-x86_64-0.12.0.zip'
      Directory = [pscustomobject]@{
        Name = '0.12'
      }
    }
    [pscustomobject]@{
      Name      = 'zig-windows-x86_64-0.12.0-dev.100+facbncbn.zip'
      FullName  = '.\0.12-dev\zig-windows-x86_64-0.12.0-dev.100+facbncbn.zip'
      Directory = [pscustomobject]@{
        Name = '0.12-dev'
      }
    }
    [pscustomobject]@{
      Name      = 'zig-windows-x86_64-0.11.0.zip'
      FullName  = '.\0.11\zig-windows-x86_64-0.11.0.zip'
      Directory = [pscustomobject]@{
        Name = '0.11'
      }
    }
    [pscustomobject]@{
      Name      = 'zig-windows-x86_64-0.11.0-dev.100+facbncbn.zip'
      FullName  = '.\0.11-dev\zig-windows-x86_64-0.11.0-dev.100+facbncbn.zip'
      Directory = [pscustomobject]@{
        Name = '0.11-dev'
      }
    }
  )
}

# sort again, but from filename pattern
$files = $folders | Get-ChildItem -File | Where-Object {
  $_.Name -match $versionRegex
}
$toDeploy = $files | Group-Object -Property {
  if ($_.Name -match $versionRegex) {
    $Matches.branch
  }
} | Sort-Object -Unique -Descending -Property {
  $_.Name -as [version]
} | Select-Object -First $(if ($DevOnly) { 1 } else { 3 }) | ForEach-Object {
  $_.Group | Sort-Object -Descending -Unique -Property {
    if ($_.Name -match $versionRegex) {
      $Matches.version -as [version]
    }
  } | Select-Object -First 1
}

if (-not $toDeploy) {
  [Console]::Error.WriteLine(($files | Select-Object -ExpandProperty FullName) -join "`n")
  throw "no files to install"
}

# $toDeploy | Select-Object FullName

$apps = Join-Path $prefix "Apps"
$bin = Join-Path $prefix "bin"
$workDir = Join-Path $apps "zip-tmp-$PID-$(Get-Random -Maximum 100000)"

function relative([string]$s) {
  ($s -replace [Regex]::Escape($prefix), '').Trim('\\')
}

Write-Host ":::: " -NoNewline
Write-Host "Will install:" (
  ($toDeploy | ForEach-Object {
    $_.Name -match $versionRegex | Out-Null
    "$($Matches.version)$($Matches.dev)"
  }) -join ", "
) -ForegroundColor Yellow
Write-Host

function createSymboliclink($Path, $Value) {

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
    New-Item -Path $Path -ItemType symboliclink -Value $Value | Out-Null
  } else {
    Write-Host " (no change)" -ForegroundColor DarkYellow -NoNewline
  }
  Write-Host
}

try {
  $toDeploy | ForEach-Object {
    $_.Name -match $versionRegex | Out-Null
    $branch = $Matches.Branch

    $archive = $_.FullName
    $name = $_.Name
    $basename = $_.Name -replace '\.zip', ''
    $isDev = ($name -match '-dev')

    $dest = Join-Path $apps $basename

    # expand and after verification of top folder name, install in final destination
    if (-not (Test-Path $dest)) {
      if (-not (Test-Path $workDir)) {
        New-Item $workDir -ItemType directory -Force | Out-Null
      }

      Write-Host ":: " -NoNewline
      Write-Host "Expand $(relative $name) to ${apps}\" -ForegroundColor Yellow
      $installPath = Join-Path $workDir $basename
      if (Test-Path $installPath) {
        Remove-Item $installPath -Recurse -Force | Out-Null
      }
      Expand-Archive -DestinationPath $workDir -LiteralPath $archive -Force
      if (Test-Path $installPath) {
        Move-Item -Path $installPath -Destination $apps -Force
      } else {
        Write-Error "Expected $installPath not found after extraction"
        throw "$installPath not found"
      }
    } else {
      Write-Host ":: " -NoNewline
      Write-Host "${branch}: $name already found in ${apps}\" -ForegroundColor Green
    }

    # create symbolic links

    $zigExe = Join-Path $dest 'zig.exe'

    $symlink = Join-Path $bin "zig-$branch.exe"
    createSymbolicLink $symlink $zigExe

    if ($isDev) {
      $symlink = Join-Path $bin "zig-dev.exe"
      createSymbolicLink -Path $symlink -Value $zigExe
    } elseif (-not $mainSymlink) {
      # only first non-dev version is main zig.exe in symlink
      $mainSymlink = Join-Path $bin "zig.exe"
      createSymbolicLink $mainSymlink $zigExe
    }
  }
} finally {
  if (Test-Path $workDir) {
    Remove-Item $workDir
  }
}
