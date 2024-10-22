$ErrorActionPreference = "Stop"

# for Linux, use "linux-glibc", "linux-musl" or "linux-uclibc"
# for MacOS, use "macos"

$packages = @{
  "windows" = @{
    8  = @{
      OperatingSystems = @("windows")
      Architectures    = @("x86", "amd64")
      PackageTypes     = @("jre", "jdk")
      ArchiveTypes     = @("msi", "zip")
    }
    11 = @{
      OperatingSystems = @("windows")
      Architectures    = @("amd64")
      PackageTypes     = @("jdk")
      ArchiveTypes     = @("msi", "zip")
    }
    17 = @{
      OperatingSystems = @("windows")
      Architectures    = @("x86", "amd64")
      PackageTypes     = @("jre", "jdk")
      ArchiveTypes     = @("msi", "zip")
    }
    21 = @{
      OperatingSystems = @("windows")
      Architectures    = @("amd64")
      PackageTypes     = @("jdk")
      ArchiveTypes     = @("msi", "zip")
    }
  }

  # prefix with '#' to ignore entry
  "#linux"  = @{
    8  = @{
      OperatingSystems = @("linux-glibc")
      Architectures    = @("amd64", "aarch64")
      PackageTypes     = @("jdk")
      ArchiveTypes     = @("tar.gz")
      Prefix           = "linux/"
    }
    17 = @{
      OperatingSystems = @("linux-glibc")
      Architectures    = @("amd64", "aarch64")
      PackageTypes     = @("jdk")
      ArchiveTypes     = @("deb")
      Prefix           = "linux/"
    }
  }
}


function AzulMetadata {
  param(
    [int]$JavaMajor
  )
  $api_url = "https://api.azul.com/metadata/v1/zulu/packages/"
  $query = @(
    "availability_types=ca"
    "product=zulu"
    "java_version=" + $JavaMajor
    "release_type=PSU"
    "latest=true"
    "page_size=1000"
    "include_fields=os,lib_c_type,arch,hw_bitness,java_package_type,archive_type,javafx_bundled,sha256_hash"
  ) -Join "&"
  $response = Invoke-WebRequest "${api_url}?${query}"
  if ($response.StatusCode -eq 200) {
    $response.Content | ConvertFrom-Json
  } else {
    Write-Error "metadata: $($response.StatusCode), $($response.StatusDescription)"
  }
}

New-Variable AzulArch -Option Constant -Value @{
  x86_32  = "x86"
  x86_64  = "amd64"
  arm_32  = "aarch32"
  arm_64  = "aarch64"
  mips_32 = "mips"
  mips_64 = "mips64"
  ppc_32  = "ppc"
  ppc_64  = "ppc64"
}

function ToNamedArch {
  param($arch, $hw_bitness)

  $t = $arch + "_" + $hw_bitness
  if ($AzulArch.Contains($t)) {
    return $AzulArch[$t]
  }
  return $arch + "-" + $hw_bitness
}

function ZuluFilter {
  param(
    [Parameter(Mandatory)]
    $AzulResponse,

    [Parameter(Mandatory)]
    $Config
  )

  if ($Config) {
    $operatingSystems = $Config.OperatingSystems
    $architectures = $Config.Architectures
    $packageTypes = $Config.PackageTypes
    $archiveTypes = $Config.ArchiveTypes
    $prefix = $Config.Prefix
  }

  if ($null -eq $operatingSystems) { $operatingSystems = @() }
  if ($null -eq $architectures) { $architectures = @() }
  if ($null -eq $packageTypes) { $packageTypes = @() }
  if ($null -eq $archiveTypes) { $archiveTypes = @() }
  if ($null -eq $prefix) { $prefix = "" }

  # filter based on arguments
  $AzulResponse = $AzulResponse | Where-Object {
    $json = $_
    if (($null -eq $json.latest) -or $json.latest) {
      $os = if ($json.lib_c_type) { $json.os + "-" + $json.lib_c_type } else { $json.os }
      $arch = ToNamedArch $json.arch $json.hw_bitness

      $isOS = $operatingSystems.Contains($os)
      $isArchitecture = $architectures.Contains($arch)
      $isPackageType = $packageTypes.Contains($json.java_package_type)
      $isArchiveType = $archiveTypes.Contains($json.archive_type)

      $isOS -and $isArchitecture -and $isPackageType -and $isArchiveType
    }
  }

  # only keep really last version
  $AzulResponse = $AzulResponse | Group-Object -Property os, arch, hw_bitness, java_package_type, { $_.java_version[0] }, javafx_bundled, archive_type | ForEach-Object {
    $_.Group | Sort-Object -Property ZuluRelease -Descending | Select-Object -First 1
  }

  $AzulResponse | ForEach-Object {
    $json = $_
    $name = ([string]$json.name)
    $packageType = $json.java_package_type.ToLower()
    $arch = ToNamedArch $json.arch $json.hw_bitness

    $url = $json.download_url
    $major = $json.java_version[0]
    $folderArch = "${prefix}${packageType}${major}"
    if ($arch -ne "amd64") { $folderArch = "${folderArch}/${arch}" }

    "${url}#${folderArch}/${name}"
  }
}

$files = $packages.Keys | Sort-Object -Descending | ForEach-Object {
  $downloadProfile = $_

  # ignore profile starting by '#' char
  if ($downloadProfile -and ($downloadProfile[0] -ne "#")) {
    $packages[$downloadProfile].Keys | Sort-Object | ForEach-Object {
      $javaMajor = $_
      $metadata = AzulMetadata $javaMajor
      if ($metadata) {
        ZuluFilter -AzulResponse $metadata -Config $packages[$downloadProfile][$javaMajor]
      } else {
        Write-Host "no metadata for $javaMajor"
      }
    }
  }
}

if (-not $files) {
  Throw "no download candidates found"
}

Import-Module lboulard-Recipes

Get-Url $files
