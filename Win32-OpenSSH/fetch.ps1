# tag: v9.5.0.0p1-Beta / release: OpenSSH-Win64-v9.5.0.0.msi
$versionPattern = "/(?<tag>(?<revision>v(?<version>\d+\.\d+(\.\d+)+)).*)"
$project = "PowerShell/Win32-OpenSSH"

$lastReleaseURL = "https://github.com/$project/releases/latest"
try {
  $response = Invoke-WebRequest -Method Head -Uri $lastReleaseURL -ErrorAction Ignore
  $statusCode = $response.StatusCode
  Write-Verbose ("`$statusCode={0}" -f $statusCode)
} catch {
  Write-Verbose $_.Exception
  $statusCode = $_.Exception.Response.StatusCode.value__
}
if ($statusCode -eq 302) {
  $lastVersionURL = $response.Headers.Location
} elseif ($statusCode -eq 200) {
  if ($response.BaseResponse.ResponseUri -ne $null) {
    # PS5.1
    $lastVersionURL = $response.BaseResponse.ResponseUri.AbsoluteUri
    Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
  } elseif ($response.BaseResponse.RequestMessage.RequestUri -ne $null) {
    # PS7
    $lastVersionURL = $response.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
    Write-Verbose ("`$lastVersionURL={0}" -f $lastVersionURL)
  }
} else {
  Write-Error ("HTTP Response {0}: {1}" -f $statusCode, $response.StatusDescription)
  throw ("unexpected response {0} for {1}" -f $statusCode, $lastReleaseURL)
}

if ($lastVersionURL) {
  Write-Host "# last Version" $lastVersionURL -Separator "`n"
} else {
  throw "no release found at ${lastReleaseURL}"
}

($lastVersionURL -match $versionPattern) | Out-Null
$tag = $Matches.tag
$version = $Matches.version
$revision = $Matches.revision

if ($error) {
  Write-Error "cannot continue, errors occurred"
  exit 1
}

$repo = "https://github.com/$project/releases/download/$tag"

$files = @(
  "OpenSSH-Win64-$revision.msi"
  "OpenSSH-Win64.zip#OpenSSH-Win64-$revision.zip"
)

$files | ForEach-Object {
  $parts = $_.Split('#', 2)
  $src = "$repo/" + $parts[0]
  if ($parts.Length -eq 2) {
    $dest = $parts[1]
  } else {
    $dest = $parts[0]
  }

  Write-Host "# $dest"
  if (-not (Test-Path $dest)) {
    try {
      Write-Host "  -> $src"
      $tmpFile = "$dest.tmp"
      Invoke-WebRequest -Uri "$src" -OutFile $tmpFile
      Move-Item -Path $tmpFile -Destination "$dest"
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}

# Support reading hardlinks on PS7+

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class FileLinkEnumerator
{
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr FindFirstFileNameW(string lpFileName, uint dwFlags, ref uint stringLength, StringBuilder linkName);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FindNextFileNameW(IntPtr hFindStream, ref uint stringLength, StringBuilder linkName);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FindClose(IntPtr hFindStream);
}
"@

function List-HardLinks {
  param (
    [string]$FilePath
  )

  $fileInfo = Get-Item -LiteralPath $FilePath
  $fileName = $fileInfo.FullName
  $links = @()

  $stringLength = 260
  $linkName = New-Object System.Text.StringBuilder -ArgumentList $stringLength
  $handle = [FileLinkEnumerator]::FindFirstFileNameW($fileName, 0, [ref]$stringLength, $linkName)

  if ($handle -eq [IntPtr]::Zero) {
    throw "Failed to find first file name: $([ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error()).Message)"
  }

  $drive = $fileInfo.PSDrive.Root.TrimEnd('\')
  try {
    do {
      $drive + $linkName.ToString()
      $linkName = $linkName.Clear()
      $stringLength = 260
    } while ([FileLinkEnumerator]::FindNextFileNameW($handle, [ref]$stringLength, $linkName))
  } finally {
    [FileLinkEnumerator]::FindClose($handle) | Out-Null
  }
}

function Get-HardLinks {
  param (
    [string]$FilePath
  )
  return @(List-HardLinks $FilePath)
}

function Find-HardLink {
  param(
    [string]$FilePath,
    [string]$LinkPath
  )

  $fileInfo = Get-Item -LiteralPath $LinkPath
  $fullName = $fileInfo.FullName
  List-HardLinks $FilePath | ForEach-Object {
    if ($fullName -eq $_) {
      return $True
    }
  }
  return $False
}

if (!$error) {
  $links = (
    ("OpenSSH-Win64.msi", "OpenSSH-Win64-$revision.msi"),
    ("OpenSSH-Win64.zip", "OpenSSH-Win64-$revision.zip")
  )

  $links | ForEach-Object {
    $link = $_[0]
    $path = $_[1]
    if ((Test-Path $link) -and (Test-Path $path)) {
      $l = (Get-Item -Path $link -Force -ea SilentlyContinue)
      if ($l.LinkType -eq "HardLink") {
        $p = (Get-Item -Path $path -Force -ea SilentlyContinue)
        $target = $l.Target
        if (-not $target) {
          # PS7+ does not read hardlinks by default
          if (Find-HardLink $p.FullName $l.FullName) {
            $target = $p.FullName
          }
        }
        if ($target -eq $p.FullName) {
          Write-Host "hardlink: $link -> $path (no change)"
          return
        } else {
          Write-Host "hardlink: $link -> unknown state (WARNING ignoring file)"
          return
        }
      }
    }

    Write-Host "hardlink: $link -> $path"
    try {
      New-Item -Path $link -Item HardLink -Value $path -Force | Out-Null
    } catch {
      Write-Error "Error: $($_.Exception.Message), line $($_.InvocationInfo.ScriptLineNumber)"
      break
    }
  }
}
