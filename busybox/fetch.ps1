$ErrorActionPreference = "Stop"

$repo = "https://frippery.org/files/busybox/"

# w32, w64, w64u (unicode), w64a (arm)
$versionRegex = "^busybox-(w\d+[au]?)-FRP-(?<version>\d+-g[0-9a-f]+)\.exe"

$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
try {
  $html = Invoke-WebRequest -Uri $repo -UseBasicParsing -UserAgent $userAgent
} catch {
  Write-Error "Error: $($_.Exception.Message)"
  exit 1
}
$links = $html.Links

$releases = $links.href | Where-Object {
  $_ -match $versionRegex
} | Sort-Object -Descending -Property {
  if ($_ -match $versionRegex) {
    $parts = $Matches.version -split "-"
    [int]$parts[0]
  }
}

if (-not $releases) {
  [Console]::Error.WriteLine(($links | Select-Object -ExpandProperty href) -join "`n")
  throw "no releases found"
}


# https://scatteredcode.net/download-and-extract-gzip-tar-with-powershell/
function DeGZip-File {
  param(
    $infile,
    $outfile = ($infile -replace '\.gz$','')
  )

  $input = New-Object System.IO.FileStream $inFile,([IO.FileMode]::Open),([IO.FileAccess]::Read),([IO.FileShare]::Read)
  $output = New-Object System.IO.FileStream $outFile,([IO.FileMode]::Create),([IO.FileAccess]::Write),([IO.FileShare]::None)
  $gzipStream = New-Object System.IO.Compression.GzipStream $input,([IO.Compression.CompressionMode]::Decompress)

  $buffer = New-Object byte[] (1024)
  while ($true) {
    $read = $gzipstream.Read($buffer,0,1024)
    if ($read -le 0) { break }
    $output.Write($buffer,0,$read)
  }

  $gzipStream.Close()
  $output.Close()
  $input.Close()
}


$releases[0] -match $versionRegex | Out-Null
$version = $Matches.version

#$files =,"busybox-w32-FRP-$version.exe"
#$files += "busybox-w32-FRP-$version.exe.sig"
#$files += "busybox-w64-FRP-$version.exe"
#$files += "busybox-w64-FRP-$version.exe.sig"
#$files += "busybox-w64u-FRP-$version.exe"
#$files += "busybox-w64u-FRP-$version.exe.sig"

$binaries = "^busybox-(w\d+u?)-FRP-$([regex]::escape($version))\.exe(\.sig)?$"
$files = $releases | Where-Object { $_ -match $binaries }
$files = $files | ForEach-Object { "$_#$version/$_" }
$files += "busybox.1.gz#man1/busybox-$version.1.gz"

if (-not (Test-Path $version -PathType Container)) {
  New-Item -ItemType Directory -Path "$version" -Force | Out-Null
}

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
      $tmpFile = "$dest.tmp"
      Invoke-WebRequest -Uri "$repo/$_" -OutFile $tmpFile -UseBasicParsing -UserAgent $userAgent
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }

  if ($dest -match "\.gz$") {
    $expanded = $dest -replace "\.gz$",""
    Write-Host "# $expanded"
    if (-not (Test-Path $expanded)) {
      DeGZip-File "$dest"
    }
  }
}

if (!$error) {
  $links = (
    ("busybox.exe","$version/busybox-w32-FRP-$version.exe"),
    ("busybox64.exe","$version/busybox-w64u-FRP-$version.exe")
  )

  $brokenWarning = $false
  $links | ForEach-Object {
    $link = $_[0]
    $path = $_[1]
    if ((Test-Path $link) -and (Test-Path $path)) {
      $l = (Get-Item -Path $link -Force -ea SilentlyContinue)
      if ($l.LinkType -eq "HardLink") {
        $p = (Get-Item -Path $path -Force -ea SilentlyContinue)
        if ($l.Target -eq $p.FullName) {
          Write-Host "hardlink: $link -> $path (no change)"
          return
        } elseif ((-not $l.Target) -and (-not $brokenWarning)) {
          Write-Error "hardlink support broken on PowerShell 6 and beyond"
          Write-Error "always (re)creating hardlink"
          $brokenWarning = $true
        }
      }
    }

    Write-Host "hardlink: $link -> $path"
    try {
      New-Item -Path $link -Item HardLink -Value $path -Force | Out-Null
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}

