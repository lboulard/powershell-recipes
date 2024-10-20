function Get-UserAgent() {
  return "Scoop/1.0 (+http://scoop.sh/) PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) (Windows NT $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor); $(if(${env:ProgramFiles(Arm)}){'ARM64; '}elseif($env:PROCESSOR_ARCHITECTURE -eq 'AMD64'){'Win64; x64; '})$(if($env:PROCESSOR_ARCHITEW6432 -in 'AMD64','ARM64'){'WOW64; '})$PSEdition)"
}

function handle_special_urls($url)
{
    # FossHub.com
    if ($url -match "^(?:.*fosshub.com\/)(?<name>.*)(?:\/|\?dwl=)(?<filename>.*)$") {
        $Body = @{
            projectUri      = $Matches.name;
            fileName        = $Matches.filename;
            source          = 'CF';
            isLatestVersion = $true
        }
        if ((Invoke-RestMethod -Uri $url) -match '"p":"(?<pid>[a-f0-9]{24}).*?"r":"(?<rid>[a-f0-9]{24})') {
            $Body.Add("projectId", $Matches.pid)
            $Body.Add("releaseId", $Matches.rid)
        }
        $url = Invoke-RestMethod -Method Post -Uri "https://api.fosshub.com/download/" -ContentType "application/json" -Body (ConvertTo-Json $Body -Compress)
        if ($null -eq $url.error) {
            $url = $url.data.url
        }
    }

    # Sourceforge.net
    if ($url -match "(?:downloads\.)?sourceforge.net\/projects?\/(?<project>[^\/]+)\/(?:files\/)?(?<file>.*?)(?:$|\/download|\?)") {
        # Reshapes the URL to avoid redirections
        $url = "https://downloads.sourceforge.net/project/$($matches['project'])/$($matches['file'])"
    }

    # Github.com
    if ($url -match 'github.com/(?<owner>[^/]+)/(?<repo>[^/]+)/releases/download/(?<tag>[^/]+)/(?<file>[^/#]+)(?<filename>.*)' -and ($token = Get-GitHubToken)) {
        $headers = @{ "Authorization" = "token $token" }
        $privateUrl = "https://api.github.com/repos/$($Matches.owner)/$($Matches.repo)"
        $assetUrl = "https://api.github.com/repos/$($Matches.owner)/$($Matches.repo)/releases/tags/$($Matches.tag)"

        if ((Invoke-RestMethod -Uri $privateUrl -Headers $headers).Private) {
            $url = ((Invoke-RestMethod -Uri $assetUrl -Headers $headers).Assets | Where-Object -Property Name -EQ -Value $Matches.file).Url, $Matches.filename -join ''
        }
    }

    return $url
}

# Unlike url_filename which can be tricked by appending a
# URL fragment (e.g. #/dl.7z, useful for coercing a local filename),
# this function extracts the original filename from the URL.
function url_remote_filename($url) {
  $uri = (New-Object URI $url)
  $basename = Split-Path $uri.PathAndQuery -Leaf
  If ($basename -match ".*[?=]+([\w._-]+)") {
    $basename = $matches[1]
  }
  If (($basename -notlike "*.*") -or ($basename -match "^[v.\d]+$")) {
    $basename = Split-Path $uri.AbsolutePath -Leaf
  }
  If (($basename -notlike "*.*") -and ($uri.Fragment -ne "")) {
    $basename = $uri.Fragment.Trim('/', '#')
  }
  return $basename
}

function filesize($length) {
  $gb = [math]::pow(2, 30)
  $mb = [math]::pow(2, 20)
  $kb = [math]::pow(2, 10)

  if ($length -gt $gb) {
    "{0:n1} GB" -f ($length / $gb)
  } elseif ($length -gt $mb) {
    "{0:n1} MB" -f ($length / $mb)
  } elseif ($length -gt $kb) {
    "{0:n1} KB" -f ($length / $kb)
  } else {
    if ($null -eq $length) {
      $length = 0
    }
    "$($length) B"
  }
}

function fname($path) { split-path $path -leaf }
function strip_filename($path) { $path -replace [regex]::escape((fname $path)) }

function ftp_file_size($url) {
  $request = [net.ftpwebrequest]::create($url)
  $request.method = [net.webrequestmethods+ftp]::getfilesize
  $request.getresponse().contentlength
}
