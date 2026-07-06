param(
  [string]$ImageFile = "C:\Users\ahmet\OneDrive\Desktop\Whisk_ahmet.jpeg",
  [string]$Folder = "C:\Users\ahmet\freqtrade\scripts",
  [string]$WebUrl = "https://example.com"
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$repo = "C:\Users\ahmet\freqtrade"
Set-Location $repo

function Test-PowerShellSyntax {
  param([string]$Path)

  $errors = $null
  $null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content $Path -Raw),
    [ref]$errors
  )

  if ($errors) {
    Write-Host "[FAIL] Syntax: $Path"
    $errors
    exit 1
  }

  Write-Host "[OK] Syntax: $Path"
}

function Test-Markers {
  $p = ".\scripts\ai_task.ps1"

  $markers = @(
    '$detected = New-Object',
    '$generatedFiles = New-Object',
    '$fileSummaries = New-Object',
    '$packet = @"',
    '$packet | Set-Content',
    '$prompt = @"',
    'AI görev paketi hazır.'
  )

  foreach ($m in $markers) {
    $count = (Select-String -Path $p -Pattern ([regex]::Escape($m)) -AllMatches).Count

    if ($count -ne 1) {
      Write-Host "[FAIL] Marker count: $m => $count"
      exit 1
    }

    Write-Host "[OK] Marker count: $m => $count"
  }
}

function Invoke-AiTaskSmoke {
  param(
    [string]$Name,
    [string]$TaskText,
    [string[]]$ExpectedTypes
  )

  Write-Host ""
  Write-Host "=== SMOKE: $Name ==="

  $output = powershell -ExecutionPolicy Bypass -File ".\scripts\ai_task.ps1" $TaskText -PrepareOnly 2>&1
  $output | ForEach-Object { Write-Host $_ }

  $detectedLine = $output | Where-Object { $_ -match "^DETECTED_TYPES=" } | Select-Object -Last 1

  if (-not $detectedLine) {
    Write-Host "[FAIL] DETECTED_TYPES satırı bulunamadı: $Name"
    exit 1
  }

  foreach ($t in $ExpectedTypes) {
    if ($detectedLine -notmatch [regex]::Escape($t)) {
      Write-Host "[FAIL] Beklenen type yok: $t"
      Write-Host "Line: $detectedLine"
      exit 1
    }
  }

  Write-Host "[OK] $Name"
}

Write-Host "=== Syntax kontrolleri ==="
Test-PowerShellSyntax ".\scripts\ai_task.ps1"
Test-PowerShellSyntax ".\scripts\collect_local_file.ps1"
Test-PowerShellSyntax ".\scripts\collect_web_page.ps1"
Test-PowerShellSyntax ".\scripts\collect_folder.ps1"
Test-PowerShellSyntax ".\scripts\summarize_image.ps1"

Write-Host ""
Write-Host "=== Marker kontrolleri ==="
Test-Markers

if (-not (Test-Path $ImageFile)) {
  Write-Host "[WARN] Görsel bulunamadı, görsel smoke atlanıyor: $ImageFile"
} else {
  Invoke-AiTaskSmoke `
    -Name "image" `
    -TaskText "Bu görseli analiz et: $ImageFile" `
    -ExpectedTypes @("image")
}

if (-not (Test-Path $Folder)) {
  Write-Host "[WARN] Klasör bulunamadı, folder smoke atlanıyor: $Folder"
} else {
  Invoke-AiTaskSmoke `
    -Name "folder" `
    -TaskText "Bu klasörü analiz et: $Folder" `
    -ExpectedTypes @("folder")
}

Invoke-AiTaskSmoke `
  -Name "web" `
  -TaskText "Bu web sayfasını analiz et: $WebUrl" `
  -ExpectedTypes @("web_url", "web_page")

if ((Test-Path $ImageFile) -and (Test-Path $Folder)) {
  Invoke-AiTaskSmoke `
    -Name "multi" `
    -TaskText "Şunları beraber analiz et: $Folder $WebUrl $ImageFile" `
    -ExpectedTypes @("folder", "web_url", "web_page", "image")
}

Write-Host ""
Write-Host "ALL_SMOKE_TESTS_OK"
