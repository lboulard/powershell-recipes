$ErrorActionPreference = "Stop"

$versionPattern = "/(?<tag>v(?<version>\d+\.\d+(\.\d+)?))$"
$project = "editorconfig/editorconfig-notepad-plus-plus"

$lastReleaseURL = "https://github.com/$project/releases/latest"
try {
  $response = Invoke-WebRequest -Method Head -Uri $lastReleaseURL -ErrorAction Ignore
  $statusCode = $response.StatusCode
  Write-Verbose ("`$statusCode={0}" -f $statusCode)
} catch {
  Write-Verbose $_.Exception
  $statusCode = $_.Exception.Response.StatusCode.value__
}
if ($statusCode -eq 302) {
  $lastVersionURL = $response.Headers.Location
} elseif ($statusCode -eq 200) {
  if ($response.BaseResponse.ResponseUri -ne $null) {
    # PS5.1
    $lastVersionURL = $response.BaseResponse.ResponseUri.AbsoluteUri
    Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
  } elseif ($response.BaseResponse.RequestMessage.RequestUri -ne $null) {
    # PS7
    $lastVersionURL = $response.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
    Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
  }
} else {
  Write-Error ("HTTP Response {0}: {1}" -f $statusCode, $response.StatusDescription)
  throw ("unexpected response {0} for {1}" -f $statusCode, $lastReleaseURL)
}

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  throw "no release found at ${lastReleaseURL}"
}

($lastVersionURL -match $versionPattern) | Out-Null
$tag = $Matches.tag
$version = $Matches.version

$repo = "https://github.com/$project/releases/download/$tag"

$flatVersion = $version -replace '\.', ''
$files = @(
  "NppEditorConfig-${flatVersion}-x64.zip"
  "NppEditorConfig-${flatVersion}-x86.zip"
) | ForEach-Object { "$repo/$_" }

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
