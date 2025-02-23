$ErrorActionPreference = "Stop"

$root = $PSScriptRoot

$filenameRegex = '^Wezterm-windows-\d{8}-\d+-[0-9a-f]+$'

$folder = Join-Path $root "nightly"
$archive = Join-Path $folder "WezTerm-windows-nightly.zip"

$lbPrograms = $Env:LBPROGRAMS
$prefix = $lbPrograms
$dest = Join-Path $prefix "Apps"

if (-not $prefix) {
  throw "prefix not defined. Is LBPROGRAMS environment variable defined?"
}

if (-not (Test-Path $dest -PathType Container)) {
  throw "${prefix}: directory not found"
}

## Breaks on multifile archive
# Expand-Archive -DestinationPath $dest -LiteralPath $archive -Force

$currentDir = Get-Location
try {
  Set-Location $dest
  Write-Host " ✓ " -NoNewline -ForegroundColor Green
  Write-Host "${archive}: expand to ${dest}"
  & jar xvf $archive
  if ($LASTEXITCODE) {
    throw "${archive}: execution failed with exit code ${LASTEXITCODE}"
  }
} finally {
  Set-Location $currentDir
}

# find last version
$lastVersion = Get-ChildItem $dest -Directory | Select-Object -ExpandProperty Name | Where-Object {
  $_ -match $filenameRegex
} | Sort-Object -Descending | Select-Object -First 1

if (-not $lastVersion) {
  [Console]::Error.WriteLine($json)
  throw "no folder versions found"
}

# create symbolic link

$currentDir = Get-Location
try {
  Set-Location $dest | Out-Null
  Write-Host " ✓ " -NoNewline -ForegroundColor Green
  Write-Host "Symbolic-Link: ./weterm → ./$lastVersion"
  New-Item -ItemType SymbolicLink -Path "./wezterm" -Target "./$lastVersion" -Force | Out-Null
} finally {
  Set-Location $currentDir
}
