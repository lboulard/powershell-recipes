
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

  $config = Get-RecipesConfig
  $webProxy = $config.GetWebProxy()
  $u = [Uri]$Uri
  $proxy = $webProxy.GetProxy($u)
  if ($proxy -eq $u) {
    $requestArgs.Add('NoProxy', $true)
  } else {
    $requestArgs.Add('Proxy', $proxy)
    if ($webProxy.UseDefaultCredentials) {
      $requestArgs.Add('UseDefaultCredentials', $true)
    } elseif ($webProxy.Credentials) {
      $requestArgs.Add('ProxyCredential', $webProxy.Credentials)
    }
  }

  return Invoke-WebRequest @requestArgs
}
