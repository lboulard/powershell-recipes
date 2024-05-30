$ErrorActionPreference = "Stop"

$versionPattern = "/(?<release>v(?<version>\d+\.\d+(\.\d+)+))$"
$project = "microsoft/terminal"

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
$release = $Matches.release
$version = $Matches.version

$repo = "https://github.com/$project/releases/download/$release"

$files =,"Microsoft.WindowsTerminal_$($version)_8wekyb3d8bbwe.msixbundle"
$files += "Microsoft.WindowsTerminal_$($version)_x64.zip"

$files | ForEach-Object {
  $parts = $_.Split('#',2)
  $src = "$repo/" + $parts[0]
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
      Invoke-WebRequest -Uri "$src" -OutFile $tmpFile
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
