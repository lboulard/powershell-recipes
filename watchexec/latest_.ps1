
$feedURL = "https://github.com/watchexec/watchexec/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$versionPattern = "/v(\d+\.\d+\.\d+)$"
$lastVersionURL = $atomFeed.link.href | Where-Object {$_ -match $versionPattern}
$version = $Matches[1]
if ($lastVersionURL) {
  Write-Host "last Version " $lastVersionURL
} else {
  throw "no release found at $feedURL"
}

$repo = "https://github.com/watchexec/watchexec/releases/download/v$version"

$files = , "watchexec-$version-x86_64-pc-windows-msvc.zip"
$files += "watchexec-$version-x86_64-pc-windows-msvc.zip.sha256"
$files += "watchexec-$version-x86_64-pc-windows-msvc.zip.b3"

$files | ForEach {
  Write-Host "# $_"
  Invoke-WebRequest -Uri "$repo/$_" -OutFile "$_"
}
