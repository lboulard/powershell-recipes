# PowerShell 5 and 7
# find Erlang installers using GitHub API only walking releases

$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$branch = "27|28"

# https://github.com/erlang/otp/releases/download/OTP-28.1/otp_win64_28.1.exe
# https://github.com/erlang/otp/releases/download/OTP-28.1/otp_win64_28.1.zip
# https://github.com/erlang/otp/releases/download/OTP-28.1/otp_doc_html_28.1.tar.gz
# https://github.com/erlang/otp/releases/download/OTP-28.1/otp_doc_html_28.1.tar.gz.sigstore

$tagPattern = "OTP-(?<version>(?:${branch})(?:\.\d+){0,3})$"
$binaries = "otp_win64_(?:\d+(?:\.\d+){1,3})\.(exe|zip)"
$docs = "otp_doc_html_(?:\d+(?:\.\d+){1,3})\.tar\.gz(?:\.sigstore)?"
$wanted = "^(?:${binaries}|${docs})$"
$project = "erlang/otp"


Import-Module lboulard-Recipes

# filenames are not enough to find release files
# use GitHub API

$githubToken = Get-GitHubToken
if (-not $githubToken) {
  Write-Warning "GitHub token missing, failure or long delay can be expected"
}

# parse all request until we find a release that match wanted files

$allBranch = ($branch -split "\|" | Sort-Object -Unique)

$found = @()
$files = Find-GitHubReleaseFromAsset $project $tagPattern $wanted -Token $githubToken -ReleaseScript {
  param($release)
  Write-Host "Release tag: $($release.tag_name)"
} -NameMangle {
  # man$foundipulate $name, $version and $tag are accessible from tag pattern parsing
  Write-Verbose "`$name='$name', `$version='$version'"
  $version -match "^\d+\.\d+" | Out-Null
  "erlang-$($matches[0])/${name}"
} -Continue {
  $r = if ($release.tag_name -match "\d+") { $matches[0] }
  if ($r) {
    $found = (@($found) + @($r) | Sort-Object -Unique)
    (Compare-Object $found $allBranch).SideIndicator -ne $null
  } else {
    $true
  }
}

$files = $files | ForEach-Object {
  $uri = [Uri]$_
  $tag = $uri.Segments[-2].TrimEnd("/")
  if ($tag -match $tagPattern) {
    $version = $Matches.version
    $tag -match "\d+" | Out-Null
    [PSCustomObject]@{
      Uri     = $uri
      Main    = $Matches[0]
      Version = $version
      Tag     = $tag
    }
  }
} | Group-Object -Property Main | ForEach-Object {
  $head = $_.Group | Group-Object -Property Version | Sort-Object -Property { [Version]$_.Name } -Descending | Select-Object -First 1
  [PSCustomObject]@{
    Main  = $_.Name
    Group = $head.Group
  }
} | ForEach-Object {
  $_.Group.Uri.OriginalString
}

if (-not $files) {
  Write-Error "no files found"
  exit 1
}

$headers = @{
  'Accept'        = 'application/octet-stream'
  'Authorization' = 'token ' + $githubToken
}

Get-Url $files -Headers $headers -ProjectName erlang