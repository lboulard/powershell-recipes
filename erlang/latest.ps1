$ErrorActionPreference = "Stop"

$repo = "https://erlang.org/download/otp_versions_tree_app_vsns.html"

# https://github.com/erlang/otp/releases/download/OTP-27.0/otp_win64_27.0.exe

$versionRegex = "/(?<release>otp_(win64|doc_html)_(?<version>\d+\.\d+(\.\d+){0,2})(\.\d+)*\.(exe|tar\.gz))$"

$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
try {
  $html = Invoke-WebRequest -Uri $repo -UseBasicParsing -UserAgent $userAgent
} catch {
  Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
  exit 1
}
$links = $html.Links

$releases = $links.href | Where-Object {
  try {
    $_ -match $versionRegex
  } catch {
    $false
  }
} | Sort-Object -Unique -Descending -Property {
  if ($_ -match $versionRegex) {
    $Matches.version -as [version]
  }
}, { $_ }

if (-not $releases) {
  [Console]::Error.WriteLine(($links | Select-Object -ExpandProperty href) -join "`n")
  throw "no releases found"
}

# keep only two last branch that are maintained

$url = [System.Uri]$repo

# Get list of maintained version

# BEWARE: PS5 maintains order when grouping object, PS6+ does not maintain order
$maintained = $releases | ForEach-Object {
  if ($_ -match $versionRegex) {
    $version = [version]$Matches.version
    [pscustomobject]@{
      href    = $_
      version = $version
      Major   = [int]$version.Major
      Minor   = [int]$version.Minor
      Build   = [math]::max(0, $version.Build)
      Release = $Matches.Release
    }
  }
} | Group-Object {
  "{0:d4}.{1:d4}" -f $_.Major, $_.Minor
} | sort -Descending Name | Select-Object -First 2 | ForEach-Object {
  $_.Group | Group-Object {
    "{0:d4}.{1:d4}.{2:d4}" -f $_.Major, $_.Minor, $_.Build
  } | Sort-Object -Descending Name | Select-Object -First 1
} | Select-Object -ExpandProperty "Group"

# Extract files to download (only latest maintained versions)
# last version is downloaded in current folder
# other version are downloaded in "$version" folder

$files = $maintained | ForEach-Object -Begin { $last = $null } {
  $dl = New-Object System.Uri -ArgumentList $url, $_.href
  if ((-not $last) -or ($last -eq $_.version)) {
    $last = $_.version
    "$dl#$($_.Release)"
  } else {
    $branch = "$($_.Major).$($_.Minor)"
    "$dl#$branch/$($_.Release)"
  }
}

# and download all

$folders = @{}  # remember created folder to create only once

$files | ForEach-Object {
  $url = [System.Uri]($_)
  $src = $url.AbsoluteUri
  if ($url.Fragment -and ($url.Fragment.Length -gt 1)) {
    $dest = [Uri]::UnescapeDataString($url.Fragment.Substring(1))
  } else {
    $dest = [Uri]::UnescapeDataString($url.Segments[-1])
  }

  Write-Host "# $dest"
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
      if ($lastModified) {
        try {
          $lastModifiedDate = Get-Date $lastModified[0]
          (Get-Item $tmpFile).LastWriteTimeUtc = $lastModifiedDate
        } catch {
          Write-Error "Error: $($_.Exception.Message)"
          Write-Error "Date: $lastModified"
        }
      }
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
