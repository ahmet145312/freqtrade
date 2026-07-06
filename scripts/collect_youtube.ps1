param(
  [Parameter(Mandatory=$true)]
  [string]$Url,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [switch]$DownloadVideo
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$metadataPath = Join-Path $OutDir "youtube_metadata.json"
$infoPath = Join-Path $OutDir "youtube_info.txt"
$subsDir = Join-Path $OutDir "subtitles"
$videoDir = Join-Path $OutDir "video"
$logPath = Join-Path $OutDir "youtube_collect.log"

New-Item -ItemType Directory -Force $subsDir | Out-Null
New-Item -ItemType Directory -Force $videoDir | Out-Null

Write-Host ""
Write-Host "[youtube] Metadata alınıyor..."
yt-dlp --dump-json --skip-download $Url | Set-Content -Path $metadataPath -Encoding UTF8

Write-Host "[youtube] Basit bilgi alınıyor..."
yt-dlp --skip-download --print "title=%(title)s" --print "channel=%(channel)s" --print "duration=%(duration_string)s" --print "upload_date=%(upload_date)s" --print "webpage_url=%(webpage_url)s" $Url | Set-Content -Path $infoPath -Encoding UTF8

Write-Host "[youtube] Türkçe altyazı/transcript deneniyor..."
Push-Location $subsDir
try {
  $oldEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  & yt-dlp `
    --skip-download `
    --write-subs `
    --write-auto-subs `
    --sub-langs "tr,tr-orig,tr.*" `
    --sub-format "vtt" `
    -o "subtitle_%(id)s.%(ext)s" `
    $Url 2>&1 | Tee-Object -FilePath $logPath -Append

  $ErrorActionPreference = $oldEap

  if ($LASTEXITCODE -ne 0) {
    Write-Host "[youtube] Altyazı komutu hata kodu döndürdü ama akış durdurulmadı: $LASTEXITCODE"
  }
} catch {
  $ErrorActionPreference = $oldEap
  Write-Host "[youtube] Altyazı bulunamadı veya indirilemedi. Devam ediliyor."
  Write-Host $_.Exception.Message
}
Pop-Location

if ($DownloadVideo) {
  Write-Host "[youtube] Video indiriliyor. Görsel analiz için 720p sınırı kullanılıyor..."
  Push-Location $videoDir
  yt-dlp `
    -f "bv*[height<=720]+ba/b[height<=720]/best[height<=720]/best" `
    --merge-output-format mp4 `
    -o "source_%(id)s.%(ext)s" `
    $Url
  Pop-Location
} else {
  Write-Host "[youtube] Video indirme kapalı. Sadece metadata/transcript hazırlandı."
}

Write-Host ""
Write-Host "[youtube] Hazır:"
Write-Host $OutDir
