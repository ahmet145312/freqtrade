param(
  [Parameter(Mandatory=$true)]
  [string]$VideoFile,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [int]$EverySeconds = 10
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force $OutDir | Out-Null

if (-not (Test-Path $VideoFile)) {
  throw "Video bulunamadı: $VideoFile"
}

if ($EverySeconds -lt 1) {
  $EverySeconds = 10
}

$pattern = Join-Path $OutDir "frame_%05d.jpg"
$vf = "fps=1/$EverySeconds,scale=1280:-1"

Write-Host ""
Write-Host "[frames] Video:"
Write-Host $VideoFile
Write-Host "[frames] Çıktı:"
Write-Host $OutDir
Write-Host "[frames] Her $EverySeconds saniyede 1 kare çıkarılıyor..."

ffmpeg -hide_banner -loglevel warning -y -i $VideoFile -vf $vf -q:v 3 $pattern

Write-Host ""
Write-Host "[frames] Kare çıkarma bitti."
Get-ChildItem $OutDir -Filter "*.jpg" | Select-Object Name,Length,LastWriteTime

