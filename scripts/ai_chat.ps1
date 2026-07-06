param(
  [Parameter(Position=0)]
  [string]$Task,

  [switch]$OpenOnly,
  [switch]$Auto
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$repo = "C:\Users\ahmet\freqtrade"
Set-Location $repo

function New-RunDir {
  $desktop = [Environment]::GetFolderPath("Desktop")
  $outRoot = Join-Path $desktop "AI_CIKTILAR"
  New-Item -ItemType Directory -Force $outRoot | Out-Null

  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $runDir = Join-Path $outRoot "TASK_$stamp"
  New-Item -ItemType Directory -Force $runDir | Out-Null

  return $runDir
}

function Open-AgentTerminal {
  param(
    [string]$Command
  )

  $psCmd = "Set-Location '$repo'; $Command"

  Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    $psCmd
  )
}

function Invoke-AutoClaude {
  param(
    [string]$Prompt,
    [string]$OutFile
  )

  Write-Host "Claude otomatik çalışıyor..."
  claude -p $Prompt --output-format text --permission-mode plan | Tee-Object -FilePath $OutFile
}

function Invoke-AutoCodex {
  param(
    [string]$Prompt,
    [string]$OutFile
  )

  Write-Host "Codex otomatik read-only çalışıyor..."
  codex -C $repo -s read-only -a never exec $Prompt | Tee-Object -FilePath $OutFile
}

function Invoke-AutoOllama {
  param(
    [string]$Prompt,
    [string]$OutFile
  )

  Write-Host "Ollama otomatik çalışıyor..."
  ollama run qwen2.5-coder:7b $Prompt | Tee-Object -FilePath $OutFile
}

if (-not $Task) {
  Write-Host ""
  Write-Host "AI Sohbet - görevi yaz:"
  $Task = Read-Host
}

if (-not $Task) {
  Write-Host "Görev boş. Çıkılıyor."
  exit 0
}

New-Item -ItemType Directory -Force ".agent_prompts" | Out-Null

$originalTask = $Task
$runDir = $null
$taskPacketPath = $null
$promptPath = $null

$needsTaskPrep = $false
if ($Task -match "https?://") { $needsTaskPrep = $true }
if ($Task -match "[A-Za-z]:\\") { $needsTaskPrep = $true }
if ($Task -match "\.(pdf|csv|xlsx|xls|txt|md|log|json|png|jpg|jpeg|webp|mp4|mov|mkv|py|ps1)\b") { $needsTaskPrep = $true }

if ($needsTaskPrep -and (Test-Path ".\scripts\ai_task.ps1")) {
  Write-Host ""
  Write-Host "Girdi/link/dosya algılandı. AI görev paketi hazırlanıyor..."
  Write-Host ""

  $prepOut = powershell -ExecutionPolicy Bypass -File ".\scripts\ai_task.ps1" $Task -PrepareOnly -NoClipboard 2>&1
  $prepOut | Tee-Object -FilePath ".agent_prompts\last_ai_task.txt"

  $promptLine = ($prepOut | Select-String -Pattern "^AI_PROMPT_PATH=" | Select-Object -First 1).Line
  $packetLine = ($prepOut | Select-String -Pattern "^TASK_PACKET_PATH=" | Select-Object -First 1).Line

  if ($promptLine) {
    $promptPath = $promptLine.Replace("AI_PROMPT_PATH=", "").Trim()
    if (Test-Path $promptPath) {
      $Task = Get-Content $promptPath -Raw
      $runDir = Split-Path $promptPath -Parent
    }
  }

  if ($packetLine) {
    $taskPacketPath = $packetLine.Replace("TASK_PACKET_PATH=", "").Trim()
  }
}

if (-not $runDir) {
  $runDir = New-RunDir
  $promptPath = Join-Path $runDir "AI_PROMPT.txt"
  $Task | Set-Content -Path $promptPath -Encoding UTF8
}

$finalAnswerPath = Join-Path $runDir "FINAL_ANSWER.md"
$routePath = Join-Path $runDir "ROUTER_OUTPUT.txt"

Write-Host ""
Write-Host "Router çalışıyor..."
Write-Host ""

$out = powershell -ExecutionPolicy Bypass -File ".\scripts\ai_route.ps1" $Task 2>&1
$out | Tee-Object -FilePath ".agent_prompts\last_ai_route.txt"
$out | Set-Content -Path $routePath -Encoding UTF8

$joined = ($out -join "`n")

$selected = "unknown"
if ($joined -match "Codex /") { $selected = "codex" }
elseif ($joined -match "Claude /") { $selected = "claude" }
elseif ($joined -match "Ollama /") { $selected = "ollama" }
elseif ($joined -match "Gemini /") { $selected = "gemini" }
elseif ($joined -match "Shell \+ Graphify") { $selected = "shell_graphify" }

