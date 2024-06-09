# https://scatteredcode.net/download-and-extract-gzip-tar-with-powershell/
function Expand-GZip {
  param(
    $inFile,
    $outFile = ($inFile -replace '\.gz$', '')
  )

  $in = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
  try {
    $out = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    try {
      $gzipStream = New-Object System.IO.Compression.GzipStream $in, ([IO.Compression.CompressionMode]::Decompress)
      try {

        $buffer = New-Object byte[] (1024)
        while ($true) {
          $read = $gzipstream.Read($buffer, 0, 1024)
          if ($read -le 0) { break }
          $out.Write($buffer, 0, $read)
        }

      } finally {
        $gzipStream.Close()
      }
    } finally {
      $out.Close()
    }
  } finally {
    $in.Close()
  }
}
