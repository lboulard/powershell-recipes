# Support reading hardlinks on PS7+

# Shall works also on PS5.
# But Get-Item is already doing same job as function Get-HardLinks.
# So you are duplicating I/O charge for hard links when using Get-Item.

# Use Find-HardLink for portable identification of hard links between two files.
# Thsi funciton is more efficient on PS7 and avoid higher I/O cost on PS5.1.

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

function Get-HardLinks {
  param (
    [string]$FilePath
  )

  $fileInfo = Get-Item -LiteralPath $FilePath
  $fileName = $fileInfo.FullName

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

function Get-AllHardLinks {
  param (
    [string]$FilePath
  )
  return @(Get-HardLinks $FilePath)
}

function Find-HardLink {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FilePath,
    [Parameter(Mandatory, Position = 1)]
    [string]$LinkPath
  )

  $fileInfo = Get-Item -LiteralPath $LinkPath -Force -ea SilentlyContinue
  if ($fileInfo -and ($fileInfo.LinkType -eq "HardLink")) {
    $fullName = $fileInfo.FullName
    $fileInfo = Get-Item -LiteralPath $FilePath -Force -ea SilentlyContinue
    if ($fileInfo -and ($fileInfo.LinkType -eq "HardLink")) {
      if ($fileInfo.Target) {
        # PS5.1 already read all hardlinks
        return $fileInfo.Target.Contains($fullName)
      } else {
        # PS7+ does not read hardlinks by default
        Get-HardLinks $FilePath | ForEach-Object {
          if ($fullName -eq $_) {
            return $True
          }
        }
      }
    }
  }
  return $False
}

# Obtains hardlinks list from a Get-Item result (FileInfo)
# On PS7, function will enumerate all hard inks. On PS5.1, returns target fields.

function Get-TargetFromFileInfo() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [System.IO.FileInfo]$FileInfo
  )
  if ($FileInfo.LinkType -eq "HardLink") {
    $target = $FileInfo.Target
    if (-not $target) {
      # PS7+ does not read hardlinks by default
      $target = Get-HardLinks $FileInfo.FullName
    }
    $target
  }
}

function Update-HardLink() {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FilePath,
    [Parameter(Mandatory, Position = 1)]
    [string]$LinkPath,
    [switch]$CreateIfAbsent
  )

  Write-Verbose "Update-HardLink: $LinkPath -> $Filepath "
  $update = $True
  if ((Test-Path $LinkPath) -and (Test-Path $FilePath)) {
    $update = -not (Find-HardLink $FilePath $LinkPath)
  } elseif (-not ($CreateIfAbsent -or (Test-Path $LinkPath))) {
    throw "'$LinkPath': not found"
  }
  if ($update) {
    $item = New-Item -Path $LinkPath -Item HardLink -Value $FilePath -Force
  }
  if ($item) {
    $item | Add-Member -NotePropertyName "Updated" -NotePropertyValue $update
    return $item
  }
}

