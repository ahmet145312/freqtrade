param(
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Task,

  [switch]$NoClipboard
)

$ErrorActionPreference = "Stop"

function Add-Score {
  param(
    [hashtable]$Scores,
    [string]$Key,
    [int]$Value
  )
  $Scores[$Key] = [int]$Scores[$Key] + $Value
}

function Has-Any {
  param(
    [string]$Text,
    [string[]]$Patterns
  )
  foreach ($p in $Patterns) {
    if ($Text -match $p) {
      return $true
    }
  }
  return $false
}

function Get-OllamaModel {
  try {
    $out = & ollama list 2>$null
    if (-not $out) {
      return $null
    }

    $lines = $out | Select-Object -Skip 1
    $names = @()

    foreach ($line in $lines) {
      $parts = ($line -split "\s+")
      if ($parts.Count -gt 0 -and $parts[0]) {
        $names += $parts[0]
      }
    }

    $preferred = @(
      "qwen2.5-coder",
      "qwen2.5",
      "qwen",
      "deepseek-coder",
      "deepseek",
      "codellama",
      "llama3.1",
      "llama3",
      "gemma",
      "mistral"
    )

    foreach ($pref in $preferred) {
      $hit = $names | Where-Object { $_ -like "$pref*" } | Select-Object -First 1
      if ($hit) {
        return $hit
      }
    }

    return ($names | Select-Object -First 1)
  } catch {
    return $null
  }
}

$taskText = ($Task -join " ").Trim()

if (-not $taskText) {
  Write-Host "Görevi yaz:"
  $taskText = Read-Host
}

if (-not $taskText) {
  Write-Error "Görev boş olamaz."
  exit 1
}

$t = $taskText.ToLowerInvariant()

$scores = @{
  shell_graphify = 0
  ollama         = 0
  codex          = 0
  claude         = 0
  gemini         = 0
}

$needsC7 = $false
$needsGraphify = $true
$needsNoEdit = $false
$needsGitApproval = $true

# Repo / local flow
if (Has-Any $t @("repo", "akış", "akis", "graphify", "backtest flow", "hangi dosya", "bağımlılık", "bagimlilik", "class", "strategy", "strateji sınıf", "strateji sinif", "isstrategy", "populate_entry", "populate_exit")) {
  Add-Score $scores "shell_graphify" 4
}

# Current docs / library behavior
if (Has-Any $t @("c7", "context7", "güncel", "guncel", "dokümantasyon", "dokumantasyon", "api", "kurulum", "install", "freqtrade", "pandas", "numpy", "talib", "ta-lib", "ccxt", "docker", "mcp", "continue", "codex", "claude code", "opencode", "playwright")) {
  $needsC7 = $true
  Add-Score $scores "codex" 2
}

# File changing / implementation
if (Has-Any $t @("dosya değiştir", "dosya degistir", "uygula", "implement", "kod yaz", "script yaz", "düzelt", "duzelt", "fix", "refactor", "ci", "github action", "workflow", "test ekle", "commit", "push", "pr aç", "pr ac", "issue template")) {
  Add-Score $scores "codex" 6
}

# Review / quality / difficult reasoning
if (Has-Any $t @("review", "incele", "kontrol et", "mantık hatası", "mantik hatasi", "lookahead", "bias", "veri sızıntısı", "veri sizintisi", "mimari", "risk", "neden yanlış", "neden yanlis", "ikinci göz", "ikinci goz", "kalite")) {
  Add-Score $scores "claude" 5
}

# Long context / research / reports
if (Has-Any $t @("uzun", "rapor", "csv", "log", "transkript", "video", "araştır", "arastir", "piyasa", "teori", "özetle", "ozetle", "büyük çıktı", "buyuk cikti", "doküman", "dokuman", "excel", "pdf")) {
  Add-Score $scores "gemini" 4
}

# Local / token saving / small summary
if (Has-Any $t @("token", "tasarruf", "lokal", "local", "ollama", "yerel", "basit", "küçük", "kucuk", "prompt hazırla", "prompt hazirla", "özet", "ozet")) {
  Add-Score $scores "ollama" 5
}

# Explicit no-edit mode
if (Has-Any $t @("dosya değiştirme", "dosya degistirme", "sadece bak", "sadece incele", "patch yok", "diff yok")) {
  $needsNoEdit = $true
  Add-Score $scores "claude" 2
  Add-Score $scores "ollama" 2
  $scores["codex"] = [Math]::Max(0, [int]$scores["codex"] - 3)
}


