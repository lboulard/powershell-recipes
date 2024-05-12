$repo="https://frippery.org/files/busybox"
$version="5236-g7dff7f376"

$files = , "busybox-w32-FRP-$version.exe"
$files += "busybox-w32-FRP-$version.exe.sig"
$files += "busybox-w64-FRP-$version.exe"
$files += "busybox-w64-FRP-$version.exe.sig"
$files += "busybox-w64u-FRP-$version.exe"
$files += "busybox-w64u-FRP-$version.exe.sig"

New-Item -ItemType Directory -Path "$version" -Force | Out-Null

$files | ForEach {
  Write-Host "# $_"
  iwr -Uri "$repo/$_" -OutFile "$version/$_"
}

Write-Host "# man1/busybox-$version.1.gz"
iwr -Uri "$repo/busybox.1.gz" -OutFile "man1/busybox-$version.1.gz"
