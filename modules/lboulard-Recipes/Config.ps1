# Recipes configuration files reader

function script:decode_value([String]$str) {
  $sb = New-Object -TypeName System.Text.StringBuilder
  $state, $savedState = "start", $null
  for ($i = 0; $i -lt $str.Length; $i++) {
    $c = $str[$i]
    if ($c -eq '\' -and ($state -ne "escape")) {
      $savedState = $state
      $state = "escape"
      continue
    }
    switch ($state) {
      "escape" {
        $e = switch ($c) {
          "b" { "`b" }
          "e" { "`e" }
          "t" { "`t" }
          "n" { "`n" }
          "r" { "`r" }
          '\' { '\' }
          '"' { '"' }
          "'" { "'" }
          "#" { "#" }
          Default {
            Write-Host "** WARNING: invalid escape sequence `"\$c`" in ``$str'"
            "\$_"
          }
        }
        $sb.Append($e) | Out-Null
        $state = $savedState
        $savedState = $null
        continue
      }
      "sq" {
        if ($c -eq "'") { $state = "end" }
        else { $sb.Append($c) | Out-Null }
      }
      "dq" {
        if ($c -eq '"') { $state = "end" }
        else { $sb.Append($c) | Out-Null }
      }
      "end" {
        # check is line empty of with a comment
        switch ($c) {
          { $_ -in " ", "\t", "`r", "`n" } { continue }
          "#" { $state = break }
          Default {
            throw "malformed line: $str"
          }
        }
      }
      "raw" {
        if ($c -eq "#") { $state = "break" }
        else { $sb.Append($c) | Out-Null }
      }
      "start" {
        switch ($c) {
          { $_ -in " ", "\t" } { continue }
          "'" { $state = 'sq' }
          '"' { $state = 'dq' }
          Default { $state = 'raw'; $sb.Append($c) | Out-Null }
        }
      }
    }
    if ($state -eq "break") {
      break
    }
  }
  switch ($state) {
    "escape" {
      $ab.Append('\') | Out-Null
      Write-Host "** WARNING: incomplete escape backslash in ``$str'"
    }
    "sq" { Write-Host "** WARNING: missing final quote in ``$str'" }
    "dq" { Write-Host "** WARNING: missing final double quote in ``$str'" }
  }
  return $sb.ToString()
}

function ConvertFrom-ConfigFile {
  [CmdletBinding()]
  param(
    [parameter(ValueFromPipeline)]$contents
  )

  process {
    foreach ($line in $contents) {
      if (!$line) {
        continue
      } elseif ($line -match "^\s*#") {
        # comments are ignored
        continue
      }
      if ($line -match "^\s*\[([a-zA-Z][a-zA-Z0-9_\-]*)(\s+`"([^`"]*)`")?\s*\]\s*#?") {
        $section = $Matches[1]
        if ($Matches[3]) {
          $section += '.' + $Matches[3]
        }
      } elseif ($section -and ($line -match "^\s*([a-zA-Z][a-zA-Z0-9_\-]*)\s*=\s*(.*)$")) {
        $name = $Matches[1]
        $value = decode_value $Matches[2]
        "$section.$name=$value"
      } else {
        throw "malformed line: $line"
      }
    }
  }
}

function script:load_cfg($file) {
  if (!(Test-Path $file)) {
    return $null
  }

  try {
    # ReadAllLines will detect the encoding of the file automatically
    # Ref: https://docs.microsoft.com/en-us/dotnet/api/system.io.file.readalllines?view=netframework-4.5
    $content = [System.IO.File]::ReadAllLines($file)
    return ($content | ConvertFrom-ConfigFile -ErrorAction Stop)
  } catch {
    Write-Host "ERROR loading $file`: $($_.exception.message)"
  }
}

$script:config_location = @(
  (Join-Path (Split-Path $PSScriptRoot -Parent) ".recipes.cfg")
  (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) ".recipes.cfg")
  @(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "recipes/config.cfg" })
  @(if ($env:RECIPES_CONFIG) { $env:RECIPES_CONFIG })
)

$script:defaults = @(
  "fetch.location="
  "http.user-agent=`${Default}"
)

$script:osVersion = [System.Environment]::OSVersion.Version

