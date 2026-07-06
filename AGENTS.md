# AGENTS.md

Bu repoda çalışan coding agent için kurallar:

- MCP kullanma.
- JSON tool-call yazma.
- exec_command JSON yazma.
- UI, dashboard, web app üretme.
- Sadece öneri verme; gerçek dosya oluştur.
- backtest.py oluştur veya mevcutsa düzelt.
- Placeholder kod yasak: value1, param1, ..., signals = ..., trades = ... kullanma.
- Kod terminalde çalışacak.
- Hata alırsan düzeltip tekrar çalıştır.
- results/trades.csv dolu oluşacak.
- results/combined_summary.csv dolu oluşacak.
- results/per_symbol_summary.csv dolu oluşacak.
- CSV boşsa görev başarısız.
- Trade sayısı 0 ise görev başarısız.

Ana görev:
Liquidity Sweep Displacement MVP backtest sistemi kur.

Çalıştırma:
python backtest.py

Python çalışmazsa:
py backtest.py

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Local Graphify Command

On this Windows machine, Codex should prefer the absolute Graphify executable path:

C:\Users\ahmet\.local\bin\graphify.exe

Use these commands instead of bare graphify when possible:

C:\Users\ahmet\.local\bin\graphify.exe query "strategy classes and backtest flow"
C:\Users\ahmet\.local\bin\graphify.exe explain "LSRC5MCoreV1B"
C:\Users\ahmet\.local\bin\graphify.exe path "LSRC5MCoreV1B" "IStrategy"

If Graphify CLI fails with a uv trampoline path error, fall back to reading graphify-out/graph.json directly.

## GitHub MCP Safety Rules

GitHub MCP is available for this repo, but write actions require explicit user approval.

Allowed without extra approval:
- Read repository metadata
- List branches
- Read commits
- Read issues and pull requests
- Read workflow run status

Not allowed without explicit user approval:
- Create or edit issues
- Create or edit pull requests
- Add comments
- Trigger workflows
- Push branches
- Merge pull requests
- Delete branches
- Change repository settings
- Modify secrets or deployments

If the user asks for a GitHub write action, first summarize the exact action and wait for clear approval.

## Context7 / C7 Rule

When the user says "C7 ile başla", first use Context7 to check current documentation before giving code, commands, or setup advice.

Use Context7 first for:
- Library or framework API usage
- Package installation and configuration
- Freqtrade documentation questions
- Pandas, NumPy, TA-Lib, Plotly, CCXT, SQLAlchemy, FastAPI, Playwright, Docker, GitHub CLI, MCP, or Codex setup
- Any answer that depends on current package behavior or docs

Do not use Context7 for pure local repo analysis. For local code structure, dependency paths, strategy classes, or backtest flow, use Graphify first.

Shortcut:
- C7 = Context7
- "C7 ile başla" = fetch current docs with Context7 first
