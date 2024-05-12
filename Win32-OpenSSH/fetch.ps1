# tag: v9.5.0.0p1-Beta / release: OpenSSH-Win64-v9.5.0.0.msi
$versionPattern = "/(?<release>(?<revision>v(?<version>\d+\.\d+(\.\d+)+)).*)"
$project = "PowerShell/Win32-OpenSSH"

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
$version = $Matches.version
$revision = $Matches.revision

if ($error) {
  Write-Error "cannot continue, errors occurred"
  exit 1
}

$repo = "https://github.com/$project/releases/download/$release"

$files =,"OpenSSH-Win64-$revision.msi"
$files += "OpenSSH-Win64.zip#OpenSSH-Win64-$revision.zip"

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

if (!$error) {
  $links = (
    ("OpenSSH-Win64.msi","OpenSSH-Win64-$revision.msi"),
    ("OpenSSH-Win64.zip","OpenSSH-Win64-$revision.zip")
  )

  $brokenWarning = $false
  $links | ForEach-Object {
    $link = $_[0]
    $path = $_[1]
    if ((Test-Path $link) -and (Test-Path $path)) {
      $l = (Get-Item -Path $link -Force -ea SilentlyContinue)
      if ($l.LinkType -eq "HardLink") {
        $p = (Get-Item -Path $path -Force -ea SilentlyContinue)
        if ($l.Target -eq $p.FullName) {
          Write-Host "hardlink: $link -> $path (no change)"
          return
        } elseif ((-not $l.Target) -and (-not $brokenWarning)) {
          Write-Error "hardlink support broken on PowerShell 6 and beyond"
          Write-Error "always (re)creating hardlink"
          $brokenWarning = $true
        }
      }
    }

    Write-Host "hardlink: $link -> $path"
    try {
      New-Item -Path $link -Item HardLink -Value $path -Force | Out-Null
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
