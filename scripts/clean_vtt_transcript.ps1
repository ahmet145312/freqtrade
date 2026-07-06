param(
  [Parameter(Mandatory=$true)]
  [string]$VttFile,

  [Parameter(Mandatory=$true)]
  [string]$OutFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $VttFile)) {
  throw "VTT dosyası bulunamadı: $VttFile"
}

$raw = [System.IO.File]::ReadAllText($VttFile, [System.Text.Encoding]::UTF8)

$lines = $raw -split "`r?`n"
$cleanLines = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
  $x = $line.Trim()

  if (-not $x) { continue }
  if ($x -eq "WEBVTT") { continue }
  if ($x -match "^Kind:") { continue }
  if ($x -match "^Language:") { continue }
  if ($x -match "-->") { continue }
  if ($x -match "^\d+$") { continue }

  $x = [regex]::Replace($x, "<\d\d:\d\d:\d\d\.\d\d\d>", "")
  $x = [regex]::Replace($x, "</?c>", "")
  $x = [regex]::Replace($x, "<[^>]+>", "")
  $x = [System.Net.WebUtility]::HtmlDecode($x)
  $x = [regex]::Replace($x, "\s+", " ").Trim()

  if ($x) {
    $cleanLines.Add($x) | Out-Null
  }
}

# Art arda tekrar eden satırları azalt
$outLines = New-Object System.Collections.Generic.List[string]
$prev = ""

foreach ($line in $cleanLines) {
  if ($line -ne $prev) {
    $outLines.Add($line) | Out-Null
  }
  $prev = $line
}

$text = ($outLines -join "`n")

[System.IO.File]::WriteAllText($OutFile, $text, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "[transcript] Temiz transcript hazır:"
Write-Host $OutFile
