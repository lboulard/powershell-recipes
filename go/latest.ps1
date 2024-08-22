$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

Import-Module lboulard-Recipes

$IndexURL = "https://go.dev/dl/"
$pathRegex = "/dl/(?<release>go(?<version>\d+\.\d+(\.\d+)+)\.(linux-amd64|linux-armv6l|windows-amd64).*)"

$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
try {
  $html = Invoke-WebRequest -Uri $IndexURL -UseBasicParsing -UserAgent $userAgent
} catch {
  Write-Error "Error: $($_.Exception.Message)"
  exit 1
}

$url = [System.Uri]$IndexURL

$links = $html.Links

$releases = $links.href | ForEach-Object {
  if ($_ -match $pathRegex) {
    @{target = $_; version = [version]$Matches.version }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } | % { $_.target } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
}

if (-not $releases) {
  [Console]::Error.WriteLine(($links | Select-Object -ExpandProperty href) -join "`n")
  throw "no releases found"
}

# Keep only two last branches that are maintained

# BEWARE: PS5 maintains order when grouping object, PS6+ does not maintain order
$maintained = $releases | ForEach-Object {
  if ($_ -match $pathRegex) {
    $version = [version]$Matches.version
    $major, $minor = [int]$version.Major, [int]$version.Minor
    [pscustomobject]@{
      Target  = $_
      Version = $version
      Branch  = (@($major, $minor) -join ".")
      Major   = $major
      Minor   = $minor
      Release = $Matches.Release
    }
  }
} | Group-Object {
  "{0:d4}.{1:d4}" -f $_.Major, $_.Minor
} | Sort-Object -Descending Name | Select-Object -First 2 | ForEach-Object {
  $_.Group | Group-Object {
    "{0:d4}.{1:d4}.{2:d4}" -f $_.Major, $_.Minor, $_.version.Build
  } | Sort-Object -Descending Name | Select-Object -First 1
} | Select-Object -ExpandProperty "Group"

# Extract files to download (only latest maintained versions)
# last version is downloaded in current folder
# other version are downloaded in "$version" folder

$files = $maintained | ForEach-Object {
  "$($_.Target)#go$($_.Branch)/$($_.Release)"
}

$files

if ($files) {
  Get-Url $files
}
