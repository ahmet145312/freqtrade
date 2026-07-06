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

$quotedPathMatches = [regex]::Matches($taskText, '"([A-Za-z]:\\[^"]+)"')
foreach ($m in $quotedPathMatches) {
  $p = $m.Groups[1].Value.Trim()
  if (Test-Path $p) {
    $resolved = (Resolve-Path $p).Path
    if (-not $inputs.Contains($resolved)) {
      $inputs.Add($resolved) | Out-Null
    }
  }
}

$pathMatches = [regex]::Matches($taskText, '(?i)[A-Z]:\\[^\s`"<>|]+')
foreach ($m in $pathMatches) {
  $p = $m.Value.Trim()
  $p = $p.TrimEnd(".", ",", ";", ")", "]", "}")

  if (Test-Path $p) {
    $resolved = (Resolve-Path $p).Path
    if (-not $inputs.Contains($resolved)) {
      $inputs.Add($resolved) | Out-Null
    }
  }
}
# Klasör otomatik hazırlık
$folderInputs = @()
foreach ($inputItem in $inputs) {
  if ($inputItem -match "^https?://") {
    continue
  }

  if ((Test-Path $inputItem) -and ((Get-Item $inputItem).PSIsContainer)) {
    $folderInputs += $inputItem
  }
}

foreach ($folderPath in $folderInputs) {
  $folderName = Split-Path $folderPath -Leaf
  $safeFolderName = [regex]::Replace($folderName, '[^\w\.-]+', '_')

  if ($safeFolderName.Length -gt 60) {
    $safeFolderName = $safeFolderName.Substring(0, 60)
  }

  if ([string]::IsNullOrWhiteSpace($safeFolderName)) {
    $safeFolderName = "folder"
  }

  $folderDir = Join-Path $runDir ("folder_{0}" -f $safeFolderName)
  New-Item -ItemType Directory -Force -Path $folderDir | Out-Null

  $notes.Add("Klasör algılandı. Dosya ağacı ve klasör özeti çıkarılıyor: $folderPath") | Out-Null

  try {
    powershell -ExecutionPolicy Bypass -File ".\scripts\collect_folder.ps1" -Folder $folderPath -OutDir $folderDir

    if (-not $detected.Contains("folder")) {
      $detected.Add("folder") | Out-Null
    }

    $folderSummary = Join-Path $folderDir "folder_summary.md"
    $folderTree = Join-Path $folderDir "folder_tree.txt"
    $folderFiles = Join-Path $folderDir "folder_files.csv"

    if (Test-Path $folderSummary) {
      if (-not $generatedFiles.Contains($folderSummary)) {
        $generatedFiles.Add($folderSummary) | Out-Null
      }

      $fileSummaries.Add((Get-Content -Path $folderSummary -Raw)) | Out-Null
    }

    if (Test-Path $folderTree -and -not $generatedFiles.Contains($folderTree)) {
      $generatedFiles.Add($folderTree) | Out-Null
    }

    if (Test-Path $folderFiles -and -not $generatedFiles.Contains($folderFiles)) {
      $generatedFiles.Add($folderFiles) | Out-Null
    }

    if (-not $generatedFiles.Contains($folderDir)) {
      $generatedFiles.Add($folderDir) | Out-Null
    }
  } catch {
    $errMsg = $_.Exception.Message
    $notes.Add("Klasör hazırlık hatası: $folderPath - $errMsg") | Out-Null
  }
}

# Genel web sayfası otomatik hazırlık
$webUrls = @()
foreach ($inputItem in $inputs) {
  if ($inputItem -match "^https?://" -and $inputItem -notmatch "youtube\.com|youtu\.be") {
    $webUrls += $inputItem
  }
}

foreach ($webUrl in $webUrls) {
  $webDir = Join-Path $runDir "web"
  New-Item -ItemType Directory -Force -Path $webDir | Out-Null

  $notes.Add("Web linki algılandı. Sayfa indiriliyor ve temiz metin çıkarılıyor: $webUrl") | Out-Null

  try {
    powershell -ExecutionPolicy Bypass -File ".\scripts\collect_web_page.ps1" -Url $webUrl -OutDir $webDir

    if (-not $detected.Contains("web_page")) {
      $detected.Add("web_page") | Out-Null
    }

    $webSummary = Join-Path $webDir "web_summary.md"
    $webText = Join-Path $webDir "web_text.txt"
    $webHtml = Join-Path $webDir "web_page.html"

    if (Test-Path $webSummary) {
      if (-not $generatedFiles.Contains($webSummary)) {
        $generatedFiles.Add($webSummary) | Out-Null
      }

      $fileSummaries.Add((Get-Content -Path $webSummary -Raw)) | Out-Null
    }

    if (Test-Path $webText -and -not $generatedFiles.Contains($webText)) {
      $generatedFiles.Add($webText) | Out-Null
    }

    if (Test-Path $webHtml -and -not $generatedFiles.Contains($webHtml)) {
      $generatedFiles.Add($webHtml) | Out-Null
    }

    if (-not $generatedFiles.Contains($webDir)) {
      $generatedFiles.Add($webDir) | Out-Null
    }

    $detected.Add("web_page") | Out-Null
  } catch {
    $errMsg = $_.Exception.Message
    $notes.Add("Web sayfası hazırlık hatası: $webUrl - $errMsg") | Out-Null
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
    powershell -ExecutionPolicy Bypass -File ".\scripts\collect_youtube.ps1" -Url $youtubeUrl -OutDir $ytDir

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
      $framesDir = Join-Path $ytDir "frames"
      powershell -ExecutionPolicy Bypass -File ".\scripts\extract_youtube_frames_stream.ps1" -Url $youtubeUrl -OutDir $framesDir -EverySeconds $FrameEverySeconds
      $generatedFiles.Add($framesDir) | Out-Null
      $notes.Add("Video dosyası indirilmeden YouTube stream üzerinden her $FrameEverySeconds saniyede bir kare çıkarıldı: $framesDir") | Out-Null
    }
  } catch {
    $notes.Add("YouTube hazırlık sırasında hata: $($_.Exception.Message)") | Out-Null
  }
}