Write-Host ""
Write-Host "Seçilen: $selected"
Write-Host "Çıktı klasörü: $runDir"
Write-Host ""

$mode = "open"
if ($Auto) {
  $mode = "auto"
}
elseif ($OpenOnly) {
  $mode = "open"
}
else {
  Write-Host "Çalışma modu seç:"
  Write-Host "1 - Otomatik çalıştır, cevabı FINAL_ANSWER.md dosyasına yaz"
  Write-Host "2 - Uygulamayı aç, prompt'u clipboard'a koy"
  $choice = Read-Host "Seçim"

  if ($choice -eq "1") {
    $mode = "auto"
  } else {
    $mode = "open"
  }
}

Set-Clipboard -Value $Task

if ($mode -eq "auto") {
  Write-Host ""
  Write-Host "Otomatik mod başladı..."
  Write-Host ""

  if ($selected -eq "claude") {
    Invoke-AutoClaude -Prompt $Task -OutFile $finalAnswerPath
  }
  elseif ($selected -eq "codex") {
    Invoke-AutoCodex -Prompt $Task -OutFile $finalAnswerPath
  }
  elseif ($selected -eq "ollama") {
    Invoke-AutoOllama -Prompt $Task -OutFile $finalAnswerPath
  }
  elseif ($selected -eq "gemini") {
    Write-Host "Gemini CLI kurulu değil. Otomatik cevap alınamıyor."
    Write-Host "Prompt clipboard'a kopyalandı. Gemini web açılıyor."
    Start-Process "https://gemini.google.com/app"

    @"
# Gemini otomatik çalıştırılamadı

Sebep:
- Bu bilgisayarda gemini CLI yok.
- Prompt clipboard'a kopyalandı.
- Gemini web açıldı.

Prompt dosyası:
$promptPath

Görev:
$originalTask
"@ | Set-Content -Path $finalAnswerPath -Encoding UTF8
  }
  elseif ($selected -eq "shell_graphify") {
    Write-Host "Shell + Graphify otomatik lokal analiz çalışıyor..."
    $graphOut = Join-Path $runDir "GRAPHIFY_OUTPUT.txt"
    powershell -ExecutionPolicy Bypass -File ".\scripts\local_repo_triage.ps1" | Tee-Object -FilePath $finalAnswerPath
    C:\Users\ahmet\.local\bin\graphify.exe query $originalTask | Tee-Object -FilePath $graphOut
  }
  else {
    Write-Host "Seçim net değil. Prompt dosyaya yazıldı."
    @"
# Otomatik çalıştırılamadı

Seçim net algılanamadı.

Prompt:
$Task
"@ | Set-Content -Path $finalAnswerPath -Encoding UTF8
  }

  Write-Host ""
  Write-Host "Bitti."
  Write-Host "FINAL_ANSWER:"
  Write-Host $finalAnswerPath
}
else {
  Write-Host ""
  Write-Host "Uygulama açma modu başladı..."
  Write-Host "Prompt clipboard'a kopyalandı."
  Write-Host ""

  if ($selected -eq "codex") {
    Write-Host "Codex açılıyor."
    Open-AgentTerminal "codex"
  }
  elseif ($selected -eq "claude") {
    Write-Host "Claude açılıyor."
    Open-AgentTerminal "claude"
  }
  elseif ($selected -eq "ollama") {
    Write-Host "Ollama açılıyor."
    Open-AgentTerminal "ollama run qwen2.5-coder:7b"
  }
  elseif ($selected -eq "gemini") {
    Write-Host "Gemini web açılıyor. Açılınca Ctrl+V yap."
    Start-Process "https://gemini.google.com/app"
  }
  elseif ($selected -eq "shell_graphify") {
    Write-Host "Shell + Graphify terminali açılıyor."
    $safeTask = $originalTask.Replace('"', '\"')
    Open-AgentTerminal "powershell -ExecutionPolicy Bypass -File .\scripts\local_repo_triage.ps1; C:\Users\ahmet\.local\bin\graphify.exe query `"$safeTask`""
  }
  else {
    Write-Host "Seçim net algılanamadı. Manuel kullan."
  }

  Write-Host ""
  Write-Host "Prompt dosyası:"
  Write-Host $promptPath
}

Write-Host ""
Write-Host "Son router çıktısı: .agent_prompts\last_ai_route.txt"
if (Test-Path ".agent_prompts\last_ai_task.txt") {
  Write-Host "Son görev paketi çıktısı: .agent_prompts\last_ai_task.txt"
}
