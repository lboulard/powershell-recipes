$ErrorActionPreference = "Stop"

$versionPattern = "/(?<release>v(?<version>\d+))$"
$project = "d0vgan/nppexec"

$feedURL = "https://github.com/$project/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$lastVersionURL = $atomFeed.link.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  if ($_ -match $versionPattern) {
    $Matches.version -as [int]
  }
},{ $_ }

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  Write-Host "# last Version" $atomFeed.link.href -Separator "`n"
  throw "no release found at $feedURL"
}

($lastVersionURL[0] -match $versionPattern) | Out-Null
$release = $Matches.release
$version = $Matches.version

$repo = "https://github.com/$project/releases/download/$release"

$files = @()
# Notepad 7.6+
$files += "NppExec_$($version)_dll_x64_PA.zip"
$files += "NppExec_$($version)_dll_PA.zip"
# Notepad 7.5 and before
#$files += "NppExec_$($version)_dll_x64.zip"
#$files += "NppExec_$($version)_dll.zip"

$files | ForEach-Object {
  $parts = $_.Split('#',2)
  $src = "$repo/" + $parts[0]
  if ($parts.Length -eq 2) {
    $dest = $parts[1]
  } else {
    $dest = $parts[0]
  }

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
