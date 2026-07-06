param(
  [Parameter(Position=0)]
  [string]$Task
)

$ErrorActionPreference = "Stop"

$repo = "C:\Users\ahmet\freqtrade"
Set-Location $repo

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

Write-Host ""
Write-Host "Router çalışıyor..."
Write-Host ""

$out = powershell -ExecutionPolicy Bypass -File ".\scripts\ai_route.ps1" $Task 2>&1
$out | Tee-Object -FilePath ".agent_prompts\last_ai_route.txt"

$joined = ($out -join "`n")

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

Write-Host ""
Write-Host "Otomatik seçim uygulanıyor..."
Write-Host ""

if ($joined -match "Codex /") {
  Write-Host "Seçim: Codex. Prompt clipboard'da. Codex açılıyor."
  Open-AgentTerminal "codex"
}
elseif ($joined -match "Claude /") {
  Write-Host "Seçim: Claude. Prompt clipboard'da. Claude açılıyor."
  Open-AgentTerminal "claude"
}
elseif ($joined -match "Ollama /") {
  $modelLine = ($out | Select-String -Pattern "^ollama run " | Select-Object -First 1).Line

  if (-not $modelLine) {
    $modelLine = "ollama run qwen2.5-coder:7b"
  }

  Write-Host "Seçim: Ollama. Prompt clipboard'da. Ollama açılıyor."
  Open-AgentTerminal $modelLine
}
elseif ($joined -match "Gemini /") {
  Write-Host "Seçim: Gemini. Prompt clipboard'da."
  Write-Host "Gemini web arayüzü açılıyor. Açılınca Ctrl+V yap."
  Start-Process "https://gemini.google.com/app"
}
elseif ($joined -match "Shell \+ Graphify") {
  Write-Host "Seçim: Shell + Graphify. Lokal analiz terminali açılıyor."
  $safeTask = $Task.Replace('"', '\"')
  Open-AgentTerminal "powershell -ExecutionPolicy Bypass -File .\scripts\local_repo_triage.ps1; C:\Users\ahmet\.local\bin\graphify.exe query `"$safeTask`""
}
else {
  Write-Host "Seçim net algılanamadı. Router çıktısı .agent_prompts\last_ai_route.txt dosyasına yazıldı."
  Write-Host "Prompt clipboard'da. Manuel olarak uygun asistana yapıştır."
}

Write-Host ""
Write-Host "Bitti. Son router çıktısı: .agent_prompts\last_ai_route.txt"
