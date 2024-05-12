
$ErrorActionPreference = "Stop"

$versionPattern = "/(?<release>RubyInstaller-(?<revision>(?<version>(?<branch>3\.3)\.\d+)(\-\d+)?))$"
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
$release = $Matches.release
$branch = $Matches.branch
$version = $Matches.version
$revision = $Matches.revision

$repo = "https://github.com/$project/releases/download/$release"

$files =,"rubyinstaller-$revision-x64.exe"
$files += "rubyinstaller-$revision-x64.exe.asc"
$files += "rubyinstaller-$revision-x64.7z"
$files += "rubyinstaller-$revision-x64.7z.asc"

$files = $files | ForEach-Object { "$($_)#$branch/$_" }

if (-not (Test-Path $branch -PathType Container)) {
  New-Item -ItemType Directory -Path "$branch" -Force | Out-Null
}

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
