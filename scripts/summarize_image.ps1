param(
  [Parameter(Mandatory=$true)]
  [string]$ImageFile,

  [Parameter(Mandatory=$true)]
  [string]$OutFile
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

if (-not (Test-Path $ImageFile)) {
  throw "Görsel bulunamadı: $ImageFile"
}

$item = Get-Item $ImageFile
$outDir = Split-Path $OutFile -Parent
if ($outDir) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$py = @"
import sys
from pathlib import Path
from PIL import Image

image_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])

with Image.open(image_path) as img:
    width, height = img.size
    fmt = img.format
    mode = img.mode
    has_alpha = mode in ("RGBA", "LA") or ("transparency" in img.info)

lines = []
lines.append("# Görsel Local Analiz Özeti")
lines.append("")
lines.append("## Dosya")
lines.append(f"- Yol: {image_path}")
lines.append(f"- Ad: {image_path.name}")
lines.append(f"- Uzantı: {image_path.suffix.lower()}")
lines.append(f"- Boyut byte: {image_path.stat().st_size}")
lines.append("")
lines.append("## Görsel Teknik Bilgi")
lines.append(f"- Format: {fmt}")
lines.append(f"- Çözünürlük: {width} x {height}")
lines.append(f"- Genişlik: {width}")
lines.append(f"- Yükseklik: {height}")
lines.append(f"- Renk modu: {mode}")
lines.append(f"- Alfa/transparan kanal: {has_alpha}")
lines.append("")
lines.append("## AI Kullanım Notu")
lines.append("- Görsel dosyası local_files içine kopyalandı.")
lines.append("- Teknik metadata local olarak çıkarıldı.")
lines.append("- Görselin içeriğini anlamak için Gemini/Claude Vision tarafına dosya olarak verilmelidir.")
lines.append("- Bu özet görüntünün ne gösterdiğini iddia etmez; sadece teknik dosya bilgisidir.")

out_path.write_text("\n".join(lines), encoding="utf-8", errors="replace")

print(f"IMAGE_SUMMARY_PATH={out_path}")
print(f"IMAGE_WIDTH={width}")
print(f"IMAGE_HEIGHT={height}")
print(f"IMAGE_FORMAT={fmt}")
"@

$tmpPy = Join-Path $outDir "_summarize_image.py"
$py | Set-Content -Path $tmpPy -Encoding UTF8

Write-Host ""
Write-Host "[image] Görsel analiz ediliyor:"
Write-Host $item.FullName

python $tmpPy $item.FullName $OutFile

Remove-Item $tmpPy -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[image] Özet hazır:"
Write-Host $OutFile
