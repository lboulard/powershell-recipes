function Get-Url() {
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ParameterSetName = "Url")]
    [string[]]$UrlList,
    [hashtable]$Headers = @{}
  )

  Begin {
    $folders = @{} # remember created folder to create only once
  }

  Process {
    if (-not $UrlList) {
      return
    }

    if (-not $Headers.Contains('Accept')) {
      $headers['Accept'] = 'application/octet-stream'
    }

    $UrlList | ForEach-Object {
      $url = [System.Uri]($_)
      $src = $url.AbsoluteUri
      if ($url.Fragment -and ($url.Fragment.Length -gt 1)) {
        $dest = [System.Web.HttpUtility]::UrlDecode($url.Fragment.Substring(1))
      } else {
        $dest = [System.Web.HttpUtility]::UrlDecode($url.Segments[-1])
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
          $result = Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -Headers $Headers -UseBasicParsing -PassThru
          $lastModified = $result.Headers['Last-Modified']
          # PS7 returns array, PS5 returns string
          if ($lastModified -is [array]) { $lastModified = $lastModified[0] }
          if ($lastModified) {
            try {
              $lastModifiedDate = Get-Date $lastModified
          (Get-Item $tmpFile).LastWriteTimeUtc = $lastModifiedDate
            } catch {
              Write-Error "Date: '$lastModified'"
              Write-Error "$($_.Exception.Message)"
            }
          }
          Move-Item -Path $tmpFile -Destination "$dest"
        } catch {
          Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
          break
        }
      }
    }
  }
}

function Get-GitHubAssetsOfLatestRelease() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Project,
    [Parameter(Mandatory, Position = 1)]
    [string]$tagPattern,
    [ScriptBlock]$FileSelection = {}
  )

  $lastVersionUrl = Get-GitHubLatestReleaseUrl $project

  if ($lastVersionURL) {
    Write-Host "# last Version" $lastVersionURL -Separator "`n"
  } else {
    throw "no release found for ${project}"
  }

  if (-not $TagPattern.StartsWith("/")) {
    $TagPattern = "/(?<tag>${tagPattern})$"
  }

  if ($lastVersionURL -match $tagPattern) {
    $vars = $Matches.GetEnumerator() | ForEach-Object {
      [psvariable]::new($_.key, $_.value)
    }
    if ($Matches.Contains('tag')) {
      $tag = $Matches.tag
    } else {
      $tag = $Matches.0
      $vars += @([psvariable]::new('tag', $tag))
    }
  } else {
    throw "no tag match at ${lastVersionUrl}"
  }

  $repo = "https://github.com/$project/releases/download/$tag"

  $files = $FileSelection.InvokeWithContext($null, $vars) | ForEach-Object { "$repo/$_" }
  if ($files) {
    Get-Url $files
  }
}
