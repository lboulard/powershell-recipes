$ErrorActionPreference = "Stop"

$repo = "https://go.dev/dl/"

$versionRegex = "^/dl/(?<release>go(?<version>\d+\.\d+(\.\d+)+)\.(linux-amd64|linux-armv6l|windows-amd64).*)"

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
} | Sort-Object -Unique -Descending -Property {
  if ($_ -match $versionRegex) {
    $Matches.version -as [version]
  }
},{ $_ }

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
      href = $_
      version = $version
      Major = [int]$version.Major
      Minor = [int]$version.Minor
      Release = $Matches.Release
    }
  }
} | Group-Object {
  "{0:d4}.{1:d4}" -f $_.Major,$_.Minor
} | Sort -Descending Name | Select-Object -First 2 | ForEach-Object {
  $_.Group | Group-Object {
    "{0:d4}.{1:d4}.{2:d4}" -f $_.Major,$_.Minor,$_.version.Build
  } | Sort-Object -Descending Name | Select-Object -First 1
} | Select-Object -ExpandProperty "Group"

# Extract files to download (only latest maintained versions)
# last version is downloaded in current folder
# other version are downloaded in "$version" folder

$folders = @()
$files = $maintained | ForEach-Object -Begin { $last = $null } {
  $dl = New-Object System.Uri -ArgumentList $url,$_.href
  if ((-not $last) -or ($last -eq $_.version)) {
    $last = $_.version
    "$dl#$($_.Release)"
  } else {
    $branch = "$($_.Major).$($_.Minor)"
    "$dl#$branch/$($_.Release)"
    $folders += $branch
  }
}

# Create folders as needed
$folders | Sort-Object -Uniq | ForEach-Object {
  $folder = $_
  if (-not (Test-Path $folder -PathType Container)) {
    Write-Host "# New folder $folder"
    New-Item -ItemType Directory -Path "$folder" -Force | Out-Null
  }
}

# and download all

$files | ForEach-Object {
  $parts = $_.Split('#',2)
  $src = $parts[0]
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
