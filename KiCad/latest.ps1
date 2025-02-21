
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

$files = , "kicad-$version-x86_64.exe"

$files | ForEach {
    Write-Host "# $_"
    if (-Not (Test-Path $_)) {
        try {
            $tmpFile = "dl_$_"
            Invoke-WebRequest -Uri "$repo/$_" -OutFile $tmpFile
            Move-Item -Path $tmpFile -Destination "$_"
        } catch {
            Write-Error "Error: $($_.Exception.Message)"
            break
        }
    }
}
