param(
  [Parameter(HelpMessage = "process development version, not stable version")]
  [switch]$DevOnly = $false
)

$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$index = "https://ziglang.org/download/index.json"

$versionRegex = "^(?<version>\d+\.\d+(?:\.\d+){0,2})(?<dev>-dev\.\d+)?$"

$archs = @(
  "x86_64-windows"
  "x86_64-linux"
  "aarch64-linux"
)

$notes = @(
  "docs"
  "stdDocs"
  "notes"
)

$json = Invoke-RestMethod -Uri $index

$location = (Get-RecipesConfig).GetFetchLocation('zig')
if ($location) {
  Write-Host "Moving to $location"
  Set-Location $location
  # required for IO.File to find file
  [IO.Directory]::SetCurrentDirectory($location)
}

if ($DevOnly) {
  $versions = $json | Get-Member -MemberType NoteProperty -Name "master" | Select-Object -ExpandProperty Name
}
else {
  $versions = $json | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {
    $_ -match $versionRegex
  } | Sort-Object -Unique -Descending -Property {
    if ($_ -match $versionRegex) {
      $Matches.version -as [version]
    }
  }, { $_ }
}


if (-not $versions) {
  [Console]::Error.WriteLine($json)
  throw "no versions found"
}

function GetForAllArchs ([string]$member) {
  $releases = $json | Select-Object -ExpandProperty $member
  if ($member -match $versionRegex) {
    $version = $Matches.version
    $v = [version]$version
    $dev = $null
  }
  else {
    $version = $releases.version
    if ($version -match $versionRegex.Trim('$')) {
      $v = [version]$Matches.version
      $dev = $Matches.dev
    }
    elseif (-not $version) {
      $version = "unknown"
    }
  }
  if ($v) {
    $branch = "$($v.Major).$($v.Minor)"
    if ($dev) {
      $branch += $dev
    }
  }
  else {
    $branch = "unknown"
  }
  $notes | ForEach-Object {
    $note = $_
    $field = $releases | Get-Member -MemberType NoteProperty -Name $note
    if ($field) {
      $global:shortcuts += [pscustomobject]@{
        Version = $version
        Branch  = $branch
        Name    = $note
        URL     = $releases | Select-Object -ExpandProperty $note
      }
    }
  }
  $archs | ForEach-Object {
    $arch = $_
    $field = $releases | Get-Member -MemberType NoteProperty -Name $arch
    if ($field) {
      $release = $releases | Select-Object -ExpandProperty $arch
      [pscustomobject]@{
        Version = $version
        Arch    = $arch
        Branch  = $branch
        href    = $release.Tarball
        Sha256  = $release.shasum
        Size    = $release.Size
      }
    }
  }
}

# Only last version is maintained
$shortcuts = @()
$maintained = $versions | Select-Object -First 2 | ForEach-Object { GetForAllArchs $_ }

# Extract files to download (only latest maintained versions)
# Each version is downloaded in "$version" folder

$files = $maintained | ForEach-Object {
  $release = $_
  $dl = New-Object System.Uri -ArgumentList @($release.href)
  $name = $dl.Segments | Select-Object -Last 1
  if ($name -eq "/") {
    throw "${_.href} does not contains a filename"
  }
  $version = $release.Version
  [pscustomobject]@{
    href   = "$dl#${version}/${name}"
    Sha256 = $release.Sha256
    Size   = $release.Size
  }
}


# and download all

function Format-Bytes {
  param([int]$bytes)

  if ($bytes -lt 1KB) {
    return "{0}B" -f $bytes
  }
  elseif ($bytes -lt 1MB) {
    return "{0:N2}KB" -f ($bytes / 1KB)
  }
  elseif ($bytes -lt 1GB) {
    return "{0:N2}MB" -f ($bytes / 1MB)
  }
  elseif ($bytes -lt 1TB) {
    return "{0:N2}GB" -f ($bytes / 1GB)
  }
  else {
    return "{0:N2}TB" -f ($bytes / 1TB)
  }
}

