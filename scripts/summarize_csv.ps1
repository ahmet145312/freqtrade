param(
  [Parameter(Mandatory=$true)]
  [string]$CsvFile,

  [Parameter(Mandatory=$true)]
  [string]$OutFile,

  [int]$SampleRows = 5000,
  [int]$PreviewRows = 20
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

if (-not (Test-Path $CsvFile)) {
  throw "CSV bulunamadı: $CsvFile"
}

$item = Get-Item $CsvFile
$outDir = Split-Path $OutFile -Parent
if ($outDir) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

Write-Host ""
Write-Host "[csv] CSV analiz ediliyor:"
Write-Host $item.FullName

# Satır sayımı: belleğe komple almadan
$totalLines = 0
$reader = [System.IO.File]::OpenText($item.FullName)
try {
  while ($null -ne $reader.ReadLine()) {
    $totalLines++
  }
} finally {
  $reader.Close()
}

$dataRows = [Math]::Max(0, $totalLines - 1)

# Header
$headerLine = Get-Content -Path $item.FullName -TotalCount 1
$columns = @()
if ($headerLine) {
  $columns = $headerLine -split "," | ForEach-Object {
    $_.Trim().Trim('"')
  }
}

# İlk örnek satırlar
$sampleLineCount = [Math]::Min($SampleRows + 1, $totalLines)
$sampleLines = Get-Content -Path $item.FullName -TotalCount $sampleLineCount

$sampleRowsObj = @()
if ($sampleLines.Count -gt 1) {
  $sampleRowsObj = $sampleLines | ConvertFrom-Csv
}

# Eksik değer örnek sayımı
$missing = @{}
foreach ($c in $columns) {
  $missing[$c] = 0
}

foreach ($row in $sampleRowsObj) {
  foreach ($c in $columns) {
    $v = $row.$c
    if ($null -eq $v -or "$v".Trim() -eq "") {
      $missing[$c]++
    }
  }
}

# İlk ve son preview
$firstPreview = Get-Content -Path $item.FullName -TotalCount ($PreviewRows + 1)

$lastPreview = New-Object System.Collections.Generic.Queue[string]
$reader = [System.IO.File]::OpenText($item.FullName)
try {
  while ($null -ne ($line = $reader.ReadLine())) {
    $lastPreview.Enqueue($line)
    if ($lastPreview.Count -gt ($PreviewRows + 1)) {
      [void]$lastPreview.Dequeue()
    }
  }
} finally {
  $reader.Close()
}

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# CSV Local Analiz Özeti") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Dosya") | Out-Null
$lines.Add("- Yol: $($item.FullName)") | Out-Null
$lines.Add("- Ad: $($item.Name)") | Out-Null
$lines.Add("- Boyut byte: $($item.Length)") | Out-Null
$lines.Add("- Toplam satır: $totalLines") | Out-Null
$lines.Add("- Veri satırı: $dataRows") | Out-Null
$lines.Add("- Kolon sayısı: $($columns.Count)") | Out-Null
$lines.Add("- Örneklenen veri satırı: $($sampleRowsObj.Count)") | Out-Null
$lines.Add("- Son değişiklik: $($item.LastWriteTime)") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Kolonlar") | Out-Null
$lines.Add("") | Out-Null
foreach ($c in $columns) {
  $lines.Add("- $c") | Out-Null
}
$lines.Add("") | Out-Null

$lines.Add("## Örnek Eksik Değer Sayımı") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| Kolon | Eksik örnek sayısı |") | Out-Null
$lines.Add("|---|---:|") | Out-Null
foreach ($c in $columns) {
  $lines.Add("| $c | $($missing[$c]) |") | Out-Null
}
$lines.Add("") | Out-Null

$lines.Add("## İlk Satırlar") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("~~~csv") | Out-Null
foreach ($l in $firstPreview) {
  $lines.Add($l) | Out-Null
}
$lines.Add("~~~") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Son Satırlar") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("~~~csv") | Out-Null
foreach ($l in $lastPreview) {
  $lines.Add($l) | Out-Null
}
$lines.Add("~~~") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## AI Kullanım Notu") | Out-Null
$lines.Add("- CSV'nin tamamı cloud modele basılmadı.") | Out-Null
$lines.Add("- Bu özet; kolon yapısı, satır sayısı, ilk/son örnekler ve eksik değer örneği içindir.") | Out-Null
$lines.Add("- Detaylı strateji/backtest analizi gerekiyorsa önce local Python/pandas analizi yapılmalı.") | Out-Null

$lines | Set-Content -Path $OutFile -Encoding UTF8

Write-Host ""
Write-Host "[csv] Özet hazır:"
Write-Host $OutFile
Write-Host "CSV_SUMMARY_PATH=$OutFile"
Write-Host "CSV_ROWS=$dataRows"
Write-Host "CSV_COLUMNS=$($columns.Count)"

