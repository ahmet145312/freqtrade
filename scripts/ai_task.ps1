param(
  [Parameter(Position=0)]
  [string[]]$Task,

  [string]$File,

  [switch]$PrepareOnly,

  [switch]$NoClipboard,

  [switch]$DownloadYouTubeVideo = $true,

  [int]$FrameEverySeconds = 10
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$repo = "C:\Users\ahmet\freqtrade"
Set-Location $repo

$taskText = ($Task -join " ").Trim()

if (-not $taskText) {
  $taskText = Read-Host "Görev"
}

$desktop = [Environment]::GetFolderPath("Desktop")
$outRoot = Join-Path $desktop "AI_CIKTILAR"
New-Item -ItemType Directory -Force $outRoot | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $outRoot "TASK_$stamp"
New-Item -ItemType Directory -Force $runDir | Out-Null

$detected = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]
$inputs = New-Object System.Collections.Generic.List[string]
$generatedFiles = New-Object System.Collections.Generic.List[string]

$urlMatches = [regex]::Matches($taskText, "https?://\S+")
foreach ($m in $urlMatches) {
  $url = $m.Value.TrimEnd(".", ",", ";", ")")
  $inputs.Add($url) | Out-Null

  if ($url -match "youtube\.com|youtu\.be") {
    $detected.Add("youtube") | Out-Null
  }
  elseif ($url -match "instagram\.com|instagr\.am") {
    $detected.Add("instagram") | Out-Null
    $notes.Add("Instagram için otomatik login/scroll/like/comment/follow yok. Link/screenshot/export üzerinden güvenli analiz.") | Out-Null
  }
  elseif ($url -match "github\.com") {
    $detected.Add("github_repo_or_page") | Out-Null
  }
  else {
    $detected.Add("web_url") | Out-Null
  }
}

if ($File) {
  if (Test-Path $File) {
    $inputs.Add((Resolve-Path $File).Path) | Out-Null
  } else {
    $notes.Add("Verilen -File yolu bulunamadı: $File") | Out-Null
  }
}

$pathMatches = [regex]::Matches($taskText, "[A-Za-z]:\\[^\r\n`"<>|]+")
foreach ($m in $pathMatches) {
  $p = $m.Value.Trim()
  if (Test-Path $p) {
    $resolved = (Resolve-Path $p).Path
    if (-not $inputs.Contains($resolved)) {
      $inputs.Add($resolved) | Out-Null
    }
  }
}

# YouTube otomatik hazırlık
$youtubeUrls = @()
foreach ($inputItem in $inputs) {
  if ($inputItem -match "^https?://" -and $inputItem -match "youtube\.com|youtu\.be") {
    $youtubeUrls += $inputItem
  }
}

