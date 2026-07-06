# AI Router Policy

Bu repo için asistan seçimi otomatik route edilir.

## Katmanlar

1. Shell + Graphify: repo akışı, sıfır token analiz, ön tarama.
2. Ollama: yerel özet, küçük analiz, prompt hazırlığı, token tasarrufu.
3. Codex / GPT: dosya değiştirme, implementasyon, test, CI, GitHub Actions.
4. Claude: review, zor bug, mimari karar, lookahead bias ve risk kontrolü.
5. Gemini: uzun context, büyük rapor, CSV/backtest sonucu, araştırma.

## Kullanım

```powershell
.\scripts\ai_route.ps1 "MCore01 stratejisini review et, lookahead bias var mı bak"
.\scripts\ai_route.ps1 "GitHub Actions CI dosyasını eklemek istiyorum"
.\scripts\ai_route.ps1 "Bu uzun backtest raporunu özetle"
```

## Ana kural

Cloud modele büyük CSV, log veya bütün repo basma.

Doğru sıra:

1. local_repo_triage.ps1
2. Graphify query
3. ilgili diff / özet
4. uygun ajan
