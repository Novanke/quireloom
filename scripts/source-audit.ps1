param([string]$Revision = '')
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent $PSScriptRoot

# Count only root library .mbt files. Tests, commands, generated interfaces,
# documents and this audit script never contribute to either metric.
# MoonBit's ///| block convention lets the second metric exclude entire type,
# import and extension declarations as well as function signatures.
function Measure-MoonBlock([string[]]$Lines) {
  $code = @($Lines | Where-Object {
    $_ -match '\S' -and $_ -notmatch '^\s*//'
  })
  $nonblank = $code.Count
  $semantic = @($code | Where-Object { $_ -notmatch '^\s*#' })
  if ($semantic.Count -eq 0 -or $semantic[0] -notmatch '^\s*(pub\s+|priv\s+)?fn\b') {
    return [pscustomobject]@{ Nonblank = $nonblank; Body = 0 }
  }
  $inside = $false
  $body = 0
  foreach ($line in $semantic) {
    if (!$inside) {
      if ($line.Contains('{')) { $inside = $true }
      continue
    }
    if ($line -notmatch '^[\s{}\[\](),;]+$') { $body++ }
  }
  [pscustomobject]@{ Nonblank = $nonblank; Body = $body }
}

Push-Location $moduleRoot
try {
  $files = if ($Revision) { @(git ls-tree --name-only $Revision) } else { @(git ls-files) }
  $files = @($files | Where-Object {
    $_ -match '^[^/\\]+\.mbt$' -and $_ -notmatch '_(wb)?test\.mbt$'
  } | Sort-Object)
  $rows = foreach ($name in $files) {
    $lines = if ($Revision) { @(git show "${Revision}:$name") } else { @(Get-Content -LiteralPath $name) }
    if ($lines -match '^\s*/\*') { throw 'Block comments require a lexical audit update.' }
    $block = [System.Collections.Generic.List[string]]::new()
    $nonblank = 0
    $body = 0
    foreach ($line in @($lines) + @('///|')) {
      if ($line -match '^\s*///\|\s*$') {
        $part = Measure-MoonBlock -Lines $block.ToArray()
        $nonblank += $part.Nonblank
        $body += $part.Body
        $block.Clear()
      } else { $block.Add($line) }
    }
    [pscustomobject]@{ File = $name; NonblankCode = $nonblank; FunctionBody = $body }
  }
  $rows | Format-Table -AutoSize
  [pscustomobject]@{
    Revision = $(if ($Revision) { $Revision } else { git rev-parse --short HEAD })
    LibraryFiles = $rows.Count
    NonblankCode = ($rows | Measure-Object NonblankCode -Sum).Sum
    FunctionBody = ($rows | Measure-Object FunctionBody -Sum).Sum
  } | Format-List
} finally { Pop-Location }
