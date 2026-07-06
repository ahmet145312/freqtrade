# LSRC Auto Crew Operational Rules

Project phase: V1 implementation.

Hard rules:

1. Do not add 1m before V3.
2. Do not add CVD before V5.
3. Do not add OI before V2.
4. Do not add RSI/MACD/Stoch RSI at all.
5. Do not optimize before baseline.
6. Do not trust beautiful backtests.
7. Do not ignore slippage.
8. Do not count a limit fill just because price touched the level.
9. Do not use future candles to detect swings.
10. Do not move to live before paper trade.
11. Do not rescue a dead core by adding complexity.

Role routing:

- ChatGPT: project manager and final judge.
- Claude Sonnet: implementation engineer.
- Claude Opus: audit and risk judge.
- Gemini: research and data/API specialist.

Current task:

Create and validate `LSRC5MCore.py`.

V1 uses:
- 5m base timeframe
- 15m informative timeframe
- 1h informative timeframe
- OHLCV
- ATR
- EMA200
- volume
- 15m swing high/low
- 5m sweep/reclaim

V1 forbids:
- 1m
- CVD
- OI
- funding
- FVG/OB
- footprint/order book
- RSI/MACD/Stoch RSI


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
