
function s:Run-Command {
  param(
    [scriptblock]$ScriptBlock,
    [string]$ErrorAction = $ErrorActionPreference
  )
  Push-Location $PSScriptRoot
  try {
    & @ScriptBlock
  } finally {
    Pop-Location
  }
  if (($lastexitcode -ne 0) -and $ErrorAction -eq "Stop") {
    exit $lastexitcode
  }
}

function s:Expand {
  $sdk = Join-Path $Home "sdk"
  $versions = @{}
  Get-ChildItem -Filter "go*.windows-amd64.zip" -File -Name | `
     Where-Object { $_ -match "\d+\.\d+(\.\d+)?" } | `
     ForEach-Object { $versions[$Matches[0]] = $_ }
  $ordered = $versions.GetEnumerator() | Sort-Object { $_.Name.split(".") | ForEach-Object { [int]$_ } } -Descending
  if ($versions.Count -eq 0) {
    return
  }
  $archive = $ordered[0].Value
  $version = $ordered[0].Key

  $src = Join-Path $sdk "tmp"

  Write-Information -MessageData "** Extracting to $src ..." -InformationAction Continue
  Expand-Archive -LiteralPath $archive -DestinationPath $src -Force
  $dest = Join-Path $sdk "go$version"
  if (Test-Path -Path $dest) {
    Remove-Item -Path $dest -Recurse
  }

  Write-Information -MessageData "** Installing to $dest ..." -InformationAction Continue
  Move-Item -Path $src\go -Destination $dest -Force
  Remove-Item -Path $src -ErrorAction "Continue"
}

$ErrorActionPreference = "Stop"
s:Run-Command -ScriptBlock { s:Expand }
