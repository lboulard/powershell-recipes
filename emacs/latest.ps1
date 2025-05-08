$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# Find latest "release-.*" folder

$IndexURL = "https://mirror.ibcp.fr/pub/gnu/emacs/windows/"
$versionPattern = "^emacs-(?<version>\d+\.\d+(_\d)?)(\.zip|-sha256.+\.txt)(\.sig)?$"

Import-Module lboulard-Recipes

$links = (Invoke-HtmlRequest $IndexURL).Links

$url = [System.Uri]$IndexURL

$files = $links.href | ForEach-Object {
  if ($_ -match "^emacs-(?<major>\d+)") {
    [PSCustomObject]@{
      Folder = $_
      Major  = $Matches.major
    }
  }
} | Sort-Object -Descending -Property Major | Select-Object -First 2 | ForEach-Object {
  $releaseURL = New-Object System.Uri -ArgumentList $url, $_.Folder
  $releases = (Invoke-WebRequest $releaseURL -UseBasicParsing).Links
  $releases.href | ForEach-Object {
    if ($_ -match $versionPattern) {
      # Transformation for sorting release
      #   "x.y"   -> "x.y.0"
      #   "x.y_z" -> "x.y.z"
      $version = $Matches.version
      if ($version.Contains('_')) {
        $version = $version -replace '_', '.'
      } else {
        $version = $version + ".0"
      }
      [PSCustomObject]@{
        URL     = (New-Object System.Uri -ArgumentList $releaseURL, $_)
        Version = [version]$version # transformed version for sorting
        Release = $Matches.version  # original version string
      }
    }
  }
} | Group-Object { "{0:d4}" -f $_.Version.Major } | ForEach-Object {
  $_.Group | Group-Object {
    $v = $_.Version
    "{0:d4}.{1:d4}.{2:d4}" -f $v.Major, $v.Minor, $v.Build
  } | Sort-Object -Descending Name | Select-Object -First 1
} | Select-Object -ExpandProperty "Group" | ForEach-Object {
  $private:url = $_.URL
  $name = $private:url.Segments[-1]
  "$($private:url)#emacs-$($_.Release)/${name}"
}

if (-not $files) {
  throw "no releases found"
}

Get-Url $files
