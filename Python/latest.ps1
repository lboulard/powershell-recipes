# Find latest release of Windows Python installer for a version

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

param(
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [switch]$GetDevRelease = $false
)

$ErrorActionPreference = "Stop"

$pythonFTP = "https://www.python.org/ftp/python/"
$branchRegex = [regex]::escape($Version) + "\.\d+"
$versionPattern = "(?<version>\d+\.\d+\.\d+)"
if ($GetDevRelease) {
  $versionPattern += "(?<dev>(?<Pre>a|b|rc)(?<Rev>\d+))?"
}

function Get-HTML {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Uri
  )
  try {
    $html = New-Object -Com "HTMLFile"
    if ($html) {
      $response = Invoke-HtmlRequest -Uri $Uri
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

$html = Get-HTML -Uri $pythonFTP

$url = [System.Uri]$pythonFTP

$links = @()
$html.links | ForEach-Object { $_.pathname } | ForEach-Object {
  if ($_ -match $branchRegex) {
    @{target = $_; version = [version]$Matches.version }
  }
} | Sort-Object -Descending -Property {
  $_.version
}, { $_ } |  ForEach-Object { $_.target } | ForEach-Object {
  (New-Object System.Uri -ArgumentList $url, $_).AbsoluteUri
} | ForEach-Object {
  Write-Verbose "Reading $_"
  $links += (Get-Html -Uri $_).links | ForEach-Object {
    $_.pathname
  } | Where-Object {
    # .exe are the default since 3.4, .msi before
    $_ -match ("^python-" + $versionPattern + "(-amd64\.exe|.amd64.msi)$")
  }
}

$links = $links | ForEach-Object {
  if ($_ -match $versionPattern) {
    [pscustomobject]@{
      Link    = $_
      version = [version]$Matches.version
      Pre     = if ($Matches.dev) { $Matches.Pre } else { "zz" } # "~" does not work, why?
      Rev     = [int]$Matches.Rev
    }
  }
} | Sort-Object -Descending Version, Pre, Rev | ForEach-Object Link

if ($links) {
  $links[0] -match $versionPattern | Out-Null
  $mainVersion = $Matches.version -as [version]
  $lastVersion = $Matches[0]
} else {
  throw "no release found for $Version"
}

Write-Host "# last Version $lastVersion"

if ($mainVersion -le [version]"3.0.0") {
  $files = @(
    "python-$lastVersion.amd64.msi"
    "python-$lastVersion.amd64.msi.asc"
  )
} elseif ($mainVersion -lt [version]"3.14.0") {
  $files = @(
    "python-$lastVersion-amd64.exe"
    "python-$lastVersion-amd64.exe.asc"
  )
} else {
  $files = @(
    "python-$lastVersion-amd64.exe"
  )
}
if ($mainVersion -ge [version]"3.10.0") {
  $files += @(
    "python-$lastVersion-amd64.exe.crt"
    "python-$lastVersion-amd64.exe.sig"
  )
}
if ($mainVersion -gt [version]"3.10.9") {
  $files += "python-$lastVersion-amd64.exe.sigstore"
}

if ($files) {
  $files = $files | ForEach-Object { $pythonFTP + $mainVersion + "/" + $_ }
  Get-Url $files
}
