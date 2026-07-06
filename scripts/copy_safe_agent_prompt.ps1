$promptPath = Join-Path (Get-Location) ".agent_prompts\safe_workflow.txt"
if (-not (Test-Path $promptPath)) {
  Write-Error "Prompt file not found: $promptPath"
  exit 1
}
Get-Content $promptPath -Raw | Set-Clipboard
Write-Host "Safe workflow prompt copied to clipboard."
