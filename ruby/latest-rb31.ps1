
$ErrorActionPreference = "Stop"

$versionPattern = "/(?<tag>RubyInstaller-(?<revision>(?<version>(?<branch>3\.1)\.\d+)(\-\d+)?))$"
$project = "oneclick/rubyinstaller2"

$feedURL = "https://github.com/$project/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$lastVersionURL = $atomFeed.link.href | Where-Object {
  $_ -match $versionPattern
} | Sort-Object -Descending -Property {
  $_ -match $versionPattern | Out-Null
  $Matches.version -as [version]
},{ $_ }

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  Write-Host "# last Version" $atomFeed.link.href -Separator "`n"
  throw "no release found at $feedURL"
}

($lastVersionURL[0] -match $versionPattern) | Out-Null
$tag = $Matches.tag
$branch = $Matches.branch
$version = $Matches.version
$revision = $Matches.revision

$repo = "https://github.com/$project/releases/download/$tag"

$files = @(
  "rubyinstaller-$revision-x64.exe"
  "rubyinstaller-$revision-x64.exe.asc"
  "rubyinstaller-$revision-x64.7z"
  "rubyinstaller-$revision-x64.7z.asc"
) | ForEach-Object { "${repo}/$_#${branch}/$_" }

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
