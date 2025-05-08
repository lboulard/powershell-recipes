
function Invoke-HtmlRequest {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [String]
    $Uri,

    [Parameter(Mandatory = $false)]
    [String]
    $OutFile = $null
  )
  $requestArgs = @{
    "Uri"             = $Uri
    "UserAgent"       = (Get-RecipesConfig).GetUserAgent($Uri)
    "UseBasicParsing" = $true
  }
  if ($OutFile) { $requestArgs.Add('OutFile', $OutFile) }

  return Invoke-WebRequest @requestArgs
}
