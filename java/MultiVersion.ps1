class MultiVersion : System.IComparable {

  [long[]] $Parts

  # --- Constructors ------------------------------------------------------
  MultiVersion([string] $text) {
    $this.Parts = [MultiVersion]::ParseParts($text)
  }

  MultiVersion([long[]] $parts) {
    if ($null -eq $parts -or $parts.Count -eq 0) {
      throw [System.ArgumentException]::new('A version needs at least one component')
    }
    foreach ($p in $parts) {
      if ($p -lt 0) { throw [System.ArgumentOutOfRangeException]::new('parts', 'Components must be >= 0') }
    }
    $this.Parts = [long[]]$parts.Clone()
  }

  # --- Parsing -----------------------------------------------------------
  hidden static [long[]] ParseParts([string] $text) {
    if ([string]::IsNullOrWhiteSpace($text)) {
      throw [System.ArgumentException]::new('Empty version string')
    }
    $t = $text.Trim() -replace '^[vV]', ''          # accept "v1.2.3"
    if ($t -notmatch '^[0-9]+(\.[0-9]+)*$') {
      throw [System.FormatException]::new("Invalid version string: '$text'")
    }
    return [long[]]@($t.Split('.') | ForEach-Object { [long]::Parse($_) })
  }

  static [MultiVersion] Parse([string] $text) {
    return [MultiVersion]::new($text)
  }

  static [bool] TryParse([string] $text, [ref] $result) {
    try {
      $result.Value = [MultiVersion]::new($text)
      return $true
    } catch {
      $result.Value = $null
      return $false
    }
  }

  # --- Accessors ---------------------------------------------------------
  [int] Count() { return $this.Parts.Count }

  # Component i (0-based); missing components read as 0
  [long] Get([int] $index) {
    if ($index -lt $this.Parts.Count) { return $this.Parts[$index] }
    return 0
  }

  # --- Comparison --------------------------------------------------------
  [int] CompareTo([object] $other) {
    if ($null -eq $other) { return 1 }
    $o = if ($other -is [MultiVersion]) { $other } else { [MultiVersion]::new([string]$other) }

    $n = [Math]::Max($this.Parts.Count, $o.Parts.Count)
    for ($i = 0; $i -lt $n; $i++) {
      [long]$a = $this.Get($i)
      [long]$b = $o.Get($i)
      if ($a -ne $b) { return $a.CompareTo($b) }
    }
    return 0
  }

  [bool] Equals([object] $other) {
    if ($null -eq $other) { return $false }
    try { return $this.CompareTo($other) -eq 0 }
    catch { return $false }
  }

  # Consistent with Equals: trailing zeros are ignored (1.2 == 1.2.0)
  [int] GetHashCode() {
    $n = $this.Parts.Count
    while ($n -gt 1 -and $this.Parts[$n - 1] -eq 0) { $n-- }
    [long]$h = 17
    for ($i = 0; $i -lt $n; $i++) {
      $h = ($h * 31 + $this.Parts[$i].GetHashCode()) -band 0x7FFFFFFF
    }
    return [int]$h
  }

  # --- Helpers -----------------------------------------------------------
  # Returns a new version with component $index incremented and the following ones reset to 0
  [MultiVersion] Increment([int] $index) {
    $len = [Math]::Max($this.Parts.Count, $index + 1)
    $new = [long[]]::new($len)
    for ($i = 0; $i -lt $len; $i++) {
      if ($i -lt $index) { $new[$i] = $this.Get($i) }
      elseif ($i -eq $index) { $new[$i] = $this.Get($i) + 1 }
      else { $new[$i] = 0 }
    }
    return [MultiVersion]::new($new)
  }

  [System.Version] ToSystemVersion() {
    if ($this.Parts.Count -gt 4) {
      throw [System.InvalidOperationException]::new('More than 4 components, cannot convert to System.Version')
    }
    $fields = [Math]::Max(2, $this.Parts.Count)
    return [System.Version]::new($this.ToString($fields))
  }

  [string] ToString() {
    return $this.Parts -join '.'
  }

  # Like System.Version.ToString(fieldCount); pads with 0 if needed
  [string] ToString([int] $fieldCount) {
    return (0..($fieldCount - 1) | ForEach-Object { $this.Get($_) }) -join '.'
  }
}

# Read-only named accessors: Major.Minor.Patch.Build.x.y
$accessors = [ordered]@{
  Major = 0
  Minor = 1
  Patch = 2
  Build = 3
}
foreach ($name in $accessors.Keys) {
  $index = $accessors[$name]
  Update-TypeData -TypeName MultiVersion -MemberType ScriptProperty -MemberName $name `
    -Value ([scriptblock]::Create("`$this.Get($index)")) -Force
}

# Show the named properties by default instead of the raw Parts array
Update-TypeData -TypeName MultiVersion -DefaultDisplayPropertySet Major, Minor, Patch, Build, Parts -Force
