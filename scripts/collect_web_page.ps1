param(
  [Parameter(Mandatory=$true)]
  [string]$Url,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [int]$MaxChars = 40000
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$htmlPath = Join-Path $OutDir "web_page.html"
$textPath = Join-Path $OutDir "web_text.txt"
$summaryPath = Join-Path $OutDir "web_summary.md"

Write-Host ""
Write-Host "[web] Sayfa indiriliyor:"
Write-Host $Url

$headers = @{
  "User-Agent" = "Mozilla/5.0 AI-Sohbet-Collector"
}

$response = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing -TimeoutSec 30

$html = $response.Content
$html | Set-Content -Path $htmlPath -Encoding UTF8

$title = ""
try {
  if ($html -match "(?is)<title[^>]*>(.*?)</title>") {
    $title = $matches[1]
    $title = [System.Net.WebUtility]::HtmlDecode($title).Trim()
  }
} catch {}

$clean = $html

$clean = [regex]::Replace($clean, "(?is)<script[^>]*>.*?</script>", " ")
$clean = [regex]::Replace($clean, "(?is)<style[^>]*>.*?</style>", " ")
$clean = [regex]::Replace($clean, "(?is)<noscript[^>]*>.*?</noscript>", " ")
$clean = [regex]::Replace($clean, "(?is)<svg[^>]*>.*?</svg>", " ")
$clean = [regex]::Replace($clean, "(?is)<[^>]+>", " ")
$clean = [System.Net.WebUtility]::HtmlDecode($clean)
$clean = [regex]::Replace($clean, "\s+", " ").Trim()

$clean | Set-Content -Path $textPath -Encoding UTF8

$preview = $clean
if ($preview.Length -gt $MaxChars) {
  $preview = $preview.Substring(0, $MaxChars)
}

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# Web Sayfası Local Özeti") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Sayfa") | Out-Null
$lines.Add("- URL: $Url") | Out-Null
$lines.Add("- Başlık: $title") | Out-Null
$lines.Add("- HTTP status: $($response.StatusCode)") | Out-Null
$lines.Add("- HTML dosyası: $htmlPath") | Out-Null
$lines.Add("- Temiz metin dosyası: $textPath") | Out-Null
$lines.Add("- Temiz metin karakter sayısı: $($clean.Length)") | Out-Null
$lines.Add("- Önizleme karakter limiti: $MaxChars") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Temiz Metin Önizleme") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("~~~text") | Out-Null
$lines.Add($preview) | Out-Null
$lines.Add("~~~") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## AI Kullanım Notu") | Out-Null
$lines.Add("- Sayfa local olarak indirildi ve HTML'den kaba temiz metin çıkarıldı.") | Out-Null
$lines.Add("- JavaScript ile sonradan yüklenen içerikler eksik olabilir.") | Out-Null
$lines.Add("- Giriş gerektiren, dinamik veya bot korumalı sayfalar tam okunamayabilir.") | Out-Null

$lines | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "[web] Özet hazır:"
Write-Host $summaryPath
Write-Host "WEB_SUMMARY_PATH=$summaryPath"
Write-Host "WEB_TEXT_PATH=$textPath"
Write-Host "WEB_HTML_PATH=$htmlPath"
Write-Host "WEB_TITLE=$title"
Write-Host "WEB_TEXT_CHARS=$($clean.Length)"
