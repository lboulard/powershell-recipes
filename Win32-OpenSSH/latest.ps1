$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# tag: v9.5.0.0p1-Beta / release: OpenSSH-Win64-v9.5.0.0.msi
$tagPattern = "(?<revision>v(?<version>\d+\.\d+(\.\d+)+)).*"
$project = "PowerShell/Win32-OpenSSH"

Import-Module lboulard-Recipes

Get-GitHubAssetsOfLatestRelease $project $tagPattern -ProjectName win32-openssh -FileSelection {
  # very ugly but does the job
  $global:revision = $revision
  @(
    "OpenSSH-Win64-$revision.msi"
    "OpenSSH-Win64.zip#OpenSSH-Win64-$revision.zip"
  )
}

if (!$error) {
  $location = (Get-RecipesConfig).GetFetchLocation('win32-openssh')
  try {
    $formerLocation = Get-Location
    Set-Location $location
    @(
    ("OpenSSH-Win64.msi", "OpenSSH-Win64-$revision.msi"),
    ("OpenSSH-Win64.zip", "OpenSSH-Win64-$revision.zip")
    ) | ForEach-Object {
      try {
        $link = $_[0]
        $path = $_[1]
        $updated = (Update-HardLink $path $link -CreateIfAbsent).Updated
        Write-Host "hardlink: $link -> $path" -NoNewline
        Write-Host $(if ($updated) { "" } else { " (nochange)" })
      }
      catch {
        Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
        break
      }
    }
  }
  finally {
    if ($formerLocation) {
      Set-Location $formerLocation
    }
  }
}
