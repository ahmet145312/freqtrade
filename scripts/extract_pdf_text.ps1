param(
  [Parameter(Mandatory=$true)]
  [string]$PdfFile,

  [Parameter(Mandatory=$true)]
  [string]$OutDir,

  [int]$MaxChars = 40000
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

if (-not (Test-Path $PdfFile)) {
  throw "PDF bulunamadı: $PdfFile"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$pdfTextPath = Join-Path $OutDir "pdf_text.txt"
$pdfSummaryPath = Join-Path $OutDir "pdf_summary.md"

$py = @"
import sys
from pathlib import Path
from pypdf import PdfReader

pdf_path = Path(sys.argv[1])
text_path = Path(sys.argv[2])
summary_path = Path(sys.argv[3])
max_chars = int(sys.argv[4])

reader = PdfReader(str(pdf_path))
page_count = len(reader.pages)

parts = []
page_stats = []

for i, page in enumerate(reader.pages, start=1):
    try:
        text = page.extract_text() or ""
    except Exception as e:
        text = f"[PAGE_EXTRACT_ERROR: {e}]"
    page_stats.append((i, len(text)))
    parts.append(f"\n\n--- PAGE {i} ---\n\n{text}")

full_text = "".join(parts).strip()
text_path.write_text(full_text, encoding="utf-8", errors="replace")

preview = full_text[:max_chars]
lines = []
lines.append("# PDF Local Analiz Özeti")
lines.append("")
lines.append("## Dosya")
lines.append(f"- Yol: {pdf_path}")
lines.append(f"- Sayfa sayısı: {page_count}")
lines.append(f"- Çıkarılan toplam karakter: {len(full_text)}")
lines.append(f"- Önizleme karakter limiti: {max_chars}")
lines.append("")
lines.append("## Sayfa Bazlı Karakter Sayısı")
lines.append("")
lines.append("| Sayfa | Karakter |")
lines.append("|---:|---:|")
for page_no, char_count in page_stats:
    lines.append(f"| {page_no} | {char_count} |")
lines.append("")
lines.append("## Metin Önizleme")
lines.append("")
lines.append("~~~text")
lines.append(preview)
lines.append("~~~")
lines.append("")
lines.append("## AI Kullanım Notu")
lines.append("- PDF metni local olarak çıkarıldı.")
lines.append("- PDF görsel tarama ise metin az/boş çıkabilir; bu durumda Gemini/Claude Vision ile dosya/görsel analizi gerekir.")
lines.append("- Tablo yapısı karmaşıksa ayrıca tablo çıkarma modülü gerekebilir.")

summary_path.write_text("\n".join(lines), encoding="utf-8", errors="replace")

print(f"PDF_TEXT_PATH={text_path}")
print(f"PDF_SUMMARY_PATH={summary_path}")
print(f"PDF_PAGES={page_count}")
print(f"PDF_TEXT_CHARS={len(full_text)}")
"@

$tmpPy = Join-Path $OutDir "_extract_pdf_text.py"
$py | Set-Content -Path $tmpPy -Encoding UTF8

Write-Host ""
Write-Host "[pdf] PDF metni çıkarılıyor:"
Write-Host $PdfFile

python $tmpPy $PdfFile $pdfTextPath $pdfSummaryPath $MaxChars

Remove-Item $tmpPy -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[pdf] Hazır:"
Write-Host $pdfSummaryPath
