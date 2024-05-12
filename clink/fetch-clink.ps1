$ErrorActionPreference = "Stop"

$versionPattern = "/(?<tag>v(?<version>\d+\.\d+\.\d+))$"
$project = "chrisant996/clink"

$feedURL = "https://github.com/$project/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$lastVersionURL = $atomFeed.link.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  if ($_ -match $versionPattern) {
    $Matches.version -as [version]
  }
},{ $_ }

if ($lastVersionURL -and (-not ($errors))) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  throw "no release found at $feedURL"
}

($lastVersionURL[0] -match $versionPattern) | Out-Null
$tag = $Matches.tag
$version = $Matches.version

# filenames are not enough to find release files
# use GitHub API

$headers = @{
  'Accept' = 'application/vnd.github+json';
  "X-GitHub-Api-Version" = "2022-11-28"
}
$token = $env:GITHUB_TOKEN
if ($token) {
  $headers['Authorization'] = 'Bearter ' + $token
}

$wanted = "clink.$([regex]::escape($version))\.[0-9a-f]+.zip$"

try {
  $json = Invoke-WebRequest -Uri "https://api.github.com/repos/$project/releases/tags/$tag" -Headers $headers -UseBasicParsing
  $release = $json.Content | ConvertFrom-Json
  $files = $release.assets | ForEach-Object {
    $asset = $_
    if ($asset.Name -match $wanted) {
      "$($asset.url)#$($asset.name)"
    }
  }
} catch {
  Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
  break
}

$headers['Accept'] = 'application/octet-stream'

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
      Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -Headers $headers -UseBasicParsing
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
