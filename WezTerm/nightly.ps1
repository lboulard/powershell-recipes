$ErrorActionPreference = "Stop"

# Find latest release of nightly build

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$project = "wez/wezterm"

Import-Module lboulard-Recipes

$token = Get-GitHubToken
$files = Find-GitHubAssets $project `
  -Tag "nightly" `
  -Version "nightly" `
  -Token $token `
  -AssetPattern '(-windows-nightly\.zip|nightly-setup\.exe)(\.sha256)?$' `
  -NameMangle { "${tag}/${name}" }


function Read-ContentDispositionFilename($contentDisposition) {
  $f = $contentDisposition -Split ";"
  foreach ($item in $f) {
    $item = $item.Trim()
    if ($item.StartsWith("filename=")) {
      $value = $item.SubString(9)
      if ($value) {
        if ($value[0] -eq '"') {
          $value = $value.Substring(1, -1)
        }
        $filename = $value
      }
    } elseif ($item.StartsWith("filename*=")) {
      $value = $item.SubString(10)
      if ($value) {
        $items = $value -Split "'"
        if ($items.length -eq 3) {
          $encoding, $lang, $value = $items
          if ($value -and $value[0] -eq '"') {
            $value = $value.Substring(1, -1)
          }
          if ($encoding.ToUpper() -eq "UTF-8" -and $value) {
            $filenameEncoded = [URI]::UnescapeDataString($value)
          }
        }
      }
    }
  }

  if ($filenameEncoded) {
    return $filenameEncoded
  } elseif ($filename) {
    return $filename
  } else {
    return $null
  }
}

# Unlike url_filename which can be tricked by appending a
# URL fragment (e.g. #/dl.7z, useful for coercing a local filename),
# this function extracts the original filename from the URL.
function url_remote_filename($url) {
  $uri = (New-Object URI $url)
  $basename = Split-Path $uri.PathAndQuery -Leaf
  If ($basename -match ".*[?=]+([\w._-]+)") {
    $basename = $matches[1]
  }
  If (($basename -notlike "*.*") -or ($basename -match "^[v.\d]+$")) {
    $basename = Split-Path $uri.AbsolutePath -Leaf
  }
  If (($basename -notlike "*.*") -and ($uri.Fragment -ne "")) {
    $basename = $uri.Fragment.Trim('/', '#')
  }
  return $basename
}

function filesize($length) {
  $gb = [int64]1000000000
  $mb = [int64]1000000
  $kb = [int64]1000

  if ($length -gt $gb) {
    "{0:n1}GB" -f ($length / $gb)
  } elseif ($length -gt $mb) {
    "{0:n1}MB" -f ($length / $mb)
  } elseif ($length -gt $kb) {
    "{0:n1}KB" -f ($length / $kb)
  } else {
    if ($null -eq $length) {
      $length = 0
    }
    "$($length) B"
  }
}

function file_up_to_date($dest, $size, $lastModified) {
  $fileInfo = [System.IO.FileInfo]::new($dest)
  if ($fileInfo.Exists) {
    if ($fileInfo.Length -eq $size) {
      if ($lastModified) {
        return $fileInfo.LastWriteTime -ge $lastModified
      }
      return $true
    }
  }
  return $false
}

function last_modifed_time($dest) {
  $fileInfo = [System.IO.FileInfo]::new($dest)
  if ($fileInfo.Exists) {
    return $fileInfo.LastWriteTimeUtc.ToString("ddd, dd MMM yyyy HH:mm:ss \G\M\T")
  }
  return $null
}

# download with file size and progress indicator
function Invoke-Download ($url, $to, $headers, $progress, $outdir) {

  $reqUrl = ($url -split '#')[0]
  $wreq = [Net.WebRequest]::Create($reqUrl)

  if (-not $to) {
    $reqName = ($url -split '#')[1]
    if ($reqName) {
      $to = $reqName.Trim("/")
      if ($to -and $outdir) {
        $to = Join-Path $outdir $to
      }
    }
  }

  if ($to -and ($headers -notcontains "If-Modified-Since")) {
    $lastModifiedDate = last_modifed_time $to
    if ($lastModifiedDate) {
      if ($null -eq $headers) {
        $headers = @{}
      }
      $headers["If-Modified-Since"] = $lastModifiedDate
    }
  }

  # $wreq.UserAgent = Get-UserAgent
  if ($headers) {
    foreach ($header in $headers.Keys) {
      $wreq.Headers[$header] = $headers[$header]
    }
  }

  try {
    $wres = $wreq.GetResponse()
  } catch [System.Net.WebException] {
    $exc = $_.Exception

    # On presence of If-Modified-Since header, we can receive 304 response
    if ($exc.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotModified) {
      Write-Host "Downloading $url"
      if ($to) {
        Write-Host " # $to (not modified)"
      } else {
        Write-Host " # Not modified"
      }
      return
    }

    $handledCodes = @(
      [System.Net.HttpStatusCode]::MovedPermanently, # HTTP 301
      [System.Net.HttpStatusCode]::Found, # HTTP 302
      [System.Net.HttpStatusCode]::SeeOther, # HTTP 303
      [System.Net.HttpStatusCode]::TemporaryRedirect  # HTTP 307
    )

    # Only handle redirection codes
    $redirectRes = $exc.Response
    if ($handledCodes -notcontains $redirectRes.StatusCode) {
      throw $exc
    }

    # Get the new location of the file
    if ((-not $redirectRes.Headers) -or ($redirectRes.Headers -notcontains 'Location')) {
      throw $exc
    }

    $newUrl = $redirectRes.Headers['Location']
    Write-Host "Following redirect to $newUrl..."

    # Handle manual file rename
    if ($url -like '*#/*') {
      $null, $postfix = $url -split '#/'
      $newUrl = "$newUrl#/$postfix"
    }

    Invoke-Download $newUrl $to $headers $progress $outdir
    return
  }

  if (-not $to) {
    $contentDisposition = $wres.Headers['Content-Disposition']
    if ($contentDisposition) {
      $filename = Read-ContentDispositionFilename $contentDisposition
      $to = ($filename.Trim(".") -split "/")[-1]
    }
    if (-not $to) {
      $to = url_remote_filename "$url"
    }
    if (-not $to) {
      throw "failed to obtain a filename"
    }
    if ($outdir) {
      $to = Join-Path $outdir $to
    }
  }

  $total = $wres.ContentLength
  $lastModifiedHeader = $wres.Headers.Get("Last-Modified")
  if ($lastModifiedHeader) {
    $lastModifiedDate = [System.DateTime]::Parse($lastModifiedHeader)
  } else {
    $lastModifiedDate = $null
  }

  Write-Host "Downloading $url ($(filesize $total))..."
  # if ($url -cne $wres.ResponseUri) {
  #   Write-Host " ->" $wres.ResponseUri
  # }
  if ($progress -and ($total -gt 0)) {
    [console]::CursorVisible = $false
    function Trace-DownloadProgress ($read, $last = $false) {
      & $progress $read $total $to $last
    }
  } else {
    function Trace-DownloadProgress {
      #no op
    }
  }

  Write-Host " # ${to}"
  if ($lastModifiedDate) {
    Write-Host " # Last modified time: $lastModifiedDate"
  }
  
  if ($outdir) {
    if (-not (Test-Path $outdir -PathType Container)) {
      New-Item -Path $outdir -ItemType Container | Out-Null
    }
  }

  if ($total -gt 0) {
    if (file_up_to_date $to $total $lastModifiedDate) {
      $wres.GetResponseStream().Close()
      $wres.Close()
      return
    }
  }

  try {

    $s = $wres.GetResponseStream()
    $fs = [IO.File]::OpenWrite($to)
    $buffer = New-Object byte[] 4096
    $totalRead = 0

    Trace-DownloadProgress $totalRead
    while (($read = $s.Read($buffer, 0, $buffer.Length)) -gt 0) {
      $fs.Write($buffer, 0, $read)
      $totalRead += $read
      Trace-DownloadProgress $totalRead
    }

  } finally {
    if ($progress) {
      if ($totalRead -lt $total) {
        Trace-DownloadProgress $totalRead $true
      }
      Write-Host "`n"
      [System.Console]::CursorVisible = $true
    }
    if ($totalRead -gt $total) {
      @(
        " ** WARNING more data than expected`n"
        "    $totalRead bytes read ($(filesize $totalRead))"
        ", expected $read bytes ($(filesize $tota))") | Write-Host
    }

    if ($fs) {
      $fs.Close()

      if ($lastModifiedDate) {
        try {
          [System.IO.File]::SetLastWriteTime($to, $lastModifiedDate)
        } catch {
          Write-Error "Date: '$lastModified'"
          Write-Error "$($_.Exception.Message)"
        }
      }
    }
    if ($s) {
      $s.Close()
    }
    $wres.Close()
  }
}

