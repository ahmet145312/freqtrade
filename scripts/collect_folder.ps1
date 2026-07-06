param(
  [Parameter(Mandatory=$true)]
  [string]$Folder,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [int]$MaxFiles = 300,

  [int]$PreviewLines = 80,

  [int]$MaxPreviewFiles = 25,

  [int]$MaxPreviewBytes = 200000
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

if (-not (Test-Path $Folder)) {
  throw "Klasör bulunamadı: $Folder"
}

$item = Get-Item $Folder
if (-not $item.PSIsContainer) {
  throw "Bu yol klasör değil: $Folder"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$summaryPath = Join-Path $OutDir "folder_summary.md"
$treePath = Join-Path $OutDir "folder_tree.txt"
$fileListPath = Join-Path $OutDir "folder_files.csv"

Write-Host ""
Write-Host "[folder] Klasör taranıyor:"
Write-Host $item.FullName

$allFiles = Get-ChildItem -Path $item.FullName -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\__pycache__\\" -and
    $_.FullName -notmatch "\\node_modules\\" -and
    $_.FullName -notmatch "\\\.venv\\" -and
    $_.FullName -notmatch "\\venv\\" -and
    $_.FullName -notmatch "\\env\\" -and
    $_.FullName -notmatch "\\\.mypy_cache\\" -and
    $_.FullName -notmatch "\\\.pytest_cache\\"
  } |
  Sort-Object FullName |
  Select-Object -First $MaxFiles

$allFiles |
  Select-Object FullName, Name, Extension, Length, LastWriteTime |
  Export-Csv -Path $fileListPath -NoTypeInformation -Encoding UTF8

$relativeLines = New-Object System.Collections.Generic.List[string]

foreach ($f in $allFiles) {
  $rel = $f.FullName.Substring($item.FullName.Length).TrimStart("\")
  $relativeLines.Add($rel) | Out-Null
}

$relativeLines | Set-Content -Path $treePath -Encoding UTF8

$extGroups = $allFiles |
  Group-Object Extension |
  Sort-Object Count -Descending

$textExts = @(
  ".ps1", ".py", ".md", ".txt", ".log", ".json", ".yml", ".yaml",
  ".csv", ".html", ".css", ".js", ".ts", ".tsx", ".jsx",
  ".toml", ".ini", ".cfg", ".env", ".example"
)

$previewFiles = $allFiles |
  Where-Object {
    $textExts -contains $_.Extension.ToLowerInvariant() -and
    $_.Length -le $MaxPreviewBytes
  } |
  Select-Object -First $MaxPreviewFiles

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# Klasör Local Özeti") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Klasör") | Out-Null
$lines.Add("- Yol: $($item.FullName)") | Out-Null
$lines.Add("- Ad: $($item.Name)") | Out-Null
$lines.Add("- Taranan dosya limiti: $MaxFiles") | Out-Null
$lines.Add("- Taranan dosya sayısı: $($allFiles.Count)") | Out-Null
$lines.Add("- Dosya listesi CSV: $fileListPath") | Out-Null
$lines.Add("- Dosya ağacı: $treePath") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Uzantı Dağılımı") | Out-Null
$lines.Add("") | Out-Null

foreach ($g in $extGroups) {
  $ext = $g.Name
  if ([string]::IsNullOrWhiteSpace($ext)) {
    $ext = "[uzantısız]"
  }
  $lines.Add("- $ext : $($g.Count)") | Out-Null
}

$lines.Add("") | Out-Null
$lines.Add("## Dosya Ağacı Önizleme") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("~~~text") | Out-Null

$relativeLines | Select-Object -First 120 | ForEach-Object {
  $lines.Add($_) | Out-Null
}

$lines.Add("~~~") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Küçük Text/Code Dosya Önizlemeleri") | Out-Null
$lines.Add("") | Out-Null

foreach ($f in $previewFiles) {
  $rel = $f.FullName.Substring($item.FullName.Length).TrimStart("\")
  $lines.Add("### $rel") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("- Byte: $($f.Length)") | Out-Null
  $lines.Add("- Son değişiklik: $($f.LastWriteTime)") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("~~~text") | Out-Null

  try {
    Get-Content -Path $f.FullName -TotalCount $PreviewLines -ErrorAction Stop | ForEach-Object {
      $lines.Add($_) | Out-Null
    }
  } catch {
    $lines.Add("[okunamadı] $($_.Exception.Message)") | Out-Null
  }

  $lines.Add("~~~") | Out-Null
  $lines.Add("") | Out-Null
}

$lines.Add("## AI Kullanım Notu") | Out-Null
$lines.Add("- Bu özet klasörün tamamını kopyalamaz; dosya ağacı, dosya listesi ve küçük text/code önizlemeleri üretir.") | Out-Null
$lines.Add("- Büyük CSV/PDF/görsel dosyalar için ayrı dosya modülleri daha uygundur.") | Out-Null
$lines.Add("- .git, node_modules, venv, cache klasörleri tarama dışında bırakıldı.") | Out-Null

$lines | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "[folder] Özet hazır:"
Write-Host $summaryPath
Write-Host "FOLDER_SUMMARY_PATH=$summaryPath"
Write-Host "FOLDER_TREE_PATH=$treePath"
Write-Host "FOLDER_FILE_LIST_PATH=$fileListPath"
Write-Host "FOLDER_FILE_COUNT=$($allFiles.Count)"
