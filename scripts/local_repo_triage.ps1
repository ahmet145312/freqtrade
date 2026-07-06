Write-Host "`n--- Git status ---"
git status --short

Write-Host "`n--- Recent commits ---"
git log --oneline -10

Write-Host "`n--- Strategy-related files tracked by git ---"
git ls-files | Select-String -Pattern "Strategy|strategy|backtest|freqtrade|MCore|LSRC"

Write-Host "`n--- Key strategy symbols ---"
if (Get-Command rg -ErrorAction SilentlyContinue) {
  rg -n "class .*Strategy|class .*IStrategy|populate_entry|populate_exit|custom_exit|custom_stoploss|leverage" .
} else {
  Get-ChildItem -Recurse -File -Include *.py |
    Select-String -Pattern "class .*Strategy|class .*IStrategy|populate_entry|populate_exit|custom_exit|custom_stoploss|leverage"
}

Write-Host "`n--- Python compile check for tracked files ---"
$files = git ls-files "*.py"
$failed = @()

foreach ($f in $files) {
  python -m py_compile $f 2>$null
  if ($LASTEXITCODE -ne 0) {
    $failed += $f
  }
}

if ($failed.Count -gt 0) {
  Write-Host "`nCompile failed:"
  $failed
  exit 1
}

Write-Host "Compile OK."
