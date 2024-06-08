# PowerShell 5 and 7
# find Ruby 3.2 installer using GitHub API only walking releases

$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
$VerbosePreference = "Continue"

$branch = "3.2"

$tagPattern = "RubyInstaller-(?<version>$([regex]::escape($branch))\.\d+)(\-\d+)?$"
$wanted = "^rubyinstaller-$([regex]::escape($branch))\.\d+.+?-x64\.(exe|7z)(\.asc)?$"
$project = "oneclick/rubyinstaller2"

$nameMangle = {
  # manipulate $name, $version and $tag are accessible from tag pattern parsing
  "${branch}/${name}"
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class CredentialManager {
    [DllImport("advapi32", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("advapi32", SetLastError = true)]
    public static extern void CredFree(IntPtr cred);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public IntPtr TargetName;
        public IntPtr Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public IntPtr TargetAlias;
        public IntPtr UserName;
    }

    public static string GetCredential(string targetName) {
        IntPtr credPtr;
        if (CredRead(targetName, 1, 0, out credPtr)) {
            var credential = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            string password = Marshal.PtrToStringUni(credential.CredentialBlob, credential.CredentialBlobSize / 2);
            CredFree(credPtr);
            return password;
        } else {
            throw new Exception("Failed to retrieve credential from Windows Credential Manager.");
        }
    }
}
"@

# check API key exists with 'cmdkey.exe /list:git:https://github.com'

function Get-GitHubToken {
  param (
    [string]$targetName = "git:https://github.com"
  )

  try {
    $token = [CredentialManager]::GetCredential($targetName)
    return $token
  } catch {
    Write-Error $_.Exception.Message
    return $null
  }
}

# filenames are not enough to find release files
# use GitHub API

$headers = @{
  'Accept'               = 'application/vnd.github+json'
  "X-GitHub-Api-Version" = "2022-11-28"
}

$githubToken = $env:GITHUB_TOKEN
if (-not $githubToken) {
  # Get the GitHub API token from Windows Credential for git
  $githubToken = Get-GitHubToken
  if ($githubToken) {
    $headers['Authorization'] = 'Bearer ' + $githubToken
  } else {
    thow "GitHub token missing, failure can be expected"
  }
} else {
  $headers['Authorization'] = 'token ' + $githubToken
}

# parse all request until we find a release that mathc wanted files

# Convert GitHub Link header into a hashtable with next/first/last/prev as key to url
function Get-GitHub-Pages() {
  $args -split ',\s*' | ForEach-Object {
    , $($_ -split ';\s*')
  } | ForEach-Object {
    $url = if ($_[0] -match '<(.*?)>') { $Matches[1] }
    $rel = if ($_[1] -match 'rel="([^"]*?)"') { $Matches[1] }
    if ($rel -and $url) { @{ $rel = $url } }
  }
}

function Get-HttpHeader($response, [string]$name) {
  $value = $response.Headers[$name]
  # PS7 returns array, PS5 returns string
  if ($value -is [array]) {
    if ($value.Count -ne 1) {
      throw "$value is present more than once in $($response.Headers)"
    }
    $value = $value[0]
  }
  return $value
}

function Trace-RateLimit($response) {
  $delay = 0
  try {
    $limitReset = Get-HttpHeader $response 'X-RateLimit-Reset'
    if ($limitReset) {
      $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
      $rateLimit = [int](Get-HttpHeader $response 'X-RateLimit-Limit')
      $rateRemaining = [int](Get-HttpHeader $response 'X-RateLimit-Remaining')
      Write-Verbose ("" + @(
          "GitHub API Rate: ${rateRemaining}/${rateLimit}"
          "(reset: $([DateTimeOffset]::FromUnixTimeSeconds($limitReset).ToLocalTime()))"
        ) -join " ")
      if ($rateRemaining -le 0) {
        $delay = $limitReset - $now
      }
    }
  } catch {
    Write-Warning "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
  }
  return $delay
}

function Invoke-GitHub-Api([string]$Url, [hashtable]$Headers) {
  # on error, use a backoff distribution delay on retry
  $retryDelay = 2 # seconds
  $retryCount = 0
  $maxTry = 5

  # maximum 5 tentatives
  while ($retryCount -lt $maxTry) {
    $response = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing
    $statusCode = $response.StatusCode

    $delay = Trace-RateLimit $response
    if ($statusCode -eq 200) {
      return $response
    }

    Write-Warning "HTTP Response code: ${statusCode}, $($response.StatusDescription)"

    # always rate limit or delay on any error
    $delay = (($retryDelay, $delay) | Measure-Object -Max).Maximum
    if ($delay -ge 0) {
      $timeSpan = New-TimeSpan -Seconds $delay
      Write-Warning "GitHub API error, sleeping ${timeSpan}"
      Start-Sleep -Seconds $delay
    }

    $retryCount += 1

    if ($statusCode -eq 429) {
      # hit GitHub rate limit, reset backoff
      $retryDelay = 2
      continue
    } elseif ($statusCode -eq 403) {
      # forbidden may be rate limit
    } else {
      throw "HTTP bad response: $($statusCode), $($response.StatusDescription)"
    }

    $retryDelay *= 2
  }
  throw "HTTP retry count ${maxTry} reached"
}

$pagesCount, $maxPages = 0, 5

# initial URL to start finding releases.
# Query "per_page" for pagination is kept in link header response

$url = "https://api.github.com/repos/$project/releases?per_page=25"
while ($url -and ($pagesCount -lt $maxPages)) {
  Write-Host "Read releases ... $(1 + ${pagesCount})/${maxPages}"
  try {
    $result = Invoke-GitHub-Api -Url $url -Headers $headers
    $pagesCount -= 1
    $link = Get-GitHub-Pages ($result.Headers['Link'])
    $next = if ($link) { $link.next }

    $releases = ($result.Content | ConvertFrom-Json) | where {
      Write-Verbose "release: $($_.tag_name)"
      (-not $_.prerelease) -and ($_.tag_name -match $tagPattern)
    } | ForEach-Object {
      $release = $_

      $release.tag_name -match $tagPattern | Out-Null
      $tag = $Matches.0
      $version = $Matches.version

      $files = $release.assets | ForEach-Object {
        $asset = $_
        $name = $asset.name
        if ($name -match $wanted) {
          if ($nameMangle) {
            $name = & $nameMangle
          }
          "$($asset.browser_download_url)#${name}"
        }
      }
      if ($files) {
        break
      }
    }
    if ($files) {
      break
    }

    # next page of releases
    $url = $next
  } catch {
    Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
    break
  }
}

if (-not $files) {
  Write-Error "no files found"
  exit 1
}

$headers['Accept'] = 'application/octet-stream'

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
      $result = Invoke-WebRequest -Uri "$src" -OutFile $tmpFile -Headers $headers -UseBasicParsing -PassThru
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
