$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$index = "https://www.irfanview.com/64bit.htm"

Import-Module lboulard-Recipes

try {
  $html = Invoke-HtmlRequest -Uri $index
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

if ($false) {

  $files = @(
    # "https://files03.tchspt.com/down/iview${cleanVersion}_x64_setup.exe"
    "https://files02.tchspt.com/down/iview${cleanVersion}_x64_setup.exe"
    "https://files02.tchspt.com/down/iview${cleanVersion}_plugins_x64_setup.exe"
    # "https://files02.tchspt.com/down/iview${cleanVersion}_x64.zip"
    # "https://files02.tchspt.com/down/iview${cleanVersion}_plugins_x64.zip"
  ) | ForEach-Object {
    $url = [System.Uri]($_)
    $filename = [Uri]::UnescapeDataString($url.Segments[-1])
    "${url}#${destDir}/${filename}"
  }

  # Direct download does not work
  Get-Url $files -Headers @{
    'Referer'    = 'https://www.techspot.com/'
  }
}

# https://www.fosshub.com/IrfanView.html?dwl=iview470_x64_setup.exe
# https://www.fosshub.com/IrfanView.html?dwl=iview470_plugins_x64_setup.exe

# Create URL file to downloads

@(
  "iview${cleanVersion}_x64_setup.exe"
  "iview${cleanVersion}_plugins_x64_setup.exe"
) | ForEach-Object {
  $filename = $_
  $basename = Split-Path -Path $filename -LeafBase
  @{
    'url'      = "https://www.fosshub.com/IrfanView.html?dwl=${filename}"
    'shortCut' = "${destDir}/${basename}.url"
  }
} | ForEach-Object {
  $url = $_.url
  $shortCut = $_.shortCut
  Write-Host "# ${shortCut}"
  @(
    "[InternetShortcut]"
    "URL=${url}"
  ) | Set-Content -Path $shortCut
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