$script:PowerShellUserAgent = `
  "Mozilla/5.0 (Windows NT $($script:osVersion.Major).$($script:osVersion.Minor); " + `
  "Microsoft Windows $($script:osVersion.Major).$($script:osVersion.Minor).$($script:osVersion.Build); " + `
  "${PSCulture}) WindowsPowerShell/$($PSVersion.Major).$($PSVersion.Minor)"

$script:UserAgents = @{
  "None"             = ""
  "Curl"             = "curl/8.9.0"
  "Chrome"           = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
  "Safari"           = [Microsoft.PowerShell.Commands.PSUserAgent]::Safari
  "Firefox"          = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
  "InternetExplorer" = [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
  "Browser"          = [Microsoft.PowerShell.Commands.PSUserAgent]::Safari
  "PowerShell"       = $script:PowerShellUserAgent
  "Default"          = $script:PowerShellUserAgent
}

$script:variableRegex = [System.Text.RegularExpressions.Regex]::New("\$\{[a-zA-Z]*[a-zA-Z0-9]*\}")

function script:interpolate() {
  param(
    [String]$str,
    [hashtable]$vars
  )
  while ($str) {
    $match = $script:variableRegex.Match($str)
    if (!$match.Success) {
      break
    }
    $name = $str.Substring($match.Index + 2, $match.Length - 3)
    if (-not $name) {
      throw "interpolate: variable name missing"
    }
    $value = if ($name -in $vars.Keys) {
      $vars[$name]
    } elseif (Test-Path -Path Env:$name) {
      (Get-Item -Path Env:$name).Value
    } else {
      $null
    }
    if ($null -eq $value) {
      throw ($name + ": undefined variable during interpolation")
    } else {
      $str = $str.Substring(0, $match.Index) + $value + $str.Substring($match.Index + $match.Length)
    }
  }
  return $str
}

class Config {
  [System.Collections.ArrayList]$Configs

  Config($locations) {
    $this.Configs = New-Object System.Collections.ArrayList
    foreach ($item in $script:defaults) {
      $this.Configs.Add($item)
    }

    foreach ($location in $locations) {
      Write-Debug "Config: loading from ${location} ($(if (Test-Path $location){'found'}else{'absent'}))"
      foreach ($line in (load_cfg $location)) {
        $this.Configs.Add($line)
      }
    }
  }

  # Return an array of tuples (subsection, value)
  hidden [string[][]] Locate([string]$section, [string]$name) {
    $items = New-Object System.Collections.ArrayList
    $section = $section + "."
    $name = "." + $name
    foreach ($item in $this.Configs) {
      Write-Debug "config line: $item"
      $key, $value = $item.Split('=', 2)
      if ($key.StartsWith($section) -and $key.EndsWith($name)) {
        $length = $key.Length - $section.Length - $name.Length
        if ($length -lt 0) { $length = 0 }
        $subsection = $key.SubString($section.Length, $length)
        $items.Add(@($subsection, $value))
      }
    }
    return $items.ToArray()
  }

  [string] GetString([string]$section, [string]$name) {
    $value = $null
    foreach ($item in $this.Locate($section, $name)) {
      $subsection, $value = $item
      if (!$subsection) {
        $value = $value
      }
    }
    return $value
  }

  [System.Net.IWebProxy] GetWebProxy() {
    $http_proxy = $this.GetString("http", "proxy")
    $webProxy = if ($http_proxy -in @("none", "", "no" )) {
      Write-Debug "NO PROXY"
      New-Object Net.WebProxy
    } elseif ($http_proxy -match "^https?://") {
      Write-Debug "PROXY $http_proxy"
      New-Object Net.WebProxy $http_proxy, $true
    } else {
      if ($http_proxy) {
        Write-Warning "BAD PROXY '$http_proxy', using system proxy"
      }
      Write-Debug "PROXY SYSTEM"
      [Net.WebRequest]::DefaultWebProxy
    }
    return $webProxy
  }

  [string] GetUserAgent([String]$url) {
    $useragent = $null
    foreach ($item in $this.Locate("http", "user-agent")) {
      $subsection, $value = $item
      if ($url.StartsWith($subsection)) {
        $useragent = $value
      }
    }
    if ($null -eq $useragent) {
      $useragent = $script:UserAgents['Default']
    } else {
      $useragent = script:interpolate $useragent $script:UserAgents
    }
    return $useragent
  }

  [string] GetFetchLocation([string]$Project) {
    $location = $null
    foreach ($item in $this.Locate("location", "fetch")) {
      $subsection, $value = $item
      if (!$subsection -or ($Project -eq $subsection)) {
        $location = $value
      }
    }
    $location = if ($null -eq $location) {
      ""
    } else {
      script:interpolate $location @{ "Project" = $Project }
    }
    return $location
  }

  [string] ResolveLocation([string]$Project, [string]$path) {
    if (Split-Path -Path $path -IsAbsolute) {
      throw "$path`: absolute path not resolvable per project"
    }
    $folderDest = $this.GetFetchLocation($Project)
    if ($folderDest) {
      $path = Join-Path $folderDest $path
    }
    return $path
  }
}

$script:recipesConfig = $null

function Get-RecipesConfig([switch]$Force) {
  if ($Force -or ($null -eq $script:recipesConfig)) {
    Write-Debug "Read recipes configuration files"
    $script:recipesConfig = [Config]::New($script:config_location)
  }
  $script:recipesConfig
}
function Get-RecipesConfigList {
  [Config]::New($script:config_location).Configs
}

function Get-RecipesUserAgent {
  $script:UserAgents
}
