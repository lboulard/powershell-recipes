function canProgress {
  [System.Console]::IsOutputRedirected -eq $false -and
  $Host.Name -ne 'Windows PowerShell ISE Host'
}

function Start-Download ($url, $to, $headers) {
  $progress = canProgress

  try {
    $url = handle_special_urls $url
    Invoke-Download $url $to $header $progress
  } catch {
    $e = $_.exception
    if ($e.Response.StatusCode -eq 'Unauthorized') {
      warn 'Token might be misconfigured.'
    }
    if ($e.innerexception) { $e = $e.innerexception }
    throw $e
  }
}

# download with file size and progress indicator
function Invoke-Download ($url, $to, $headers, $progress) {

  $reqUrl = ($url -split '#')[0]
  $wreq = [Net.WebRequest]::Create($reqUrl)

  $wreq.UserAgent = Get-UserAgent
  if (-not ($url -match 'sourceforge\.net' -or $url -match 'portableapps\.com')) {
    $wreq.Referer = strip_filename $url
  }
  if ($url -match 'api\.github\.com/repos') {
    $wreq.Accept = 'application/octet-stream'
    $wreq.Headers['Authorization'] = "Bearer $(Get-GitHubToken)"
    $wreq.Headers['X-GitHub-Api-Version'] = '2022-11-28'
  }
  if ($headers) {
    foreach ($header in $headers.Keys) {
      $wreq.Headers[$header] = $headers[$header]
    }
  }

  try {
    $wres = $wreq.GetResponse()
  } catch [System.Net.WebException] {
    $exc = $_.Exception
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

    Invoke-Download $newUrl $to $cookies $progress
    return
  }

  $total = $wres.ContentLength
  $lastModifiedHeader = $wres.Headers.Get("Last-Modified")
  if ($lastModifiedHeader) {
    $lastModifiedDate = [System.DateTime]::Parse($lastModifiedHeader)
  }

  if ($progress -and ($total -gt 0)) {
    [console]::CursorVisible = $false
    function Trace-DownloadProgress ($read) {
      Write-DownloadProgress $read $total $url
    }
  } else {
    Write-Host "Downloading $url ($(filesize $total))..."
    function Trace-DownloadProgress {
      #no op
    }
  }

  try {
    $s = $wres.GetResponseStream()
    $fs = [IO.File]::OpenWrite($to)
    $buffer = New-Object byte[] 2048
    $totalRead = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    Trace-DownloadProgress $totalRead
    while (($read = $s.Read($buffer, 0, $buffer.Length)) -gt 0) {
      $fs.Write($buffer, 0, $read)
      $totalRead += $read
      if ($sw.ElapsedMilliseconds -gt 100) {
        $sw.Restart()
        Trace-DownloadProgress $totalRead
      }
    }
    $sw.Stop()
    Trace-DownloadProgress $totalRead

  } finally {
    if ($progress) {
      [System.Console]::CursorVisible = $true
      Write-Host
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

function Format-DownloadProgress ($url, $read, $total, $console) {
  $filename = url_remote_filename $url

  # calculate current percentage done
  $p = [math]::Round($read / $total * 100, 0)

  # pre-generate LHS and RHS of progress string
  # so we know how much space we have
  $left = "$filename ($(filesize $total))"
  $right = [string]::Format('{0,3}%', $p)

  # calculate remaining width for progress bar
  $midwidth = $console.BufferSize.Width - ($left.Length + $right.Length + 8)

  # calculate how many characters are completed
  $completed = [math]::Abs([math]::Round(($p / 100) * $midwidth, 0) - 1)

  # generate dashes to symbolise completed
  if ($completed -gt 1) {
    $dashes = [string]::Join('', ((1..$completed) | ForEach-Object { '=' }))
  }

  # this is why we calculate $completed - 1 above
  $dashes += switch ($p) {
    100 { '=' }
    default { '>' }
  }

  # the remaining characters are filled with spaces
  $spaces = switch ($dashes.Length) {
    $midwidth { [string]::Empty }
    default {
      [string]::Join('', ((1..($midwidth - $dashes.Length)) | ForEach-Object { ' ' }))
    }
  }

  "$left [$dashes$spaces] $right"
}

function Write-DownloadProgress ($read, $total, $url) {
  $console = $host.UI.RawUI
  $left = $console.CursorPosition.X
  $top = $console.CursorPosition.Y
  $width = $console.BufferSize.Width

  if ($read -eq 0) {
    $maxOutputLength = $(Format-DownloadProgress $url 100 $total $console).length
    if (($left + $maxOutputLength) -gt $width) {
      # not enough room to print progress on this line
      # print on new line
      Write-Host
      $left = 0
      $top = $top + 1
      if ($top -gt $console.CursorPosition.Y) { $top = $console.CursorPosition.Y }
    }
  }

  Write-Host $(Format-DownloadProgress $url $read $total $console) -NoNewline
  [System.Console]::SetCursorPosition($left, $top)
}

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
    $hasUserAgent = $Headers.Contains('User-Agent')
    $config = Get-RecipesConfig

    $UrlList | ForEach-Object {
      $url = [System.Uri]($_)
      $src = $url.AbsoluteUri
      if ($url.Fragment -and ($url.Fragment.Length -gt 1)) {
        $dest = [Uri]::UnescapeDataString($url.Fragment.Substring(1))
      } else {
        $dest = [Uri]::UnescapeDataString($url.Segments[-1])
      }

      if (!$hasUserAgent) {
        $Headers['User-Agent'] = $config.GetUserAgent($src)
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
          Start-Download $src $tmpFile $Headers
          Move-Item -Path $tmpFile -Destination $dest
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
    [ScriptBlock]$FileSelection = {},
    [ScriptBlock]$NameMangle = {}
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

  $files = $FileSelection.InvokeWithContext($null, $vars) | ForEach-Object {
    $varsWithName = $vars + @([psvariable]::new('name', $_))
    $name = $NameMangle.InvokeWithContext($null, $varsWithName)
    if ($name -and ($name -ne $_)) {
      "$repo/$_#$name"
    } else {
      "$repo/$_"
    }
  }
  if ($files) {
    Get-Url $files
  }
}
