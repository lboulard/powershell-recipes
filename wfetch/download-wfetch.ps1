$ErrorActionPreference = "Stop"

$releaseURL = "https://api.github.com/repos/lboulard/wfetch/releases/latest"
$token = $Env:GITHUB_TOKEN
$headers = @{
    'Authorization' = "Bearer $token"
    'Accept' = 'application/vnd.github+json'
}

$release = Invoke-RestMethod -Uri $releaseURL -Headers $headers -ContentType "application/vnd.github+json" -Method Get
$assets = $release | Select-Object -ExpandProperty assets
$downloads = $assets | Where-Object { $_.name -like '*-windows*.exe' } | Select-Object url,name
write-Output $downloads

$headers = @{
    'Authorization' = "Bearer $token"
    'Accept' = 'application/octet-stream'
}
foreach($entry in $downloads) {
    irm $entry.url -Headers $headers -OutFile $entry.name
}
