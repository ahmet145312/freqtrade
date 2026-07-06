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

## Mandatory Agent Workflow Rules

For every coding, debugging, setup, backtest, strategy, data, or repository task, follow this workflow:

1. Use Graphify first for repo-local analysis.
   - Inspect local code flow, strategy classes, dependency paths, backtest flow, and existing project structure with Graphify before proposing repo changes.
   - If Graphify CLI fails, fall back to reading `graphify-out/graph.json` directly.

2. Use Context7 / C7 first for current documentation.
   - When the task depends on library APIs, package behavior, Freqtrade docs, pandas, NumPy, TA-Lib, CCXT, Docker, MCP, GitHub CLI, Codex, Claude, OpenCode, or Continue behavior, fetch current documentation with Context7 before giving commands or code.
   - "C7 ile başla" means Context7 must be used before answering.

3. Plan before changing files.
   - Before editing files, summarize the exact plan.
   - List the files that will be changed.
   - Do not modify files until the plan is clear.
   - Prefer minimal, targeted edits.

4. Git and GitHub safety.
   - Do not run risky Git operations without explicit user approval.
   - Risky operations include: commit, push, pull with merge/rebase, reset, clean, checkout that discards changes, branch deletion, force push, PR creation, PR merge, issue creation/editing, workflow dispatch, secret/config changes.
   - Never use `git add .`.
   - Only stage explicit files named by the user or plan.
   - Before any GitHub write action, summarize the exact action and wait for clear approval.

5. Default response discipline.
   - If the user asks for implementation, first produce a short plan.
   - If the user says "dosya değiştirme", do not read/write/patch files unless explicitly allowed.
   - If there are many untracked files, do not touch unrelated files.