# Long outputs should prefer Gemini unless user explicitly asks local/token/Ollama
if ((Has-Any $t @("uzun", "büyük", "buyuk", "büyük çıktı", "buyuk cikti", "csv", "pdf", "excel", "rapor", "backtest raporu", "log")) -and -not (Has-Any $t @("lokal", "local", "ollama", "yerel", "token", "tasarruf"))) {
  Add-Score $scores "gemini" 5
  $scores["ollama"] = [Math]::Max(0, [int]$scores["ollama"] - 3)
}

# Default fallback
if (($scores.Values | Measure-Object -Sum).Sum -eq 0) {
  Add-Score $scores "ollama" 2
  Add-Score $scores "shell_graphify" 1
}

$winner = $scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
$route = $winner.Key
$ollamaModel = Get-OllamaModel

if ($route -eq "ollama" -and -not $ollamaModel) {
  $route = "gemini"
}

$mandatory = @"
Graphify ile repo akışını kontrol et.
C7 ile güncel dokümantasyonu kontrol et.
Dosya değiştirmeden önce plan çıkar.
Riskli Git/GitHub işlemi yapmadan açık onay iste.
Sadece hedef dosyalara dokun. git add . kullanma.
"@

switch ($route) {
  "shell_graphify" {
    $assistantName = "Shell + Graphify"
    $command = @"
cd C:\Users\ahmet\freqtrade
powershell -ExecutionPolicy Bypass -File .\scripts\local_repo_triage.ps1
C:\Users\ahmet\.local\bin\graphify.exe query "$taskText"
"@
    $prompt = @"
Önce token yakmadan şu lokal kontrolleri çalıştır:

$command

Sonra sadece çıkan özeti ajana ver.
Görev: $taskText
"@
  }

  "ollama" {
    $assistantName = "Ollama / Yerel asistan"
    $command = @"
ollama run $ollamaModel
"@
    $prompt = @"
Yerel ve düşük maliyetli analiz yap.
Dosya değiştirme.
Kısa, net ve uygulanabilir çıktı ver.

Görev:
$taskText
"@
  }

  "codex" {
    $assistantName = "Codex / GPT ana geliştirici"
    $command = @"
cd C:\Users\ahmet\freqtrade
codex
"@
    $prompt = @"
$mandatory

Görev:
$taskText

Önce kısa plan çıkar.
Plan içinde değişecek dosyaları tek tek listele.
Ben onay vermeden dosya değiştirme.
Riskli Git/GitHub işlemi yapma.
"@
  }

  "claude" {
    $assistantName = "Claude / Review ve zor hata"
    $command = @"
cd C:\Users\ahmet\freqtrade
claude
"@
    $prompt = @"
Dosya değiştirme.
Önce mevcut diff / ilgili dosya / Graphify bulgusunu incele.
Mantık hatası, veri sızıntısı, lookahead bias, yanlış backtest varsayımı ve mimari risk ara.
Kod yazmadan önce bulguları önem sırasına göre raporla.

Görev:
$taskText
"@
  }

  "gemini" {
    $assistantName = "Gemini / Uzun context ve araştırma"
    $command = @"
Gemini uygulamasına veya Gemini arayüzüne bu promptu yapıştır.
"@
    $prompt = @"
Uzun context / araştırma / rapor analizi yap.
Kod değiştirme.
Önce ana bulguları çıkar.
Sonra karar tablosu ver.
Belirsiz noktaları açıkça ayır.

Görev:
$taskText
"@
  }
}

if ($needsC7 -and $prompt -notmatch "C7") {
  $prompt = "C7 ile güncel dokümantasyonu kontrol et.`n`n" + $prompt
}

Write-Host ""
Write-Host "=== AI ROUTER KARARI ==="
Write-Host "Görev: $taskText"
Write-Host "Seçilen: $assistantName"
Write-Host ""
Write-Host "Skorlar:"
$scores.GetEnumerator() | Sort-Object Name | ForEach-Object {
  Write-Host ("- {0}: {1}" -f $_.Key, $_.Value)
}

Write-Host ""
Write-Host "Önerilen komut / yer:"
Write-Host $command

Write-Host ""
Write-Host "Clipboard prompt:"
Write-Host "----------------"
Write-Host $prompt
Write-Host "----------------"

if (-not $NoClipboard) {
  $prompt | Set-Clipboard
  Write-Host ""
  Write-Host "Prompt clipboard'a kopyalandı."
}

Write-Host ""
Write-Host "Kural: Cloud modele büyük CSV/log/repo basma. Önce local triage + Graphify kullan."

