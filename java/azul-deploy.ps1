param(
  [Parameter(Mandatory, HelpMessage = "Folder for JDK/JRE deployment")]
  [string]$InstallPath,

  [Parameter(Mandatory, HelpMessage = "Path(s) to folder of ZIP archives")]
  [string[]]$FromPath,

  [Parameter(HelpMessage = "Deploy JDK")]
  [switch]$JDK = $false,
  [Parameter(HelpMessage = "Deploy JRE")]
  [switch]$JRE = $false,

  [Parameter(HelpMessage = "Select deployed architectures")]
  [ValidateSet("x86", "amd64")]
  [Alias("Arch")]
  [string[]]$Architecture = @("x86", "amd64"),

  [Parameter(HelpMessage = "Deploy OpenFX variant")]
  [switch]$OpenFX = $false
)


begin {
  $ErrorActionPreference = "Stop"

  @(
    "`nArguments:"
    "  ●  `$InstallPath = $InstallPath"
    "  ●     `$FromPath = [$($FromPath -join ', ')]"
    "  ●          `$JDK = $JDK"
    "  ●          `$JRE = $JRE"
    "  ● `$Architecture = [$($Architecture -join ', ')]"
    "  ●       `$OpenFX = $OpenFX"
  ) -Join "`n" | Out-Default

  if (-not ($JRE -or $JDK)) {
    Throw "incorrect arguments, at least one of -JDR or -JRE shall be given"
  }

  function Create-Symboliclink {
    param(
      [string]$Path,
      [string]$Value
    )

    $upToDate = $False
    if (Test-Path $Path) {
      # check is already defined
      $fileInfo = Get-Item -Path $Path -ErrorAction SilentlyContinue
      if ($fileInfo) {
        # or use this?
        #   islink = [bool]($fileInfo.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if ($fileInfo.LinkType -eq "SymbolicLink") {
            # see further for usage of ".\" prefix
          $upToDate = ($fileInfo.LinkTarget -eq ".\$Value")
        } else {
          Throw ("{0} is not a symbolic link" -f $Path)
        }
      }
    }

    if (-not $upToDate) {
      # For symbolic link on directory, create item in current directory
      # Use -Name and -Value relative to this directory
      $pwd = Get-Location
      try {
        Set-Location (Split-Path $Path -Parent)
        $name = (Split-Path $Path -Leaf)
        New-Item -ItemType SymbolicLink -Name $name -Value ".\$Value" -Force
      } finally {
        Set-Location $pwd
      }
    } else {
      $null
    }
  }

  function ToNamedArch([string]$arch) {
    if ($arch -eq "x64") {
      "amd64"
    } elseif ($arch -match "i?.86") {
      "x86"
    } else {
      $arch
    }
  }

}

