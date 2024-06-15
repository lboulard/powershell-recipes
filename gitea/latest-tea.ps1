# Find latest release of Gitea tea tool

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"
# $DebugPreference = "Continue"

$ErrorActionPreference = "Stop"

$IndexURL = "https://dl.gitea.com/tea/"
$branchRegex = "(?<version>\d+\.\d+(\.\d+)?)/"
$versionPattern = "(?<version>\d+\.\d+(\.\d+)?)"

$wanted = "/tea-" + $versionPattern + "-windows(-4\.0)?-amd64\.exe(\.(asc|sha256|asc\.sha256))?$"

$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'

$url = [System.Uri]$IndexURL

Write-Host "Reading $IndexURL"
$response = Invoke-WebRequest -Uri $IndexURL -UseBasicParsing -UserAgent $UserAgent

$files = $response.links.href | ForEach-Object {
  if ($_ -match $branchRegex) {
    @{target = $_; version = [version]$Matches.version }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } | % { $_.target } | ForEach-Object {
  New-Object System.Uri -ArgumentList $url, $_
} | ForEach-Object -Begin { $found = $False } -Process {
  if (-not $found) {
    Write-Host "Reading $_"
    $folderURL = $_
    $folder = Invoke-WebRequest -Uri $_ -UseBasicParsing -UserAgent $UserAgent
    $folder.links.href | Where-Object {
      $_ -match $wanted
    } | ForEach-Object {
      $found = $True
      Write-Debug "accepted: ${folderURL} : $_"
      (New-Object System.Uri -ArgumentList $folderURL, $_).AbsoluteUri
    }
  }
}

if ($files) {
  $files[0] -match $versionPattern | Out-Null
  $version = $Matches.version -as [version]
} elseif ($Branch) {
  throw "no release found for ${Branch}"
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

$files = $files | % { 
  $u = [System.Uri]$_
  $name = $u.Segments[-1]
  "$_#tea-${version}/${name}"
}

Get-Url $files
