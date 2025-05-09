
# exclude 99 minor version, there are development tags
$versionPattern = "/(\d+\.(?!99\.)\d+\.\d+)$"
$project = "KiCad/kicad-source-mirror"

$feedURL = "https://github.com/$project/releases.atom"

$atomFeed = Invoke-RestMethod -Uri $feedURL

$lastVersionURL = $atomFeed.link.href | Where-Object {
    $_ -match $versionPattern
}
if ($lastVersionURL) {
    Write-Host "# last Version`n" ($lastVersionURL -join "`n") -Separator ""
} else {
    throw "no release found at $feedURL"
}

$sortedVersionURL = $lastVersionURL | Sort-Object -Descending -Property {
    $_ -match $versionPattern
    $parts = $Matches[1] -split "\."
    [int[]]$parts
}
Write-Host "# sorted Version`n" ($sortedVersionURL -join "`n") -Separator ""

($sortedVersionURL[0] -match $versionPattern) | Out-Null
$version_path = $Matches[0]
$version = $Matches[1]

$repo = "https://github.com/$project/releases/download$version_path"

$url = , "$repo#kicad-$version-x86_64.exe"

Get-Url $url -ProjectName kicad
