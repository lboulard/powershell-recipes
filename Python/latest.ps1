# Find latest release of Windows Python installer for a version

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

$html = Get-HTML -Uri $pythonFTP

$pathnames = $html.links | ForEach-Object {
  $_.pathname
} | Where-Object {
  $_ -match ("^" + $branchRegex + "/$")
} | Sort-Object -Descending -Property {
  $_ -match $branchRegex
  $Matches.version -as [version]
}, { $_ }

$links = @()
$pathnames | ForEach-Object {
  $releaseURL = $pythonFTP + $_
  $html = Get-HTML -Uri $releaseURL
  $links += $html.links | ForEach-Object {
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
} else {
  $files = @(
    "python-$lastVersion-amd64.exe"
    "python-$lastVersion-amd64.exe.asc"
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

$files = $files | ForEach-Object { $pythonFTP + $mainVersion + "/" + $_ }

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