function Verify-Size {
  param(
    [string]$filepath,
    [int]$size
  )
  $item = Get-Item $filepath
  if ($item) {
    return ($item.Length -eq $size)
  }
  return $false
}

function Verify-Checksum {
  param(
    [string]$filepath,
    [string]$checksum
  )
  $sha = Get-FileHash $filepath -Algorithm SHA256
  if ($sha) {
    $wanted = $checksum.ToUpper()
    $got = $sha.Hash
    if ($got -eq $wanted) {
      return $true
    }
    Write-Warning "Bad checksum"
    Write-Warning "Wanted: $wanted"
    Write-Warning "   Got: $got"
  }
  return $false
}

$location = (Get-RecipesConfig).GetFetchLocation('zig')

$folders = @{}  # remember created folder to create only once

$files | ForEach-Object {
  $parts = $_.href.Split('#', 2)
  $src = $parts[0]
  if ($parts.Length -eq 2) {
    $dest = $parts[1]
  }
  else {
    $dest = [System.Web.HttpUtility]::UrlDecode($parts[0] -replace '^.*/', '')
  }
  $checksum = $_.Sha256
  $size = $_.Size

  $dest = Join-Path $location $dest

  if ($size) {
    Write-Host "# $dest`t$(Format-Bytes ${size})"
  }
  else {
    Write-Host "# $dest"
  }

  if (-not (Test-Path $dest)) {
    try {
      Write-Host "  -> $src"
      $parent = Split-Path -Parent -Path $dest
      if ($parent -and -not $folders.Contains($parent)) {
        if (-not (Test-Path $parent -PathType Container)) {
          New-Item -Path $parent -ItemType Container | Out-Null
        }
        $folders.Add($parent, $True)
      }
      $tmpFile = "$dest.tmp"
      $result = Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -UseBasicParsing -PassThru
      $lastModified = $result.Headers['Last-Modified']
      # PS7 returns array, PS5 returns string
      if ($lastModified -is [array]) { $lastModified = $lastModified[0] }
      if ($lastModified) {
        try {
          $lastModifiedDate = Get-Date $lastModified
          (Get-Item $tmpFile).LastWriteTimeUtc = $lastModifiedDate
        }
        catch {
          Write-Error "Error: $($_.Exception.Message)"
          Write-Error "Date: $lastModified"
        }
      }

      $failed = $false
      if ($size -and -not (Verify-Size -File $tmpFile -Size $size)) {
        $length = (Get-Item $tmpFile).Length
        Write-Warning "${tmpfile}: bad size, wanted ${size}, got ${length}" -TargetObject $_
        $failed = $true
      }
      if ($checksum -and -not (Verify-Checksum -File $tmpFile -Checksum $checksum -Size $size)) {
        Write-Warning "${tmpfile}: bad checksum, wanted ${checksum}"
        $failed = $true
      }
      if (-not $failed) {
        Move-Item -Path $tmpFile -Destination "$dest"
      }
    }
    catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)" -TargetObject $_
      break
    }
  }
}

# Create all URL shortcuts for documentations and release notes
Write-Host $shortcuts
$shortcuts | ForEach-Object {
  $shortcut = $_
  $filename = "$($shortcut.Version)/$($shortcut.Name).url"
  if (Test-Path $filename) {
    $current = [IO.File]::ReadAllLines($filename)
  }
  else {
    $current = $null
  }
  $content = @(
    "[InternetShortcut]"
    "URL=$($shortcut.URL)"
  )
  # why just "($current -eq $null)" does not work?
  $write = if ($current -eq $null) { $true } else { $false }
  $state = ""
  if (-not $write) {
    $diff = Compare-Object $content $current
    $write = -not ($diff -eq $null)
    if ($write) {
      $state = " (updated)"
    }
  }
  Write-Host "# ${filename}${state}"
  if ($write) {
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines($filename, $content, $Utf8NoBomEncoding)
  }
}
