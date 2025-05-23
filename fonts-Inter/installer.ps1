# Load gdi32.dll
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Gdi32 {
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern int AddFontResourceEx(string lpszFilename, uint fl, IntPtr pdv);

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern bool RemoveFontResourceEx(string lpszFilename, uint fl, IntPtr pdv);

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern bool GetFontResourceInfo(string lpszFilename, ref uint cbBuffer, IntPtr lpBuffer, uint dwQueryType);

    public const uint FR_PRIVATE = 0x10;
    public const uint FRINFO_DESCRIPTION = 1;
}
"@

function Get-FontNameFromFile {
    param (
        [string]$fontFilePath
    )

    if (-Not (Test-Path $fontFilePath)) {
        return @()
    }

    # Load the font(s) from the file
    $loadedFonts = [Gdi32]::AddFontResourceEx($fontFilePath, [Gdi32]::FR_PRIVATE, [IntPtr]::Zero)
    if ($loadedFonts -le 0) {
        return @()
    }

    $fontName = @()
    try {
        # Query the required buffer size for the font names
        $bufferSize = 0
        $result = [Gdi32]::GetFontResourceInfo($fontFilePath, [ref]$bufferSize, [IntPtr]::Zero, [Gdi32]::FRINFO_DESCRIPTION)

        if ($result) {
            # Allocate buffer to hold the font names
            $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($bufferSize)

            # Retrieve the font names
            $result = [Gdi32]::GetFontResourceInfo($fontFilePath, [ref]$bufferSize, $buffer, [Gdi32]::FRINFO_DESCRIPTION)
            if ($result) {
                # Convert the buffer to a string
                $fontName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($buffer)
            }

            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer) | Out-Null
        }
    } finally {
        # Remove the font resource
        [Gdi32]::RemoveFontResourceEx($fontFilePath, [Gdi32]::FR_PRIVATE, [IntPtr]::Zero) | Out-Null
    }

    return $fontName
}

$location = (Get-RecipesConfig).GetFetchLocation('fonts-inter')

$version = Get-ChildItem $location -File -Filter "Inter-*" | ForEach-Object {
    if ($_.Name -match '(\d+(\.\d+)+)\.zip$') { $Matches[1] }
} | Sort-Object -Descending -Property {
    [Version]$_
} | Select-Object -First 1

$release = "Inter-${version}"

Write-Output "Release: ${release}"

$versions = @(
    "; autogenerated"
    "#define MyAppVersion `"${version}`""
    "#define MyAppLicense `"${location}\${release}\LICENSE.txt`""
    "[Setup]"
    "SourceDir=${location}"
)

# Source: "OZHANDIN.TTF"; DestDir: "{autofonts}"; FontInstall: "Oz Handicraft BT"; \
#  Flags: ignoreversion comparetimestamp uninsneveruninstall

Push-Location $location

try {
    $files = Get-ChildItem $release -Recurse -Filter '*.ttf' | ForEach-Object {
        $fontFilePath = Resolve-Path -Path $_.Fullname -Relative
        $fontName = Get-FontNameFromFile -fontFilePath $_.Fullname
        @(
            "Source: `"${fontFilePath}`""
            "DestDir: `"{autofonts}\${release}`""
            "FontInstall: `"${fontName}`""
            "Flags: ignoreversion comparetimestamp uninsrestartdelete"
        ) -join "; "
    }

    Set-Content -Value $versions "version.inc.iss"
    Set-Content -Value $files "files.inc.iss"
} finally {
    Pop-Location
}
