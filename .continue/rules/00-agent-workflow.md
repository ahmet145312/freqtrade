---
name: Mandatory Agent Workflow Rules
alwaysApply: true
---

# Mandatory Agent Workflow Rules

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

## AI Router

For ambiguous tasks, prefer this routing policy:
- Shell + Graphify: repo-local flow and zero-token analysis.
- Ollama: local low-cost summaries and small analysis.
- Codex: implementation, tests, CI, and file changes.
- Claude: review, hard bugs, architecture, lookahead bias, and risk checks.
- Gemini: long context, large reports, and research.