process {
  $archiveRegex = "^zulu(?<release>\d+(\.\d+){2,3})-ca(?<openfx>-fx)?-(?<usage>jre|jdk)(?<version>\d+(\.\d+){1,2})-win_(?<arch>i.86|x64|aarch64)\.zip$"

  # ordered by release and version string
  $archives = $FromPath | ForEach-Object {
    Get-ChildItem $_ -File -Recurse
  } | Select-Object DirectoryName, Name, FullName | Where-Object {
    $_.Name -match $archiveRegex
  } | ForEach-Object {
    if ($_.Name -match $archiveRegex) {
      $arch = ToNamedArch($Matches.arch)
      # Build number if Update number in Java
      $version = $Matches.version -as [Version]

      $archInstallPath = Join-Path $InstallPath "zulu-$($arch)"

      if ($version.Major -le 8) {
        $javaVersion = [Version]::new(1, $version.Major, $version.Minor)
        $javaUpdate = $version.Build
        $id = @($Matches.usage, $javaVersion, "_", $javaUpdate) -Join ""
        $folderLinks = @(
          @($Matches.usage, "-", $javaVersion) -Join ""
          @($Matches.usage, "-1.", $version.Major) -Join ""
        )
      } else {
        $javaVersion = $version
        $id = @($Matches.usage, $javaVersion) -Join ""
        $javaUpdate = $null
        $folderLinks = @(
          @($Matches.usage, "-", $version.Major) -Join ""
        )
      }
      $installName = @($Matches.usage, "-", $version) -Join ""

      [pscustomobject]@{
        Id            = $id
        DirectoryName = $_.DirectoryName
        Name          = $_.Name
        FullName      = $_.FullName
        ZuluRelease   = $Matches.release -as [Version]
        OpenFX        = [bool]$Matches.openfx
        Usage         = $Matches.usage.ToUpper()
        Version       = $version
        Architecture  = $arch

        JavaVersion   = $version.Major
        JavaUpdate    = $javaUpdate
        InstallPath   = Join-Path $archInstallPath $installName
        FolderLinks   = $folderLinks
      }
    }
  } | Where-Object {
    $isJRE = $JRE -and ($_.Usage -eq "JRE")
    $isJDK = $JDK -and ($_.Usage -eq "JDK")
    $isOpenFX = -not ($_.OpenFX -xor $OpenFX)
    $isArch = $Architecture.Contains($_.Architecture)

    $isArch -and $isOpenFX -and (-$isJRE -or $isJDK)
  } | Group-Object -Property Usage, Architecture, JavaVersion | ForEach-Object {
    $_.Group | Sort-Object -Property ZuluRelease -Descending | Select-Object -First 1
  }

  if (-not $archives) {
    throw "no candidate found for deployment"
  }

  if ($false) {
    Write-Output "`nCandidates:"
    $archives | Format-List | Out-Default
    # $archives | Format-List | Out-String -Stream | % { if ($_) { "  ● $_" } else { $_ } } | Out-Host
  }

  function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = "zulu-deploy-${PID}-" + [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
  }

  $tempDirPath = New-TemporaryDirectory
  try {
    foreach ($archive in $archives) {
      $packageInstallPath = $archive.InstallPath
      $packageInstallParent = Split-Path $packageInstallPath -Parent
      $basename = $archive.Name -replace '\.zip$', ''
      $rootExtractedPath = Join-Path $tempDirPath $basename

      $archive | Out-Host

      Write-Host (" ● {0}:" -f $packageInstallPath) -NoNewline
      if (Test-Path $packageInstallPath) {
        Write-Host " already installed" -ForegroundColor Green
      } else {
        Write-Host (" extracting from '{0}' ..." -f $archive.Name) -ForegroundColor Yellow -NoNewline

        Expand-Archive -DestinationPath $tempDirPath -LiteralPath $archive.FullName -Force
        if (Test-Path $rootExtractedPath) {
          & {
            New-Item -Path $packageInstallParent -ItemType Directory -Force
            Move-Item -Path $rootExtractedPath -Destination $packageInstallPath -Force
          } | Out-Null
          Write-Host " done" -ForegroundColor Green
        } else {
          Write-Host " error" -ForegroundColor Red
          " error`n" | Out-Host
          Write-Error "${basename}: not found after extraction of $($archive.FullName)"
          throw "${rootExtractedPath} not found"
        }
      }

      foreach ($link in $archive.FolderLinks) {
        $linkPath = Join-Path $packageInstallParent $link
        $name = Split-Path -Path $packageInstallPath -Leaf
        $link = Create-SymbolicLink -Path $linkPath -Value $name

        Write-Host (" ● {0}:" -f $linkPath) -NoNewline
        Write-Host (" symlink to '{0}'" -f $name) -ForegroundColor Yellow -NoNewline
        if ($link) {
          Write-Host " (new or updated)" -ForegroundColor Green
        } else {
          Write-Host " (no change)" -ForegroundColor Yellow
        }
        if (-not (Test-Path -Path $linkPath -Type Container)) {
          Write-Error ("{0}: not a folder!" -f $linkPath)
        }
      }
    }
  } finally {
    Remove-Item $tempDirPath -Force -Recurse | Out-Null

    # To clean up forgotten temporary directory
    # CMD.EXE /S /C "FOR /D %d IN (C:\Users\lboulard\AppData\Local\Temp\zulu-deploy-*) DO RD /Q /S "%~d""
  }
}
