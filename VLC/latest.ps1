# Find latest release of Windows Python installer for a version

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$ErrorActionPreference = "Stop"

# WARNING final slash is required
$IndexURL = "https://download.videolan.org/pub/videolan/vlc/"
$versionPattern = "(?<version>\d+\.\d+\.\d+)"
$filePattern = "^vlc-${versionPattern}-win64\.exe(\.(asc|sha256))?$"

function Get-HTML {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Uri
  )
  try {
    $html = New-Object -Com "HTMLFile"
    if ($html) {
      $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing `
        -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
      if ($html | Get-Member -Name "IHTMLDocument2_write" -Type Method) {
        # PowerShell 5.1
        $html.IHTMLDocument2_write($response.Content)
      } else {
        $html.write([ref]$response.Content)
      }
      return $html
    } else {
      throw "failed to create HTML object"
    }
  } catch {
    Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
    throw "download or HTML parsing failed"
  }
}

$html = Get-HTML -Uri $IndexURL

# Find latest version at page root

$url = [System.Uri]$IndexURL

$foldersURL = $html.links | ForEach-Object {
  $_.pathname
} | Where-Object {
  try {
    $_ -match "^${versionPattern}/?$"
  } catch {
    $False
  }
} | Sort-Object -Descending -Property {
  if ($_ -match $versionPattern) {
    $Matches.version -as [version]
  }
}, { $_ } | ForEach-Object {
  New-Object System.Uri -ArgumentList $url, $_
}

$files = @()
foreach ($folderURL in $foldersURL) {
  # WARNING final slash is required
  $releaseURL = New-Object System.Uri -ArgumentList $folderURL, "win64/"
  Write-Verbose "Reading ${releaseURL}"
  try {
    $subhtml = Get-HTML -Uri $releaseURL
  } catch {
    return
  }
  $files += $subhtml.links | Select-Object -ExpandProperty pathname | Where-Object {
    $_ -match $filePattern
  } | ForEach-Object {
    (New-Object System.Uri -ArgumentList $releaseURL, $_).AbsoluteUri
  }
  # stop when files found
  if ($files) {
    break
  }
}

if ($files) {
  $files[0] -match $versionPattern | Out-Null
  $version = $Matches.version -as [version]
} else {
  throw "no release found"
}

Write-Host "# last Version $version"

if ($files) {
  Get-Url $files
}
