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
    $outfile = ($infile -replace '\.gz$', '')
  )

  $input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
  $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
  $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)

  $buffer = New-Object byte[] (1024)
  while ($true) {
    $read = $gzipstream.Read($buffer, 0, 1024)
    if ($read -le 0) { break }
    $output.Write($buffer, 0, $read)
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
  $parts = $_.Split('#', 2)
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
    $expanded = $dest -replace "\.gz$", ""
    Write-Host "# $expanded"
    if (-not (Test-Path $expanded)) {
      DeGZip-File "$dest"
    }
  }
}

# Support reading hardlinks on PS7+

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class FileLinkEnumerator
{
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr FindFirstFileNameW(string lpFileName, uint dwFlags, ref uint stringLength, StringBuilder linkName);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FindNextFileNameW(IntPtr hFindStream, ref uint stringLength, StringBuilder linkName);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FindClose(IntPtr hFindStream);
}
"@

function List-HardLinks {
  param (
    [string]$FilePath
  )

  $fileInfo = Get-Item -LiteralPath $FilePath
  $fileName = $fileInfo.FullName
  $links = @()

  $stringLength = 260
  $linkName = New-Object System.Text.StringBuilder -ArgumentList $stringLength
  $handle = [FileLinkEnumerator]::FindFirstFileNameW($fileName, 0, [ref]$stringLength, $linkName)

  if ($handle -eq [IntPtr]::Zero) {
    throw "Failed to find first file name: $([ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error()).Message)"
  }

  $drive = $fileInfo.PSDrive.Root.TrimEnd('\')
  try {
    do {
      $drive + $linkName.ToString()
      $linkName = $linkName.Clear()
      $stringLength = 260
    } while ([FileLinkEnumerator]::FindNextFileNameW($handle, [ref]$stringLength, $linkName))
  } finally {
    [FileLinkEnumerator]::FindClose($handle) | Out-Null
  }
}

function Get-HardLinks {
  param (
    [string]$FilePath
  )
  return @(List-HardLinks $FilePath)
}

function Find-HardLink {
  param(
    [string]$FilePath,
    [string]$LinkPath
  )

  $fileInfo = Get-Item -LiteralPath $LinkPath
  $fullName = $fileInfo.FullName
  List-HardLinks $FilePath | ForEach-Object {
    if ($fullName -eq $_) {
      return $True
    }
  }
  return $False
}

if (!$error) {
  $links = (
    ("busybox.exe", "$version/busybox-w32-FRP-$version.exe"),
    ("busybox64.exe", "$version/busybox-w64u-FRP-$version.exe")
  )

  $links | ForEach-Object {
    $link = $_[0]
    $path = $_[1]
    if ((Test-Path $link) -and (Test-Path $path)) {
      $l = (Get-Item -Path $link -Force -ea SilentlyContinue)
      if ($l.LinkType -eq "HardLink") {
        $p = (Get-Item -Path $path -Force -ea SilentlyContinue)
        $target = $l.Target
        if (-not $target) {
          # PS7+ does not read hardlinks by default
          if (Find-HardLink $p.FullName $l.FullName) {
            $target = $p.FullName
          }
        }
        if ($target -eq $p.FullName) {
          Write-Host "hardlink: $link -> $path (no change)"
          return
        } else {
          Write-Host "hardlink: $link -> unknown state (WARNING ignoring file)"
          return
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