foreach ($youtubeUrl in $youtubeUrls) {
  $ytDir = Join-Path $runDir "youtube"
  New-Item -ItemType Directory -Force $ytDir | Out-Null

  $notes.Add("YouTube linki algılandı. Metadata, altyazı, temiz transcript ve video/frame hazırlığı deneniyor.") | Out-Null

  try {
    if ($DownloadYouTubeVideo) {
      powershell -ExecutionPolicy Bypass -File ".\scripts\collect_youtube.ps1" -Url $youtubeUrl -OutDir $ytDir -DownloadVideo
    } else {
      powershell -ExecutionPolicy Bypass -File ".\scripts\collect_youtube.ps1" -Url $youtubeUrl -OutDir $ytDir
    }

    $generatedFiles.Add((Join-Path $ytDir "youtube_metadata.json")) | Out-Null
    $generatedFiles.Add((Join-Path $ytDir "youtube_info.txt")) | Out-Null

    $vtt = Get-ChildItem (Join-Path $ytDir "subtitles") -Filter "*.tr.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vtt) {
      $vtt = Get-ChildItem (Join-Path $ytDir "subtitles") -Filter "*.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if ($vtt) {
      $cleanTranscript = Join-Path $ytDir "transcript_clean.txt"
      powershell -ExecutionPolicy Bypass -File ".\scripts\clean_vtt_transcript.ps1" -VttFile $vtt.FullName -OutFile $cleanTranscript
      $generatedFiles.Add($cleanTranscript) | Out-Null
      $notes.Add("YouTube transcript temizlendi: $cleanTranscript") | Out-Null
    } else {
      $notes.Add("YouTube altyazı bulunamadı veya indirilemedi.") | Out-Null
    }

    if ($DownloadYouTubeVideo) {
      $video = Get-ChildItem (Join-Path $ytDir "video") -Filter "*.mp4" -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($video) {
        $framesDir = Join-Path $ytDir "frames"
        powershell -ExecutionPolicy Bypass -File ".\scripts\extract_video_frames.ps1" -VideoFile $video.FullName -OutDir $framesDir -EverySeconds $FrameEverySeconds
        $generatedFiles.Add($video.FullName) | Out-Null
        $generatedFiles.Add($framesDir) | Out-Null
        $notes.Add("Video indirildi ve her $FrameEverySeconds saniyede bir kare çıkarıldı: $framesDir") | Out-Null
      } else {
        $notes.Add("Video dosyası bulunamadı; frame çıkarılamadı.") | Out-Null
      }
    }
  } catch {
    $notes.Add("YouTube hazırlık sırasında hata: $($_.Exception.Message)") | Out-Null
  }
}

$fileSummaries = New-Object System.Collections.Generic.List[string]

foreach ($inputItem in $inputs) {
  if ($inputItem -match "^https?://") {
    continue
  }

  if (-not (Test-Path $inputItem)) {
    continue
  }

  $item = Get-Item $inputItem
  $ext = $item.Extension.ToLowerInvariant()

  switch ($ext) {
    ".pdf"  { $detected.Add("pdf") | Out-Null }
    ".csv"  { $detected.Add("csv") | Out-Null }
    ".xlsx" { $detected.Add("excel") | Out-Null }
    ".xls"  { $detected.Add("excel") | Out-Null }
    ".txt"  { $detected.Add("text") | Out-Null }
    ".md"   { $detected.Add("markdown") | Out-Null }
    ".log"  { $detected.Add("log") | Out-Null }
    ".json" { $detected.Add("json") | Out-Null }
    ".py"   { $detected.Add("code") | Out-Null }
    ".ps1"  { $detected.Add("code") | Out-Null }
    ".png"  { $detected.Add("image") | Out-Null }
    ".jpg"  { $detected.Add("image") | Out-Null }
    ".jpeg" { $detected.Add("image") | Out-Null }
    ".webp" { $detected.Add("image") | Out-Null }
    ".mp4"  { $detected.Add("video_file") | Out-Null }
    ".mov"  { $detected.Add("video_file") | Out-Null }
    ".mkv"  { $detected.Add("video_file") | Out-Null }
    default { $detected.Add("file") | Out-Null }
  }

  $summary = @"
Dosya: $($item.FullName)
Boyut: $($item.Length) byte
Uzantı: $ext
Son değişiklik: $($item.LastWriteTime)
"@

  if ($ext -in @(".txt", ".md", ".csv", ".log", ".json", ".py", ".ps1")) {
    try {
      $sample = Get-Content $item.FullName -TotalCount 80 -ErrorAction Stop | Out-String
      $samplePath = Join-Path $runDir ("sample_" + $item.BaseName + ".txt")
      $sample | Set-Content -Path $samplePath -Encoding UTF8
      $summary += "`nÖrnek içerik dosyası: $samplePath`n"
    } catch {
      $summary += "`nÖrnek içerik okunamadı: $($_.Exception.Message)`n"
    }
  }

  $fileSummaries.Add($summary) | Out-Null
}

if ($detected.Count -eq 0) {
  $detected.Add("plain_task") | Out-Null
}

$uniqueDetected = $detected | Select-Object -Unique

