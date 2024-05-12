$repo = "https://github.com/elixir-lang/elixir/releases/download"
$tag  = "v1.16.3"

$version = $tag.Substring(1)  # strip 'v' prefix

$withFragment = $false
if ($withFragment) {
    $files = , "elixir-otp-26.exe#elixir-otp-26-$version.exe"
    $files += "elixir-otp-26.exe.sha256sum#elixir-otp-26-$version.exe.sha256sum" 
    $files += "Docs.zip#Docs-$version.zip" 
    $files += "Docs.zip.sha256sum#Docs-$version.zip.sha256sum" 
} else {
    $files = , "elixir-otp-26.exe"
    $files += "elixir-otp-26.exe.sha256sum"
    $files += "Docs.zip"
    $files += "Docs.zip.sha256sum"
}

$files | ForEach {
    if ($withFragment) {
        $parts = $_.Split('#', 2)
        $src = "$repo/$tag/" + $parts[0]
        $dest = $parts[1]
    } else {
        $src = "$repo/$tag/" + $_
        # $version = $version -replace '([\.\*\+\?\|\(\)\[\]\{\}\^\$\\])', '\\$1'
        $version = $version -replace '(\$)', '\\$1'
        $dest = $_ -Replace '^([^.]+)((\..*)*)', ('$1' + "-$version" + '$2')
    }
    Write-Host "# $dest"
    if (-Not (Test-Path $dest)) {
        try {
            Write-Host "  -> $src"
            Invoke-WebRequest -Uri "$src" -OutFile "$dest.tmp" -Resume
            Move-Item -Path "$dest.tmp" -Destination "$dest"
        } catch {
            Write-Error "Error: $($_.Exception.Message)"
            break
        }
    }
}
