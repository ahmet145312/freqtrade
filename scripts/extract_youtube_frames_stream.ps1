param(
  [Parameter(Mandatory=$true)]
  [string]$Url,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [int]$EverySeconds = 10
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

New-Item -ItemType Directory -Force $OutDir | Out-Null

if ($EverySeconds -lt 1) {
  $EverySeconds = 10
}

Write-Host ""
Write-Host "[stream-frames] YouTube stream URL alınıyor..."

$streamUrl = yt-dlp `
  -f "bv*[height<=720]/b[height<=720]/best[height<=720]/best" `
  --get-url `
  $Url |
  Select-Object -First 1

if (-not $streamUrl) {
  throw "yt-dlp stream URL alamadı."
}

$pattern = Join-Path $OutDir "frame_%05d.jpg"
$vf = "fps=1/$EverySeconds,scale=1280:-1"

Write-Host "[stream-frames] Video indirmeden direkt stream'den kare çıkarılıyor..."
Write-Host "[stream-frames] Çıktı:"
Write-Host $OutDir
Write-Host "[stream-frames] Her $EverySeconds saniyede 1 kare..."

ffmpeg -hide_banner -loglevel warning -y -i $streamUrl -vf $vf -q:v 3 $pattern

Write-Host ""
Write-Host "[stream-frames] Kare çıkarma bitti."
Get-ChildItem $OutDir -Filter "*.jpg" | Select-Object Name,Length,LastWriteTime