$recommended = "ai_route"
if ($uniqueDetected -contains "youtube" -or $uniqueDetected -contains "video_file" -or $uniqueDetected -contains "image" -or $uniqueDetected -contains "pdf" -or $uniqueDetected -contains "excel" -or $uniqueDetected -contains "csv") {
  $recommended = "gemini_or_claude"
}
if ($uniqueDetected -contains "code" -or $uniqueDetected -contains "github_repo_or_page") {
  $recommended = "codex_or_claude"
}

$taskPacketPath = Join-Path $runDir "TASK_PACKET.md"
$promptPath = Join-Path $runDir "AI_PROMPT.txt"

$inputList = if ($inputs.Count -gt 0) { ($inputs -join "`n") } else { "Yok" }
$typeList = ($uniqueDetected -join ", ")
$noteList = if ($notes.Count -gt 0) { ($notes -join "`n") } else { "Yok" }
$fileSummaryText = if ($fileSummaries.Count -gt 0) { ($fileSummaries -join "`n---`n") } else { "Yok" }
$generatedList = if ($generatedFiles.Count -gt 0) { (($generatedFiles | Select-Object -Unique) -join "`n") } else { "Yok" }

$youtubeTranscriptText = "Yok"
$cleanTranscriptFiles = $generatedFiles | Where-Object { $_ -match "transcript_clean\.txt$" }
if ($cleanTranscriptFiles) {
  $firstTranscript = $cleanTranscriptFiles | Select-Object -First 1
  if (Test-Path $firstTranscript) {
    $youtubeTranscriptText = Get-Content $firstTranscript -Raw
  }
}

$packet = @"
# AI Görev Paketi

Tarih: $(Get-Date)
Repo: $repo
Çıktı klasörü: $runDir

## Kullanıcının görevi

$taskText

## Algılanan türler

$typeList

## Girdiler

$inputList

## Üretilen dosyalar / klasörler

$generatedList

## YouTube temiz transcript

$youtubeTranscriptText

## Dosya özetleri

$fileSummaryText

## Notlar / sınırlar

$noteList

## Çalışma kuralı

- Önce lokal çıkarım kullan.
- Büyük dosyayı direkt cloud modele basma.
- Gerekirse parçala.
- Video/görsel analizinde kesin görülenleri ve tahminleri ayrı yaz.
- Trading/strateji konusu varsa uygulanabilir kurallara çevir.
- Kod/dosya değişikliği gerekiyorsa önce plan çıkar.
- Git işlemi gerekiyorsa açık onay iste.
- `git add .` kullanma.
"@

$packet | Set-Content -Path $taskPacketPath -Encoding UTF8

$prompt = @"
Aşağıdaki görev paketini analiz et.

Amaç:
- Verilen girdinin türünü doğru değerlendir.
- Kullanıcının istediği son ürünü çıkar.
- Dosya/video/görsel/web/PDF/CSV içeriğinde kesin görülenleri ve belirsiz kalanları ayrı yaz.
- YouTube/videosu varsa transcript ve frame klasörünü birlikte değerlendir.
- Trading/strateji konusu varsa uygulanabilir kurallara çevir.
- Kod/repo konusu varsa önce plan çıkar, doğrudan dosya değiştirme.
- Büyük veri varsa özetle, karar tablosu üret.
- Riskleri ve eksik bilgileri açıkça belirt.

Görev paketi:
$taskPacketPath

Kullanıcı görevi:
$taskText

Algılanan türler:
$typeList

Girdiler:
$inputList

Üretilen dosyalar / klasörler:
$generatedList

Önerilen yön:
$recommended
"@

$prompt | Set-Content -Path $promptPath -Encoding UTF8

if (-not $NoClipboard) {
  Set-Clipboard -Value $prompt
}

Write-Host ""
Write-Host "AI görev paketi hazır."
Write-Host "TASK_PACKET_PATH=$taskPacketPath"
Write-Host "AI_PROMPT_PATH=$promptPath"
Write-Host "DETECTED_TYPES=$typeList"
Write-Host "RECOMMENDED=$recommended"

if (-not $PrepareOnly) {
  Write-Host ""
  Write-Host "Prompt clipboard'a kopyalandı."
}
