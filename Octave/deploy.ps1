# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.4#verbosepreference
# $VerbosePreference = "Continue"

$ErrorActionPreference = "Stop"

# Define the destination base folder
$lbPrograms = $Env:LBPROGRAMS
if ([string]::IsNullOrWhiteSpace($lbPrograms)) {
    $lbHome = $env:LBHOME
    if ([string]::IsNullOrWhiteSpace($lbHome)) {
        $dest = $HOME
    }
    else {
        $dest = $lbHome
    }
}
else {    
    $dest = $lbPrograms
}
$appsDir = Join-Path $dest "Apps"
Set-Location -Path $PSScriptRoot

# Get all matching archives and parse version info
$archives = Get-ChildItem -Filter "octave-*-w64.7z" | Where-Object {
    $_.Name -match "^octave-(\d+)\.(\d+)\.(\d+)-w64\.7z$"
} | ForEach-Object {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    [PSCustomObject]@{
        File    = $_
        Version = [Version]::new($major, $minor, $patch)
        Folder  = "octave-$($major).$($minor).$($patch)-w64"
    }
}

if (-not $archives) {
    Write-Error "No valid Octave archives found."
    exit 1
}

function Get-7ZipPath {
    # Try PATH first
    #$7zPath = Get-Command 7z -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
    #if ($7zPath) { return $7zPath }

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $foundPath = $null

    foreach ($regPath in $registryPaths) {
        foreach ($subKey in Get-ChildItem $regPath -ErrorAction SilentlyContinue) {
            $props = Get-ItemProperty $subKey.PSPath -ErrorAction SilentlyContinue
            $displayName = $props.DisplayName
            $installLocation = $props.InstallLocation

            if ($displayName -like "*7-Zip*") {
                if (-not $installLocation -and $props.UninstallString -match "^(.*?\\)Uninstall\.exe") {
                    $installLocation = $Matches[1]
                }

                if ($installLocation) {
                    $exe = Join-Path $installLocation "7z.exe"
                    if (Test-Path $exe) {
                        $foundPath = $exe
                        break
                    }
                }
            }
        }

        if ($foundPath) { break }
    }

    if ($foundPath) {
        return $foundPath
    }
    else {
        throw "7z.exe not found in PATH or registry"
    }
}
function Get-LinkInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @{
            Type   = $null
            Target = $null
        }
    }

    $item = Get-Item $Path -Force

    if (-not $item.Attributes.ToString().Contains("ReparsePoint")) {
        return @{
            Type   = $null
            Target = $null
        }
    }

    $fsutilOutput = fsutil reparsepoint query $Path 2>$null
    $type = switch -regex ($fsutilOutput) {
        "Reparse Tag Value\s+:\s+0xA000000C" { "SymbolicLink"; break }
        "Reparse Tag value\s+:\s+0xA0000003" { "Junction"; break }
        default { "Other"; break }
    }

    # Use .Target for symbolic links
    $target = $null
    if ($type -eq "SymbolicLink") {
        $target = $item.Target
    }
    elseif ($type -eq "Junction") {
        # Use fsutil output to get junction target
        if ($fsutilOutput -match "Substitute Name:\s+\\\?\?(.*)") {
            $target = $Matches[1] -replace "^[A-Z]:", { $_.Value.ToUpper() }
        }
    }

    return @{
        Type   = $type
        Target = $target
    }
}

function Expand-7Zip {
    param (
        [string]$SevenZipExe,
        [string]$ArchivePath,
        [string]$OutputPath
    )

    Write-Host "Counting files in archive..."

    $listOutput = & $SevenZipExe l "$ArchivePath"
    $lines = $listOutput -split "`r?`n"
    $sep = ($lines | Select-String "^-{10,}").LineNumber
    if ($sep.Count -lt 2) {
        throw "Could not parse archive contents."
    }

    $files = $lines[($sep[0] + 1)..($sep[1] - 1)] | Where-Object { $_ -match '\S' }
    $totalFiles = $files.Count
    if ($totalFiles -eq 0) {
        throw "No files to extract."
    }

    Write-Host "Expanding archive to '$OutputPath' ($totalFiles files)..."

    & cmd /c "`"$SevenZipExe`" x `"$ArchivePath`" -o`"$OutputPath`" -y -bsp2" | Out-Default
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip extraction failed with exit code $LASTEXITCODE"
    }

    Write-Host "Extraction complete."
}

# Get the archive with the latest version
$latest = $archives | Sort-Object Version -Descending | Select-Object -First 1
$archive = $latest.File
$versionedFolder = $latest.Folder
$targetPath = Join-Path $appsDir $versionedFolder
$linkPath = Join-Path $appsDir "octave"

# Skip extraction if folder already exists
if (-Not (Test-Path $targetPath)) {
    # Create a temporary extraction folder
    $tempPath = New-TemporaryFile
    Remove-Item $tempPath
    New-Item -Path $tempPath -ItemType Directory | Out-Null

    # Use 7-Zip to extract
    Write-Output "Extracting $($archive.Name) to temporary folder..."
    $sevenZip = Get-7ZipPath
    Expand-7Zip -SevenZipExe $sevenZip -ArchivePath $archive -OutputPath $tempPath

    # Ensure expected folder exists in archive
    $extractedFolder = Join-Path $tempPath $versionedFolder
    if (-Not (Test-Path $extractedFolder)) {
        Write-Error "Expected folder '$versionedFolder' not found in archive."
        Remove-Item -Recurse -Force $tempPath
        exit 1
    }

    # Move folder atomically to target path
    Move-Item -Path $extractedFolder -Destination $targetPath
    Remove-Item -Recurse -Force $tempPath
}
else {
    Write-Output "Target folder '$targetPath' already exists. Skipping extraction."
}

# Check if symbolic link exists and validate target
$shouldCreateLink = $true
$linkInfo = Get-LinkInfo $linkPath

if ($linkInfo.Type) {
    if ($linkInfo.Type -ne "SymbolicLink") {
        Write-Error "Path '$linkPath' exists but is not a symbolic link. It is: $($linkInfo.Type). Aborting."
        exit 1
    }

    if ($linkInfo.Target -eq $versionedFolder) {
        Write-Output "Symbolic link already points to correct version: '$versionedFolder'"
        $shouldCreateLink = $false
    }
    else {
        Write-Output "Removing outdated symbolic link pointing to '$($linkInfo.Target)'"
        Remove-Item $linkPath
    }
}

# Create symbolic link if needed
if ($shouldCreateLink) {
    Write-Output "Creating symbolic link '$linkPath' -> '$versionedFolder'"
    cmd /c mklink /D "$linkPath" "$versionedFolder" | Out-Null
}