$script:refreshTime = New-TimeSpan -Start 0
$refreshDelay = [timespan]::FromMilliseconds(1000 / 10)

function progress($length, $size, $prefix, $last = $false) {
  if ($length -ge $size) { $last = $true }
  if (-not $last) {
    $time = New-TimeSpan -Start 0
    if ($time -lt $refreshTime) {
      return
    }
    $script:refreshTime = $time.Add($refreshDelay)
  }

  @(
    " "
    $prefix
    " {0,7} of {1,7}" -f ($(filesize $length), $(filesize $size))
  ) | Write-Host -NoNewline

  $foreGround = $(if ($length -lt $size) { 'Yellow' } else { 'Green' })
  Write-Host -NoNewline -ForegroundColor $foreGround $(if ($last) {
      "  {0:P} *" -f ($length / $size)
    } else {
      "  {0:P} >" -f ($length / $size)
    }) "`r"
}

function test_progress($prefix, $size, $progress) {
  $i = 0
  try {
    [System.Console]::CursorVisible = $false
    $step = Get-Random -Minimum 3000 -Maximum 5000
    for ($i = 0; $i -lt $size; $i += $step) {
      & $progress $i $size $prefix
      Start-Sleep -Milliseconds ($step / 2000)
      $step = Get-Random -Minimum 3000 -Maximum 5000
    }
    # last display
    if ($i -ge $size) {
      & $progress $size $size $prefix
    }
  } finally {
    # Force refresh when interrupted
    if ($i -lt $size) {
      & $progress $i $size $prefix $true
    }
    Write-Host
    [System.Console]::CursorVisible = $true
  }
}

# test_progress download.zip (1 -shl 21) progress

function canProgress {
  [System.Console]::IsOutputRedirected -eq $false -and
  $Host.Name -ne 'Windows PowerShell ISE Host'
}

$progressFunc = $null
if (canProgress) {
  $progressFunc = $function:progress
}

$location = (Get-RecipesConfig).GetFetchLocation("wezterm")

foreach ($url in $files) {
  Invoke-Download $url $null $null $progressFunc $location
}