$fileSummaries = New-Object System.Collections.Generic.List[string]

# Yerel tek dosya otomatik hazırlık
$fileIndex = 0

foreach ($inputItem in $inputs) {
  if ($inputItem -match "^https?://") {
    continue
  }

  if (-not (Test-Path $inputItem)) {
    continue
  }

  $item = Get-Item $inputItem

  if ($item.PSIsContainer) {
    continue
  }

  $fileIndex += 1
  $safeBase = [regex]::Replace($item.BaseName, '[^\w\.-]+', '_')
  if ($safeBase.Length -gt 60) {
    $safeBase = $safeBase.Substring(0, 60)
  }
  if ([string]::IsNullOrWhiteSpace($safeBase)) {
    $safeBase = "file"
  }

  $localRoot = Join-Path $runDir "local_files"
  $localDir = Join-Path $localRoot ("file_{0:D3}_{1}" -f $fileIndex, $safeBase)
  New-Item -ItemType Directory -Force -Path $localDir | Out-Null

  $notes.Add("Yerel dosya algılandı. collect_local_file ile hazırlanıyor: $($item.FullName)") | Out-Null

  try {
    powershell -ExecutionPolicy Bypass -File ".\scripts\collect_local_file.ps1" -File $item.FullName -OutDir $localDir

    $summaryPath = Join-Path $localDir "file_summary.md"
    if (Test-Path $summaryPath) {
      $summary = Get-Content -Path $summaryPath -Raw
      $fileSummaries.Add($summary) | Out-Null

      if (-not $generatedFiles.Contains($summaryPath)) {
        $generatedFiles.Add($summaryPath) | Out-Null
      }
    }

    Get-ChildItem -Path $localDir -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (-not $generatedFiles.Contains($_.FullName)) {
        $generatedFiles.Add($_.FullName) | Out-Null
      }
    }

    if (-not $generatedFiles.Contains($localDir)) {
      $generatedFiles.Add($localDir) | Out-Null
    }

    $ext = $item.Extension.ToLowerInvariant()

    switch ($ext) {
      ".pdf"  { $detected.Add("pdf") | Out-Null }
      ".csv"  { $detected.Add("csv") | Out-Null }
      ".xlsx" { $detected.Add("excel") | Out-Null }
      ".xls"  { $detected.Add("excel") | Out-Null }
      ".txt"  { $detected.Add("text_file") | Out-Null }
      ".md"   { $detected.Add("text_file") | Out-Null }
      ".log"  { $detected.Add("text_file") | Out-Null }
      ".json" { $detected.Add("json_file") | Out-Null }
      ".py"   { $detected.Add("code") | Out-Null }
      ".ps1"  { $detected.Add("code") | Out-Null }
      ".yml"  { $detected.Add("code") | Out-Null }
      ".yaml" { $detected.Add("code") | Out-Null }
      ".png"  { $detected.Add("image") | Out-Null }
      ".jpg"  { $detected.Add("image") | Out-Null }
      ".jpeg" { $detected.Add("image") | Out-Null }
      ".webp" { $detected.Add("image") | Out-Null }
      ".mp4"  { $detected.Add("video_file") | Out-Null }
      ".mov"  { $detected.Add("video_file") | Out-Null }
      ".mkv"  { $detected.Add("video_file") | Out-Null }
      default { $detected.Add("local_file") | Out-Null }
    }
  } catch {
    $errMsg = $_.Exception.Message
    $notes.Add("Yerel dosya hazırlık hatası: $($item.FullName) - $errMsg") | Out-Null
  }
}
if ($detected.Count -eq 0) {
  $detected.Add("plain_task") | Out-Null
}

$uniqueDetected = $detected | Select-Object -Unique

$recommended = "ai_route"
if ($uniqueDetected -contains "youtube" -or $uniqueDetected -contains "video_file" -or $uniqueDetected -contains "image" -or $uniqueDetected -contains "pdf" -or $uniqueDetected -contains "excel" -or $uniqueDetected -contains "csv") {
  $recommended = "gemini_or_claude"
}
if ($uniqueDetected -contains "code" -or $uniqueDetected -contains "github_repo_or_page" -or $uniqueDetected -contains "folder") {
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










