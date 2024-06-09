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

# dear user, check API key exists with 'cmdkey.exe /list:git:https://github.com'

function Get-GitHubToken {
  param (
    [string]$TargetName = "git:https://github.com",
    [string]$EnvName = "GITHUB_TOKEN",
    [bool]$Required = $False
  )

  $githubToken = [Environment]::GetEnvironmentVariable($EnvName)
  if ($githubToken) {
    return $githubToken
  } else {
    # Get the GitHub API token from Windows Credential for git
    try {
      $githubToken = [CredentialManager]::GetCredential($TargetName)
      return $githubToken
    } catch {
      Write-Error $_.Exception.Message
      return $null
    }
  }
  if ($Required) {
    throw "GitHub token missing, failure can be expected"
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

function Invoke-GitHubApi() {
  param(
    [string]$Url,
    [string]$Token,
    [hashtable]$Headers = $null
  )

  if ($Headers -eq $null) {
    $Headers = @{}
  }
  if (-not $Headers.Contains('Accept')) {
    $Headers.Add('Accept', 'application/vnd.github+json')
  }
  if (-not $Headers.Contains('X-GitHub-Api-Version')) {
    $Headers.Add('X-GitHub-Api-Version', '2022-11-28')
  }
  if ($Token) {
    $Headers.Add('Authorization', 'token ' + $Token)
  }

  # on error, use a backoff distribution delay on retry
  $retryDelay = 2 # seconds
  $retryCount = 0
  $maxTry = 5

  # maximum 5 tentatives
  while ($retryCount -lt $maxTry) {

    # Invoke-WebRequest mess
    Write-Verbose "GitHub API: ${Url}"
    if ($psVersion.Major -eq 5) {
      $response = try {
     (Invoke-WebRequest  -Uri $Url -Headers $Headers -UseBasicParsing -ErrorAction Stop).BaseResponse
      } catch [System.Net.WebException] {
        Write-Verbose "An exception was caught: $($_.Exception.Message)"
        $_.Exception.Response
      }
    } else {
      $response = Invoke-WebRequest  -Uri $Url -Headers $Headers -UseBasicParsing -ErrorAction SilentlyContinue -SkipHttpErrorCheck
    }
    $statusCode = [int]$response.StatusCode

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

# Convert GitHub Link header into a hashtable with next/first/last/prev as key to url
function Get-GitHubLinks() {
  $args -split ',\s*' | ForEach-Object {
    , $($_ -split ';\s*')
  } | ForEach-Object {
    $url = if ($_[0] -match '<(.*?)>') { $Matches[1] }
    $rel = if ($_[1] -match 'rel="([^"]*?)"') { $Matches[1] }
    if ($rel -and $url) { @{ $rel = $url } }
  }
}

function Get-GitHubReleases() {
  param(
    [Parameter(Mandatory)]
    [string]$Project,
    [string]$Token,
    [int]$MaxPages = 5,
    [ScriptBlock]$Begin = {},
    [ScriptBlock]$Process = { param($release) },
    [ScriptBlock]$End = {},
    [ScriptBlock]$Continue = { param($release) $True }
  )

  try {
    . $Begin
    # initial URL to start finding releases.
    # Query "per_page" for pagination is kept in link header response
    $url = "https://api.github.com/repos/$Project/releases?per_page=25"

    $pageNumber = 0
    while ($url -and ($pageNumber -lt $MaxPages)) {
      $pageNumber += 1
      Write-Verbose "GitHub releases page ${pageNumber}/${maxPages}"
      $result = Invoke-GitHubApi -Url $url -Token $githubToken
      $link = Get-GitHubLinks ($result.Headers['Link'])
      $next = if ($link) { $link.next }

      if ($result -and $result.Content) {
        $result.Content | ConvertFrom-Json | ForEach-Object {
          Write-Verbose "Release tag: $($_.tag_name)"
          . $Process($_)
          if (-not (. $continue($_))) {
            break
          }
        }
      }

      # next page of releases
      $url = $next
    }
  } finally {
    . $End
  }
}

function Find-GitHubRelease() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Project,
    [Parameter(Mandatory, Position = 1)]
    [string]$TagPattern,
    [string]$Token,
    [int]$MaxPages = 5,
    [bool]$PreRelease = $False,
    [ScriptBlock]$ReleaseScript = { param($release) },
    [ScriptBlock]$Filter = {}
  )

  Get-GitHubReleases -Project $project -Token $githubToken -MaxPages $MaxPages -Begin {
    $found = $False
  } -Continue {
    -not $found
  } -Process {
    param($release)

    #Write-Host "Release tag: $($release.tag_name)"
    . $ReleaseScript($release)

    # ignore prerelease
    if ($release.prerelease -and (-not $PreRelease)) {
      Write-Verbose "Release tag: $($_.tag_name), ignore pre-release"
      return
    }

    if ($release.tag_name -match $TagPattern) {
      $tag = if ($Matches.Contains('tag')) { $Matches.tag } else { $Matches.0 }
      $version = $Matches.version
      $vars = @(
        [psvariable]::new('release', $release)
        [psvariable]::new('tag', $tag)
        [psvariable]::new('version', $version)
      )
      Write-Verbose "Release tag: $($_.tag_name), version ${version}"

      $result = $Filter.InvokeWithContext($null, $vars)
      if ($result) {
        $found = $True
        $result
      }
    }
  }
}

function Find-GitHubReleaseFromAsset() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Project,
    [Parameter(Mandatory, Position = 1)]
    [string]$TagPattern,
    [Parameter(Mandatory, Position = 2)]
    [string]$AssetPattern,
    [string]$Token,
    [int]$MaxPages = 5,
    [bool]$PreRelease = $False,
    [ScriptBlock]$ReleaseScript = { param($release) },
    [ScriptBlock]$NameMangle = {}
  )

  Find-GitHubRelease -Project $Project -TagPattern $TagPattern `
    -MaxPages $MaxPages -ReleaseScript $ReleaseScript -Filter {
    $release.assets | ForEach-Object {
      $asset = $_
      $name = $asset.name
      if ($name -match $AssetPattern) {
        if ($NameMangle) {
          $vars = @(
            [psvariable]::new('release', $release)
            [psvariable]::new('tag', $tag)
            [psvariable]::new('version', $version)
            [psvariable]::new('name', $name)
          )
          $name = $NameMangle.InvokeWithContext($null, $vars)
        }
        "$($asset.browser_download_url)#${name}"
      }
    }
  }
}

function Find-GitHubAssets() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Project,
    [Parameter(Mandatory, Position = 1)]
    [string]$Tag,
    [Parameter(Mandatory, Position = 2)]
    [string]$Version,
    [Parameter(Mandatory, Position = 3)]
    [string]$AssetPattern,

    [string]$Token,
    [ScriptBlock]$NameMangle = {}
  )

  $json = Invoke-GitHubApi -Url "https://api.github.com/repos/$Project/releases/tags/$Tag" -Token $Token
  $release = $json.Content | ConvertFrom-Json
  if ($release) {
    $release.assets | ForEach-Object {
      $asset = $_
      $name = $asset.name
      if ($name -match $AssetPattern) {
        Write-Verbose "GitHub Asset: name=${name}"
        if ($NameMangle) {
          $vars = @(
            [psvariable]::new('release', $release)
            [psvariable]::new('tag', $Tag)
            [psvariable]::new('version', $version)
            [psvariable]::new('name', $name)
          )
          $name = $NameMangle.InvokeWithContext($null, $vars)
        }
        "$($asset.browser_download_url)#${name}"
      }
    }
  }
}

function Get-GitHubLatestReleaseUrl() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Project
  )

  $lastReleaseURL = "https://github.com/$Project/releases/latest"
  try {
    $response = (Invoke-WebRequest -Method Head -Uri $lastReleaseURL -ErrorAction Ignore).BaseResponse
    $statusCode = $response.StatusCode
    Write-Verbose ("`$statusCode={0}" -f $statusCode)
  } catch {
    Write-Verbose $_.Exception
    $statusCode = [int]$_.Exception.Response.StatusCode
  }
  if ($statusCode -eq 302) {
    $lastVersionURL = $response.Headers.Location
  } elseif ($statusCode -eq 200) {
    if ($response.ResponseUri) {
      # PS5.1
      $lastVersionURL = $response.ResponseUri.AbsoluteUri
      Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
    } elseif ($response.RequestMessage.RequestUri) {
      # PS7
      $lastVersionURL = $response.RequestMessage.RequestUri.AbsoluteUri
      Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
    } else {
      throw "I do not known how to read response of Invoke-WebRequest"
    }
  } else {
    Write-Error ("HTTP Response {0}: {1}" -f $statusCode, $response.StatusDescription)
    throw ("unexpected response {0} for {1}" -f $statusCode, $lastReleaseURL)
  }

  $lastVersionURL
}
