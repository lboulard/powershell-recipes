$ErrorActionPreference = "Stop"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

# https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.0/LLVM-19.1.0-win64.exe
# https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.0/LLVM-19.1.0-Windows-X64.tar.xz
# https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.6/clang+llvm-19.1.6-x86_64-pc-windows-msvc.tar.xz

$project = "llvm/llvm-project"
$tagPattern = "(?<tag>llvmorg-(?<version>\d+\.\d+(\.\d+)+))"
$wanted = @(
  "^LLVM-\d+(.\d+)+-[wW]in(dows-[xX])?64(\.exe|\.tar\..+)(\.sig|\.asc)?$"
  "^clang\+llvm-\d+(.\d+)+-x86_64-pc-windows-msvc(?:\.7z|\.tar\.xz)(?:\.sig)?$") -join "|"

$nameMangle = {
  # manipulate $name, $version and $tag are accessible from tag pattern parsing
  Write-Verbose "`$name='$name', `$version='$version'"
  "LLVM-${version}/${name}"
}

Import-Module lboulard-Recipes

$githubToken = Get-GitHubToken
if (-not $githubToken) {
  Write-Warning "GitHub token missing, failure or long delay can be expected"
}

# parse all request until we find a release that match wanted files

$files = Find-GitHubReleaseFromAsset $project $tagPattern $wanted -Token $githubToken -ReleaseScript {
  param($release)
  Write-Host "Release tag: $($release.tag_name)"
} -NameMangle $nameMangle

if (-not $files) {
  Write-Error "no files found"
  exit 1
}

$headers = @{
  'Accept'        = 'application/octet-stream'
  'Authorization' = 'token ' + $githubToken
}

Get-Url $files -Headers $headers -ProjectName llvm
