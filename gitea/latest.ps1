# Find latest release of Gitea installer for a branch or latest release version

param(
  [string]$Branch = ""
)

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"
# $DebugPreference = "Continue"

$ErrorActionPreference = "Stop"

$IndexURL = "https://dl.gitea.com/gitea/"
if ($Branch) {
  $branchRegex = "(?<version>" + [regex]::escape($Branch) + "\.\d+)/"
} else {
  $branchRegex = "(?<version>\d+\.\d+\.\d+)/"
}
$versionPattern = "(?<version>\d+\.\d+\.\d+)"

$wanted = "/gitea-" + $versionPattern + "-windows-4\.0-amd64\.exe(\.(asc|sha256|asc\.sha256))?$"

$url = [System.Uri]$IndexURL

Write-Host "Reading $IndexURL"
$response = Invoke-HtmlRequest -Uri $IndexURL

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
    $folder = Invoke-HtmlRequest -Uri
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
  "$_#gitea-${version}/${name}"
}

Get-Url $files
