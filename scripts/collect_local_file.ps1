param(
  [Parameter(Mandatory=$true)]
  [string]$File,

  [Parameter(Mandatory=$true)]
  [string]$OutDir
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

if (-not (Test-Path $File)) {
  throw "Dosya bulunamadı: $File"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$item = Get-Item $File
$ext = $item.Extension.ToLowerInvariant()
$dest = Join-Path $OutDir $item.Name

Copy-Item -Path $item.FullName -Destination $dest -Force

$summaryPath = Join-Path $OutDir "file_summary.md"

$type = "unknown"

switch ($ext) {
  ".pdf"  { $type = "pdf" }
  ".csv"  { $type = "csv" }
  ".txt"  { $type = "text" }
  ".log"  { $type = "text" }
  ".md"   { $type = "text" }
  ".json" { $type = "json" }
  ".png"  { $type = "image" }
  ".jpg"  { $type = "image" }
  ".jpeg" { $type = "image" }
  ".webp" { $type = "image" }
  ".ps1"  { $type = "code" }
  ".py"   { $type = "code" }
  ".yml"  { $type = "code" }
  ".yaml" { $type = "code" }
}

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# Yerel Dosya Özeti") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Dosya") | Out-Null
$lines.Add("- Kaynak: $($item.FullName)") | Out-Null
$lines.Add("- Kopya: $dest") | Out-Null
$lines.Add("- Ad: $($item.Name)") | Out-Null
$lines.Add("- Uzantı: $ext") | Out-Null
$lines.Add("- Tür: $type") | Out-Null
$lines.Add("- Boyut byte: $($item.Length)") | Out-Null
$lines.Add("- Son değişiklik: $($item.LastWriteTime)") | Out-Null
$lines.Add("") | Out-Null

if ($type -in @("text", "json", "code", "csv")) {
  $lines.Add("## İlk İçerik Örneği") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("~~~text") | Out-Null

  try {
    Get-Content -Path $item.FullName -TotalCount 120 -ErrorAction Stop | ForEach-Object {
      $lines.Add($_) | Out-Null
    }
  } catch {
    $lines.Add("Dosya metin olarak okunamadı: $($_.Exception.Message)") | Out-Null
  }

  $lines.Add("~~~") | Out-Null
  $lines.Add("") | Out-Null
}

if ($type -eq "csv") {
  $lines.Add("## CSV Notu") | Out-Null
  $lines.Add("- İlk 120 satır eklendi.") | Out-Null
  $lines.Add("- Büyük CSV ise tamamı cloud modele basılmamalı; önce local özet/kolon analizi yapılmalı.") | Out-Null
  $lines.Add("") | Out-Null
}

if ($type -eq "pdf") {
  $lines.Add("## PDF Notu") | Out-Null
  $lines.Add("- PDF kopyalandı.") | Out-Null
  $lines.Add("- İçerik görsel/tablo içeriyorsa Gemini/Claude tarafında dosya olarak ayrıca verilmelidir.") | Out-Null
  $lines.Add("- Sonraki aşamada PDF metin çıkarma modülü eklenecek.") | Out-Null
  $lines.Add("") | Out-Null
}

if ($type -eq "image") {
  $lines.Add("## Görsel Notu") | Out-Null
  $lines.Add("- Görsel kopyalandı.") | Out-Null
  $lines.Add("- Görsel analiz için Gemini/Claude Vision tarafına dosya olarak verilmelidir.") | Out-Null
  $lines.Add("") | Out-Null
}

$lines | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "[file] Yerel dosya hazırlandı:"
Write-Host $OutDir
Write-Host ""
Write-Host "[file] Özet:"
Write-Host $summaryPath
Write-Host ""
Write-Host "FILE_COPY_PATH=$dest"
Write-Host "FILE_SUMMARY_PATH=$summaryPath"
Write-Host "FILE_TYPE=$type"
