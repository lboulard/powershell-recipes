$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$index = "https://www.irfanview.com/64bit.htm"

Import-Module lboulard-Recipes

$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
try {
  $html = Invoke-WebRequest -Uri $index -UseBasicParsing -UserAgent $userAgent
} catch {
  Write-Error "Error: $($_.Exception.Message)"
  exit 1
}
if ($html.Content -match "\Wversion\s+(?<version>\d+(\.\d+)+)") {
  $version = $Matches.version
} else {
  throw "no releases found"
}

$cleanVersion = $version -replace '\.', ''
$checksums = @{}

if ($html.Content -match "(?s)English.*?Self extracting EXE file.*?SHA-256 checksum: ([0-9a-fA-f]{64})") {
  $checksums["iview${cleanVersion}_x64_setup.exe"] = $Matches.1
}
if ($html.Content -match "(?s)-64 Plugins.*?EXE-Installer.*?SHA-256 checksum: ([0-9a-fA-f]{64})") {
  $checksums["iview${cleanVersion}_plugins_x64_setup.exe"] = $Matches.1
}

if ($html.Content -match "(?s)English.*?ZIP file.*?SHA-256 checksum: ([0-9a-fA-f]{64})") {
  $checksums["iview${cleanVersion}_x64.zip"] = $Matches.1
}
if ($html.Content -match "(?s)-64 Plugins.*?ZIP File.*?SHA-256 checksum: ([0-9a-fA-f]{64})") {
  $checksums["iview${cleanVersion}_plugins_x64.zip"] = $Matches.1
}

$destDir = "irfanview-${version}"

### Official site and official mirrors forbids direct downloads

# https://github.com/microsoft/winget-pkgs/tree/master/manifests/i/IrfanSkiljan/IrfanView
# zip installer is not found on TechSoft downloads

$files = @(
  "https://files03.tchspt.com/down/iview${cleanVersion}_x64_setup.exe"
  "https://files02.tchspt.com/down/iview${cleanVersion}_plugins_x64_setup.exe"
  # "https://files02.tchspt.com/down/iview${cleanVersion}_x64.zip"
  # "https://files02.tchspt.com/down/iview${cleanVersion}_plugins_x64.zip"
) | ForEach-Object {
  $url = [System.Uri]($_)
  $filename = [Uri]::UnescapeDataString($url.Segments[-1])
  "${url}#${destDir}/${filename}"
}

Get-Url $files -Headers @{
  'User-Agent' = $userAgent
}

$checksums.GetEnumerator() | ForEach-Object {
  $filename = $_.Name
  $checksum = $_.Value

  $dest = "${destDir}/${filename}"
  $checksumDest = "${dest}.sha256"

  if (Test-Path $dest) {
    $fiSrc = Get-Item $dest
    $update = if (Test-Path $checksumDest) {
      (Get-Item $checksumDest).LastWriteTime -ne $fiSrc.LastWriteTime
    } else {
      $true
    }

    if ($update) {
      Write-Host "# ${checksumDest}"
      [System.IO.File]::WriteAllText($checksumDest, "$checksum *$filename")
      (Get-Item $checksumDest).LastWriteTime = $fiSrc.LastWriteTime
    } else {
      Write-Host "# ${checksumDest} (no change)"
    }

  }
}
